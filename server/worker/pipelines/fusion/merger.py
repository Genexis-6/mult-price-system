"""
fusion/merger.py
================
Loads products from all 3 platform tables concurrently using asyncio.gather.
Each platform gets its own session to avoid interference.
Uses the existing query classes (JumiaQueries, JijiQueries, KongaQueries)
instead of raw SQL.
"""

import asyncio
import pandas as pd
from core.store import JijiQueries,JumiaQueries, KongaQueries, db_session_manager
from core.utils import get_logger

logger = get_logger(__name__)


async def _load_single_platform(query_class, query: str) -> tuple[str, pd.DataFrame]:
    """
    Opens its own session, loads products for the query, returns
    (platform_name, DataFrame). Each platform call is fully independent.
    """
    platform = query_class.__name__.replace("Queries", "").lower()  # e.g. "jumia"

    async with db_session_manager.session() as session:
        try:
            repo     = query_class(session)
            products = await repo.load_product(query)

            if not products:
                logger.warning(f"[{platform}] No rows found for query='{query}'")
                return platform, pd.DataFrame()

            # ProductSchemas → list of dicts → DataFrame
            df = pd.DataFrame([p.model_dump() for p in products])
            df["source_platform"] = platform
            logger.info(f"[{platform}] Loaded {len(df)} rows")
            return platform, df

        except Exception as e:
            logger.error(f"[{platform}] Failed to load: {e}")
            return platform, pd.DataFrame()


async def merge_platforms(query: str) -> pd.DataFrame:
    """
    Concurrently load all 3 platform tables for a query using asyncio.gather.
    Each platform gets its own independent session.
    Returns a single merged DataFrame with a `source_platform` column.
    """
    results = await asyncio.gather(
        _load_single_platform(JumiaQueries, query),
        _load_single_platform(JijiQueries,  query),
        _load_single_platform(KongaQueries, query),
        return_exceptions=True,
    )

    frames = []
    for result in results:
        if isinstance(result, Exception):
            logger.error(f"Platform load failed: {result}")
            continue
        platform, df = result
        if not df.empty:
            frames.append(df)

    if not frames:
        logger.error(f"No data found across any platform for query='{query}'")
        return pd.DataFrame()

    merged = pd.concat(frames, ignore_index=True)
    logger.info(f"Merged total: {len(merged)} rows across {len(frames)} platforms")
    return merged