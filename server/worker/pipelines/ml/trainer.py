"""
ml/trainer.py
=============
Trains an XGBoost regressor on fused product data.

Why XGBoost over Random Forest:
  - Sequential boosting corrects previous errors → better on small noisy datasets
  - Built-in L1/L2 regularisation prevents overfitting (critical with 92 rows)
  - Handles feature interactions natively
  - Missing values handled internally (no need to impute everything)
  - Typically 10-30% better R² than RF on tabular data this size
"""

import joblib
import numpy as np
import pandas as pd
from pathlib import Path
from datetime import datetime

from xgboost import XGBRegressor
from sklearn.model_selection import cross_val_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from ..ml.features import FEATURE_COLUMNS, LABEL_WEIGHTS, INVERT_FEATURES, PRICE_USE_MIDPOINT
from core.utils import get_logger

logger = get_logger(__name__)

MODEL_DIR  = Path("ml/saved_models")
MODEL_DIR.mkdir(parents=True, exist_ok=True)
MODEL_PATH = MODEL_DIR / "recommender.joblib"

JIJI_SENTIMENT_CAP = 0.7


# ── Platform bias correction ──────────────────────────────────────────────────

def _apply_platform_adjustments(df: pd.DataFrame) -> pd.DataFrame:
    """Cap Jiji sentiment — their reviews are seller feedback, not product reviews."""
    df = df.copy()
    if "sentiment_score_raw" in df.columns and "source_platform" in df.columns:
        jiji_high = (df["source_platform"] == "jiji") & (df["sentiment_score_raw"] > JIJI_SENTIMENT_CAP)
        if jiji_high.any():
            logger.info(f"Capping {jiji_high.sum()} Jiji sentiment scores to {JIJI_SENTIMENT_CAP}")
            df.loc[jiji_high, "sentiment_score_raw"] = JIJI_SENTIMENT_CAP
    return df


# ── Label generation ──────────────────────────────────────────────────────────

def generate_labels(df: pd.DataFrame) -> pd.Series:
    """
    Composite label:
      score = 0.35×sentiment + 0.30×rating + 0.20×price_score + 0.15×review_count

    Rating: 0/NULL → neutral 0.5 (no verified rating ≠ bad product)
    Price:  midpoint strategy — median price scores highest, outliers score lower
    Review: 0 reviews → neutral 0.5 contribution
    """
    label = pd.Series(0.0, index=df.index)

    col_map = {
        "sentiment_score": "sentiment_score_raw",
        "rating":          "rating_raw",
        "review_count":    "review_count_raw",
        "price":           "price_raw",
    }

    for col, weight in LABEL_WEIGHTS.items():
        source_col = col_map.get(col, col)
        actual_col = source_col if source_col in df.columns else col

        if actual_col not in df.columns:
            logger.warning(f"Label column '{actual_col}' not found — skipping")
            continue

        series = pd.to_numeric(df[actual_col], errors="coerce")

        # ── Rating: 0 and NULL = no rating → neutral 0.5 ─────────────────────
        if col == "rating":
            has_rating = series.notna() & (series > 0)
            rated      = series[has_rating]
            norm       = pd.Series(0.5, index=df.index)
            if not rated.empty:
                r_min, r_max = rated.min(), rated.max()
                if r_max > r_min:
                    norm[has_rating] = (rated - r_min) / (r_max - r_min)
                else:
                    norm[has_rating] = 1.0
            logger.debug(f"{(~has_rating).sum()} products have no rating → neutral 0.5")

        # ── Price: midpoint strategy ──────────────────────────────────────────
        elif col == "price" and PRICE_USE_MIDPOINT:
            series  = series.clip(lower=0).fillna(series.median())
            col_min, col_max = series.min(), series.max()
            if col_max == col_min:
                norm = pd.Series(0.5, index=df.index)
            else:
                norm        = (series - col_min) / (col_max - col_min)
                median_norm = norm.median()
                norm        = 1.0 - (norm - median_norm).abs()
            logger.debug(f"Price midpoint — median=₦{series.median():,.0f}, range ₦{series.min():,.0f}–₦{series.max():,.0f}")

        # ── Review count: 0 = no reviews → neutral 0.5 ───────────────────────
        elif col == "review_count":
            series     = series.clip(lower=0).fillna(0)
            has_review = series > 0
            norm       = pd.Series(0.5, index=df.index)
            reviewed   = series[has_review]
            if not reviewed.empty:
                r_min, r_max = reviewed.min(), reviewed.max()
                if r_max > r_min:
                    norm[has_review] = (reviewed - r_min) / (r_max - r_min)
                else:
                    norm[has_review] = 1.0
            logger.debug(f"{(~has_review).sum()} products have no review data → neutral 0.5")

        # ── Standard min-max ──────────────────────────────────────────────────
        else:
            series  = series.clip(0, 1).fillna(0.5)  # sentiment already in [0,1]
            col_min, col_max = series.min(), series.max()
            norm = pd.Series(0.5, index=df.index) if col_max == col_min \
                   else (series - col_min) / (col_max - col_min)
            if col in INVERT_FEATURES:
                norm = 1.0 - norm

        label += weight * norm

    return label


