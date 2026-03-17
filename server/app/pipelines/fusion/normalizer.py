"""
fusion/normalizer.py
====================
Normalization of numeric ML features.

Strategy per feature:
  - price          → Z-score  (roughly normal distribution)
  - rating         → Z-score  (bounded 0-5, roughly normal)
  - sentiment_score → Z-score  (bounded -1 to 1, roughly normal)
  - review_count   → log1p then Z-score
                     (heavily right-skewed: most products have 0-10 reviews,
                      a few have hundreds — log compression prevents outliers
                      from collapsing all other values to near zero)

log1p formula:   log(1 + x)  — the +1 handles zeros safely (log(0) = -inf)
Z-score formula: (x - mean) / std
"""

import numpy as np
import pandas as pd
from app.utils.logger import get_logger

logger = get_logger(__name__)

# Features normalized with Z-score only
ZSCORE_FEATURES = ["price", "rating", "sentiment_score"]

# Features normalized with log1p first, then Z-score
LOG_ZSCORE_FEATURES = ["review_count"]

ALL_NUMERIC_FEATURES = ZSCORE_FEATURES + LOG_ZSCORE_FEATURES


# ── NULL imputation ───────────────────────────────────────────────────────────

def impute_nulls(df: pd.DataFrame) -> pd.DataFrame:
    """
    Fill NULLs in numeric features with the column median.

    Special case for review_count:
      Jiji and Konga often have NULL review_count.
      We impute with 0 (not median) because NULL genuinely means
      "no reviews recorded" — it's not missing data, it's a real zero.
    """
    df = df.copy()

    for col in ALL_NUMERIC_FEATURES:
        if col not in df.columns:
            continue

        null_count = df[col].isna().sum()
        if null_count == 0:
            continue

        if col == "review_count":
            # NULL review_count = no reviews = 0, not the median
            df[col] = df[col].fillna(0)
            logger.info(f"Imputed {null_count} NULLs in 'review_count' with 0")
        else:
            median_val = df[col].median()
            if pd.isna(median_val):
                median_val = 0.0
                logger.warning(f"No non-null values for '{col}' — filling with 0")
            df[col] = df[col].fillna(median_val)
            logger.info(f"Imputed {null_count} NULLs in '{col}' with median={median_val:.4f}")

    return df


# ── Normalization ─────────────────────────────────────────────────────────────

def _zscore(series: pd.Series) -> tuple[pd.Series, dict]:
    """Z-score normalize a series. Returns normalized series + stats dict."""
    series = pd.to_numeric(series, errors="coerce").fillna(0)
    mean   = series.mean()
    std    = series.std()
    if std == 0:
        logger.warning(f"std=0 — all normalized values set to 0")
        return pd.Series([0.0] * len(series), index=series.index), {"mean": mean, "std": std}
    return (series - mean) / std, {"mean": round(mean, 4), "std": round(std, 4)}


def normalize(df: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    """
    Full normalization pipeline:
      1. Impute NULLs
      2. Apply appropriate normalization per feature
      3. Preserve raw values in <feature>_raw columns

    Returns:
      df    — normalized DataFrame
      stats — {feature: {method, mean, std}} for traceability
    """
    logger.info("Starting normalization...")
    df    = impute_nulls(df)
    df    = df.copy()
    stats = {}

    # Z-score only features
    for col in ZSCORE_FEATURES:
        if col not in df.columns:
            continue
        df[col]            = pd.to_numeric(df[col], errors="coerce").fillna(0)
        df[f"{col}_raw"]   = df[col]
        df[col], col_stats = _zscore(df[col])
        stats[col]         = {"method": "zscore", **col_stats}
        logger.info(f"Z-score normalized '{col}' — mean={col_stats['mean']}, std={col_stats['std']}")

    # log1p → Z-score features
    for col in LOG_ZSCORE_FEATURES:
        if col not in df.columns:
            continue
        df[col]          = pd.to_numeric(df[col], errors="coerce").fillna(0)
        df[f"{col}_raw"] = df[col]                        # preserve original count

        log_series       = np.log1p(df[col])              # log(1 + x)
        df[col], col_stats = _zscore(log_series)
        stats[col]       = {"method": "log1p+zscore", **col_stats}
        logger.info(
            f"log1p+Z-score normalized '{col}' — "
            f"log mean={col_stats['mean']}, log std={col_stats['std']}"
        )

    logger.info("Normalization complete ✓")
    return df, stats