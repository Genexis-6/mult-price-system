"""
fusion/normalizer.py
====================
Normalization pipeline with critical safety fixes:

  sentiment_score → clip to [0,1] first, then Z-score
                    (model outputs can be negative; Pydantic schema requires ≥0)
  rating          → treat 0 as NULL (no rating), impute with neutral 0.5
  review_count    → clip negatives to 0, then log1p + Z-score
                    (negative review_count causes log1p(-inf) = NaN)
  price           → Z-score

Also engineers additional features for the ML model:
  platform_code   → ordinal encoding of source_platform
  price_tier      → quantile-based price bucket (0-3)
  review_log      → log1p(review_count) as a standalone feature
  price_x_reviews → interaction: price × log(review_count + 1)
"""

import numpy as np
import pandas as pd
from core.utils import get_logger

logger = get_logger(__name__)

ZSCORE_FEATURES     = ["price", "rating", "sentiment_score"]
LOG_ZSCORE_FEATURES = ["review_count"]
ALL_NUMERIC_FEATURES = ZSCORE_FEATURES + LOG_ZSCORE_FEATURES

PLATFORM_ENCODING = {"jumia": 0, "jiji": 1, "konga": 2}


# ── NULL imputation & safety clipping ────────────────────────────────────────

def impute_nulls(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # sentiment_score: clip to [0,1] — model can output negatives,
    # Pydantic schema requires >= 0, and negative sentiment is meaningless here
    if "sentiment_score" in df.columns:
        before_clip = (df["sentiment_score"] < 0).sum()
        df["sentiment_score"] = df["sentiment_score"].clip(0, 1)
        if before_clip:
            logger.info(f"Clipped {before_clip} negative sentiment scores to 0")

        null_count = df["sentiment_score"].isna().sum()
        if null_count:
            # NULL sentiment = no reviews analysed → neutral 0.5
            df["sentiment_score"] = df["sentiment_score"].fillna(0.5)
            logger.info(f"Imputed {null_count} NULLs in 'sentiment_score' with neutral=0.5")

    # rating: 0 means "no rating" same as NULL — treat both as neutral
    if "rating" in df.columns:
        no_rating = df["rating"].isna() | (df["rating"] == 0)
        count = no_rating.sum()
        df["rating"] = df["rating"].where(~no_rating, np.nan)   # set 0 → NaN
        valid_median = df["rating"].median()
        # If no product has a rating, use 0 (will be handled by trainer)
        fill_val = valid_median if pd.notna(valid_median) else 0.0
        df["rating"] = df["rating"].fillna(fill_val)
        logger.info(f"Imputed {count} NULLs in 'rating' with {fill_val} (no rating)")

    # review_count: clip negatives to 0 — negative counts cause log1p(-inf)
    if "review_count" in df.columns:
        neg_count = (df["review_count"] < 0).sum()
        if neg_count:
            logger.info(f"Clipped {neg_count} negative review_count values to 0")
        df["review_count"] = df["review_count"].clip(lower=0).fillna(0)
        logger.info(
            f"Imputed {df['review_count'].isna().sum()} NULLs in 'review_count' with 0"
        ) if df["review_count"].isna().sum() else None

    # price: fill nulls with median
    if "price" in df.columns:
        null_count = df["price"].isna().sum()
        if null_count:
            median_val = df["price"].median() or 0.0
            df["price"] = df["price"].fillna(median_val)
            logger.info(f"Imputed {null_count} NULLs in 'price' with median={median_val:.2f}")

    return df


# ── Feature engineering ───────────────────────────────────────────────────────

def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Add derived features that improve ML model performance.
    All engineered features use _raw columns (pre-normalization values).
    """
    df = df.copy()

    # Platform encoding — captures systematic platform differences
    if "source_platform" in df.columns:
        df["platform_code"] = (
            df["source_platform"]
            .map(PLATFORM_ENCODING)
            .fillna(-1)
            .astype(int)
        )
        logger.info("Added feature: platform_code")

    # Price tiers — captures non-linear price effects
    # budget=0, mid=1, premium=2, luxury=3
    if "price" in df.columns:
        try:
            df["price_tier"] = pd.qcut(
                df["price"], q=4, labels=[0, 1, 2, 3], duplicates="drop"
            ).astype(float)
        except ValueError:
            # All prices identical — assign mid tier
            df["price_tier"] = 1.0
        df["price_tier"] = df["price_tier"].fillna(1.0)
        logger.info("Added feature: price_tier")

    # Review log — standalone log-transformed review count
    if "review_count" in df.columns:
        df["review_log"] = np.log1p(pd.to_numeric(df["review_count"], errors="coerce").clip(lower=0).fillna(0))
        logger.info("Added feature: review_log")

    # Interaction: price × review signal
    # High-priced products with many reviews score differently than cheap ones
    if "price" in df.columns and "review_count" in df.columns:
        df["price_x_reviews"] = (
            pd.to_numeric(df["price"], errors="coerce").fillna(0)
            * np.log1p(
                pd.to_numeric(df["review_count"], errors="coerce")
                .clip(lower=0)
                .fillna(0)
            )
        )
        logger.info("Added feature: price_x_reviews")

    return df


# ── Z-score helper ────────────────────────────────────────────────────────────

def _zscore(series: pd.Series) -> tuple[pd.Series, dict]:
    series = pd.to_numeric(series, errors="coerce").fillna(0)
    mean   = series.mean()
    std    = series.std()
    if std == 0 or pd.isna(std):
        logger.warning(f"std=0 or NaN — normalized values set to 0")
        return pd.Series(0.0, index=series.index), {"mean": float(mean), "std": 0.0}
    return (series - mean) / std, {"mean": round(float(mean), 4), "std": round(float(std), 4)}


# ── Main pipeline ─────────────────────────────────────────────────────────────

def normalize(df: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    """
    Full normalization pipeline:
      1. Safety clip + NULL imputation
      2. Feature engineering (platform_code, price_tier, interactions)
      3. Z-score / log1p+Z-score per feature
      4. Preserve raw values in <feature>_raw columns

    Returns:
      df    — normalized DataFrame with engineered features
      stats — {feature: {method, mean, std}} for traceability
    """
    logger.info("Starting normalization...")
    df    = impute_nulls(df)
    df    = engineer_features(df)
    df    = df.copy()
    stats = {}

    # Z-score features
    for col in ZSCORE_FEATURES:
        if col not in df.columns:
            continue
        df[col]            = pd.to_numeric(df[col], errors="coerce").fillna(0)
        df[f"{col}_raw"]   = df[col]
        df[col], col_stats = _zscore(df[col])
        stats[col]         = {"method": "zscore", **col_stats}
        logger.info(f"Z-score normalized '{col}' — mean={col_stats['mean']}, std={col_stats['std']}")

    # log1p + Z-score features
    for col in LOG_ZSCORE_FEATURES:
        if col not in df.columns:
            continue
        df[col]          = pd.to_numeric(df[col], errors="coerce").clip(lower=0).fillna(0)
        df[f"{col}_raw"] = df[col]
        log_series       = np.log1p(df[col])
        df[col], col_stats = _zscore(log_series)
        stats[col]       = {"method": "log1p+zscore", **col_stats}
        logger.info(f"log1p+Z-score normalized '{col}' — mean={col_stats['mean']}, std={col_stats['std']}")

    # Z-score engineered features too
    for col in ["price_x_reviews", "review_log"]:
        if col not in df.columns:
            continue
        df[col], col_stats = _zscore(df[col])
        stats[col]         = {"method": "zscore", **col_stats}

    logger.info("Normalization complete ✓")
    return df, stats