# ── Training ──────────────────────────────────────────────────────────────────

def train(df: pd.DataFrame) -> dict:
    """
    Train XGBoost regressor on fused DataFrame.
    Returns metrics dict. Saves model to disk.
    """
    logger.info(f"Training started | {len(df)} samples")

    # Only use features that actually exist in the DataFrame
    available_features = [c for c in FEATURE_COLUMNS if c in df.columns]
    missing            = [c for c in FEATURE_COLUMNS if c not in df.columns]
    if missing:
        logger.warning(f"Missing features (will be skipped): {missing}")

    if len(df) < 10:
        raise ValueError(f"Not enough data: {len(df)} rows (minimum 10)")

    df = _apply_platform_adjustments(df)

    X = df[available_features].apply(pd.to_numeric, errors="coerce").fillna(0)
    y = generate_labels(df)

    logger.info(f"Label stats — min={y.min():.3f}, max={y.max():.3f}, mean={y.mean():.3f}, std={y.std():.3f}")

    if "source_platform" in df.columns:
        for platform in df["source_platform"].unique():
            mask = df["source_platform"] == platform
            plat = y[mask]
            logger.info(f"  [{platform}] label mean={plat.mean():.3f}, std={plat.std():.3f}, n={mask.sum()}")

    model = XGBRegressor(
        n_estimators=300,
        max_depth=4,           # shallow trees — prevents overfitting on small data
        learning_rate=0.05,    # slow learning = better generalisation
        subsample=0.8,         # row sampling per tree
        colsample_bytree=0.8,  # feature sampling per tree
        reg_alpha=0.1,         # L1 regularisation
        reg_lambda=1.0,        # L2 regularisation
        random_state=42,
        n_jobs=-1,
        verbosity=0,
    )

    cv_folds  = max(2, min(5, len(df) // 5))
    cv_scores = cross_val_score(model, X, y, cv=cv_folds, scoring="r2")
    logger.info(f"Cross-validation R² ({cv_folds} folds): {cv_scores.mean():.3f} ± {cv_scores.std():.3f}")

    model.fit(X, y)

    importances = dict(zip(available_features, model.feature_importances_.round(4)))
    logger.info(f"Feature importances: {importances}")

    joblib.dump({"model": model, "features": available_features}, MODEL_PATH)
    logger.info(f"Model saved → {MODEL_PATH}")

    return {
        "samples":             len(df),
        "features_used":       available_features,
        "cv_r2_mean":          round(float(cv_scores.mean()), 4),
        "cv_r2_std":           round(float(cv_scores.std()), 4),
        "feature_importances": importances,
        "trained_at":          datetime.utcnow().isoformat(),
    }