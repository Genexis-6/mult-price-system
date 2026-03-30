"""
main.py — Pipeline entry point

Flow:
  1. ETL       — scrape Jumia, Konga, Jiji in parallel → store in platform tables
  2. Fusion    — merge tables, detect cross-platform duplicates
  3. Sentiment — RoBERTa inference on reviews → writes scores back to DB
  4. Reload    — re-read updated sentiment scores from DB into DataFrame
  5. Normalize — clip/impute, engineer features, Z-score/log1p normalize
  6. ML        — train XGBoost (if mode="train_model") then score & rank
  7. Output    — return top N recommendations with platform + buy link

Two modes:
  "train_model" — retrain on fresh data every run (scheduled refresh)
  "predict"     — skip training, use saved model (fast user-facing queries)
"""

import asyncio
from typing import Literal, Optional
import redis

from core.task_definition import TaskResults
from .etl.jumia                    import JumiaETL
from .etl.konga                    import KongaETL
from .etl.jiji                     import JijiETL
from .fusion.merger                import merge_platforms
from .fusion.deduplicator          import assign_duplicate_groups
from .fusion.normalizer            import normalize
from .fusion.pipeline              import save_fused
from .sentiment.sentiment_analizer import run_sentiment
from .ml.main                      import run_ml
from core.utils.logger              import get_logger
from core.schemas import RedisPublishSchemas
from ..helper import publish_redis_job

logger = get_logger(__name__)


# ── Layer 1: ETL ──────────────────────────────────────────────────────────────

async def run_etl_layer(query: str, pages: int = 2) -> dict:
    """Run all 3 ETLs concurrently. Returns row counts per platform."""
    etls = {
        "jumia": JumiaETL(),
        "konga": KongaETL(),
        "jiji":  JijiETL(),
    }

    tasks = {
        name: asyncio.create_task(etl.run(query, pages))
        for name, etl in etls.items()
    }

    results = {}
    for name, task in tasks.items():
        try:
            count         = await task
            results[name] = count
            logger.info(f"✓ {name}: {count} products loaded")
        except Exception as e:
            results[name] = 0
            logger.error(f"✗ {name}: failed — {e}")

    return results


# ── Full pipeline ─────────────────────────────────────────────────────────────

async def run_full_pipeline(
    
    query: str,
    pages: int = 2,
    mode:  Optional[Literal["train_model", "predict"]] = "train_model",
    redis: redis.Redis = None,
    task_id:Optional[str] = None
    
) -> list[dict]:
    """
    Orchestrates the full recommendation pipeline for a search query.

    Args:
        query: User search term e.g. "samsung phone"
        pages: Number of pages to scrape per platform
        mode:  "train_model" → scrape + retrain + predict (scheduled refresh)
               "predict"     → scrape + predict only (fast user-facing path)

    Returns:
        Ranked list of product recommendation dicts.
    """
    logger.info(f"=== Pipeline START | query='{query}' | mode={mode} ===")

    # ── Layer 1: ETL ──────────────────────────────────────────────────────────
    etl_results   = await run_etl_layer(query, pages)
    total_scraped = sum(etl_results.values())
    logger.info(f"Layer 1 ✓ ETL: {etl_results} | total={total_scraped}")

    if total_scraped == 0:
        logger.error("No products scraped — aborting pipeline.")
        return []
    
    if etl_results:
        await publish_redis_job(redis, RedisPublishSchemas(
            task_id=task_id,
            progress=10,
            message="Matching similar products across platforms..."
        ))
        
    # ── Layer 2: Fusion (merge + dedup, no normalization yet) ─────────────────
    df = await merge_platforms(query)
    if df.empty:
        logger.error("Fusion returned empty DataFrame — aborting.")
        return []

    df = await assign_duplicate_groups(df)
    logger.info(
        f"Layer 2 ✓ Fusion: {len(df)} listings | "
        f"{int(df['is_duplicate'].sum())} cross-platform duplicates flagged"
    )
    if df:
        await publish_redis_job(redis, RedisPublishSchemas(
            task_id=task_id,
            progress=30,
            message="Analyzing customer reviews..."
        ))

    # ── Layer 3: Sentiment ─────────────────────────────────────────────────────
    # Self-contained: fetches from DB, runs inference, writes scores back to DB.
    await run_sentiment()
    logger.info("Layer 3 ✓ Sentiment: scores written to DB")

    # ── Layer 4: Reload with sentiment scores ──────────────────────────────────
    # Re-merge so the DataFrame has the freshly written sentiment_score values.

    
    df = await merge_platforms(query)
    if df.empty:
        logger.warning(f"Layer 4 ✗ No data found for query='{query}' after reload")
        return []

    logger.info(
        f"Layer 4 ✓ Reload: {df['sentiment_score'].notna().sum()}/{len(df)} "
        f"listings have sentiment scores"
    )
    if df:
        await publish_redis_job(redis, RedisPublishSchemas(
            task_id=task_id,
            progress=50,
            message="Preparing data for ranking..."
        ))

    # ── Layer 5: Normalize ─────────────────────────────────────────────────────
    df, norm_stats = normalize(df)
    logger.info(f"Layer 5 ✓ Normalize: {list(norm_stats.keys())}")

    # Persist enriched fused DataFrame to fused_products table
    await save_fused(df, query)
    if df:
        await publish_redis_job(redis, RedisPublishSchemas(
            task_id=task_id,
            status="progress",
            progress=70,
            message="Ranking the best products..."
        ))

    # ── Layer 6: ML ────────────────────────────────────────────────────────────
    recommendations = await run_ml(df, query, mode=mode)
    logger.info(f"Layer 6 ✓ ML: {len(recommendations)} recommendations | mode={mode}")

    logger.info(f"=== Pipeline END | query='{query}' ===")
    return recommendations