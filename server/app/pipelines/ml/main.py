"""
ml/pipeline.py
==============
Layer 4 entry point.

Two modes controlled by the `mode` parameter:

  "train_model" — retrain XGBoost on fresh fused data, then predict
  "predict"     — skip training, score with existing saved model only

Usage:
  # First run or scheduled refresh → retrain
  await run_ml(df, query, mode="train_model")

  # User query with cached data → predict only (faster)
  await run_ml(df, query, mode="predict")
"""

from typing import Literal, Optional

import pandas as pd

from ..ml.trainer  import train
from ..ml.preditor import predict, save_scores, get_top_recommendations, model_exists, save_results_json
from app.store     import db_session_manager
from app.utils.logger import get_logger

logger = get_logger(__name__)


async def run_ml(
    df:     pd.DataFrame,
    query:  str,
    top_n:  int = 10,
    mode:   Optional[Literal["train_model", "predict"]] = "train_model",
) -> list[dict]:
    """
    Full ML pipeline.

    Args:
        df:    Fused, normalized DataFrame from Layer 5
        query: Original search query (used for DB updates + JSON file naming)
        top_n: Number of top recommendations to return
        mode:  "train_model" → retrain then predict
               "predict"     → predict only (faster, uses saved model)

    Returns:
        Ranked list of product dicts ready for the API response.
    """
    logger.info(f"=== ML START | query='{query}' | {len(df)} products | mode={mode} ===")

    if df.empty:
        logger.error("ML aborted — empty DataFrame.")
        return []

    # ── Guard: predict mode requires a saved model ────────────────────────────
    if mode == "predict" and not model_exists():
        logger.warning(
            "mode='predict' requested but no saved model found. "
            "Switching to 'train_model' for this run."
        )
        mode = "train_model"

    # ── Step 1: Train (only in train_model mode) ──────────────────────────────
    metrics = {}
    if mode == "train_model":
        try:
            metrics = train(df)
            logger.info(
                f"Training ✓ — "
                f"R²={metrics['cv_r2_mean']} ± {metrics['cv_r2_std']} | "
                f"samples={metrics['samples']}"
            )
        except ValueError as e:
            logger.warning(f"Training skipped: {e}")
            if not model_exists():
                logger.error("No trained model available. Cannot score products.")
                return []

    # ── Step 2: Score and rank ────────────────────────────────────────────────
    ranked_df = predict(df)
    logger.info(f"Ranking ✓ — {len(ranked_df)} products scored")

    # ── Step 3: Persist scores to DB ─────────────────────────────────────────
    async with db_session_manager.session() as session:
        await save_scores(ranked_df, query, session)

    # ── Step 4: Build top N + save JSON ──────────────────────────────────────
    recommendations = get_top_recommendations(ranked_df, top_n=top_n)
    save_results_json(recommendations, query=query, metrics=metrics)

    logger.info(f"=== ML END | {len(recommendations)} recommendations | mode={mode} ===")
    return recommendations