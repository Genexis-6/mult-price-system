"""
ml/features.py
==============
Single source of truth for ML feature names and label generation weights.
"""

# ── Input features for XGBoost ────────────────────────────────────────────────
FEATURE_COLUMNS = [
    # Core features
    "price",              # Z-score normalized
    "rating",             # Z-score normalized
    "review_count",       # log1p + Z-score normalized
    "sentiment_score",    # Z-score normalized

    # Engineered features (added by normalizer)
    "platform_code",      # ordinal: jumia=0, jiji=1, konga=2
    "price_tier",         # quantile bucket: 0=budget, 1=mid, 2=premium, 3=luxury
    "review_log",         # log1p(review_count) standalone
    "price_x_reviews",    # interaction: price × log(review_count+1)
]

# ── Label generation weights ──────────────────────────────────────────────────
# score = 0.35 * sentiment
#       + 0.30 * rating
#       + 0.20 * price_score   (inverted: lower price → higher score)
#       + 0.15 * review_count
LABEL_WEIGHTS = {
    "sentiment_score": 0.35,
    "rating":          0.30,
    "price":           0.20,
    "review_count":    0.15,
}

# Features where lower raw value = better outcome (inverted in label generation)
INVERT_FEATURES = {"price"}

# Use midpoint price strategy (rewards median-priced products, not just cheapest)
PRICE_USE_MIDPOINT = True