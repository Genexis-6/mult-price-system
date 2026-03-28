"""
ml/predictor.py
===============
Loads the saved Random Forest model, scores/ranks fused products,
and applies a soft platform diversity cap on the final results.

Ranking formula (via Random Forest trained on weighted labels):
  label = 0.40 * sentiment_score  (higher = better)
        + 0.35 * rating            (higher = better)
        + 0.25 * review_count      (more = more trustworthy)

  The model learns non-linear interactions between these features.
  Price is an input feature but has 0 label weight — the model
  discovers its effect through correlation with other features.

Diversity strategy:
  Sort ALL products globally by recommendation_score (highest first).
  Walk down the list and include each product UNLESS one platform
  has already taken MAX_PER_PLATFORM slots — in that case skip and
  continue until a slot opens or another platform fills it.
  This preserves score order while preventing one platform from
  monopolising all top slots.
"""

import json
import joblib
import pandas as pd
from datetime import datetime
from pathlib import Path
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from ..ml.features import FEATURE_COLUMNS
from core.utils.logger import get_logger

logger = get_logger(__name__)

MODEL_PATH      = Path("ml/saved_models/recommender.joblib")
RESULTS_DIR     = Path("ml/saved_models/results")
PLATFORMS       = ["jumia", "jiji", "konga"]

# Maximum slots any single platform can occupy in the top-N results.
# e.g. top_n=10, MAX_PER_PLATFORM=4 → no platform can take more than 4 slots.
# The remaining slots go to whichever other platforms have the next best scores.
MAX_PER_PLATFORM = 4


def model_exists() -> bool:
    return MODEL_PATH.exists()


def load_model():
    if not model_exists():
        raise FileNotFoundError(
            f"No trained model found at {MODEL_PATH}. "
            "Run the training pipeline first."
        )
    return joblib.load(MODEL_PATH)

def predict(df: pd.DataFrame) -> pd.DataFrame:
    bundle   = load_model()
    model    = bundle["model"]
    features = bundle["features"] 

    X = df[features].copy()
    X = X.apply(pd.to_numeric, errors="coerce").fillna(0)

    scores = model.predict(X)

    df = df.copy()
    df["recommendation_score"] = scores
    df = df.sort_values("recommendation_score", ascending=False).reset_index(drop=True)
    df["rank"] = df.index + 1

    return df
def get_top_recommendations(df: pd.DataFrame, top_n: int = 10) -> list[dict]:
    """
    Return top N recommendations ranked by score with a soft platform cap.

    Walk the globally-sorted list in score order.
    Skip a product only if its platform has already filled MAX_PER_PLATFORM slots.
    This means:
      - Rank 1 is always the single highest-scoring product regardless of platform
      - No platform takes more than MAX_PER_PLATFORM of the top_n slots
      - Score order is respected within and across platforms
    """
    platform_counts: dict[str, int] = {p: 0 for p in PLATFORMS}
    results   = []
    seen_urls = set()

    for _, row in df.iterrows():
        if len(results) >= top_n:
            break

        platform = row.get("source_platform", "")
        url      = row.get("product_url", "")

        if url in seen_urls:
            continue

        if platform_counts.get(platform, 0) >= MAX_PER_PLATFORM:
            logger.debug(
                f"Skipping '{row.get('product_name', '')[:40]}' "
                f"— {platform} already has {MAX_PER_PLATFORM} slots"
            )
            continue

        seen_urls.add(url)
        platform_counts[platform] = platform_counts.get(platform, 0) + 1
        results.append(_format_result(row, len(results) + 1))

    # If we're still short (e.g. one platform dominates after cap),
    # fill remaining from the global list ignoring the cap
    if len(results) < top_n:
        logger.warning(
            f"Only {len(results)}/{top_n} slots filled after diversity cap — "
            "filling remainder without platform constraint"
        )
        for _, row in df.iterrows():
            if len(results) >= top_n:
                break
            url = row.get("product_url", "")
            if url not in seen_urls:
                seen_urls.add(url)
                results.append(_format_result(row, len(results) + 1))

    logger.info(
        f"Top {len(results)} recommendations | "
        f"platform slots: {platform_counts}"
    )
    return results


def _format_result(row: pd.Series, rank: int) -> dict:
    return {
        "rank":                 rank,
        "product_name":        row.get("product_name"),
        "source_platform":     row.get("source_platform"),
        "price":               _safe_float(row.get("price_raw")),
        "currency":            row.get("currency", "NGN"),
        "rating":              _safe_float(row.get("rating_raw")),
        "review_count":        _safe_int(row.get("review_count_raw")),
        "sentiment_score":     _safe_float(row.get("sentiment_score_raw")),
        "recommendation_score": round(float(row["recommendation_score"]), 4),
        "product_url":         row.get("product_url"),
        "image_url":           row.get("image_url"),
    }


# ── JSON result storage ───────────────────────────────────────────────────────

def save_results_json(
    recommendations: list[dict],
    query: str,
    metrics: dict | None = None,
) -> Path:
    """Save recommendations to JSON. Writes timestamped + latest files."""
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)

    safe_query  = query.replace(" ", "_").replace("/", "-")[:50]
    timestamp   = datetime.utcnow().strftime("%Y%m%d_%H%M%S")

    payload = {
        "query":            query,
        "generated_at":     datetime.utcnow().isoformat(),
        "total_results":    len(recommendations),
        "training_metrics": metrics or {},
        "recommendations":  recommendations,
    }

    timestamped = RESULTS_DIR / f"{safe_query}_{timestamp}.json"
    latest      = RESULTS_DIR / f"{safe_query}_latest.json"

    for path in (timestamped, latest):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2, default=str)

    logger.info(f"Results saved → {timestamped}")
    logger.info(f"Latest        → {latest}")
    return timestamped


def load_results_json(query: str) -> dict | None:
    """Load the latest saved results for a query. Returns None if not found."""
    safe_query = query.replace(" ", "_").replace("/", "-")[:50]
    latest     = RESULTS_DIR / f"{safe_query}_latest.json"

    if not latest.exists():
        logger.warning(f"No saved results for query='{query}'")
        return None

    with open(latest, "r", encoding="utf-8") as f:
        return json.load(f)


# ── DB persistence ────────────────────────────────────────────────────────────

async def save_scores(df: pd.DataFrame, query: str, session: AsyncSession) -> int:
    from core.store import FusedProduct

    updated = 0
    for _, row in df.iterrows():
        if pd.isna(row.get("recommendation_score")):
            continue
        await session.execute(
            update(FusedProduct)
            .where(
                FusedProduct.query == query,
                FusedProduct.product_url == row.get("product_url"),
            )
            .values(recommendation_score=float(row["recommendation_score"]))
        )
        updated += 1

    await session.commit()
    logger.info(f"Saved scores for {updated} products (query='{query}')")
    return updated


# ── Helpers ───────────────────────────────────────────────────────────────────

def _safe_float(val) -> float | None:
    try:
        return round(float(val), 4) if val is not None and val == val else None
    except (TypeError, ValueError):
        return None


def _safe_int(val) -> int | None:
    try:
        return int(val) if val is not None and val == val else None
    except (TypeError, ValueError):
        return None