"""
fusion/pipeline.py
==================
Layer 3 entry point — async version.

  merge → deduplicate → normalize → save to fused_products
"""

import pandas as pd
from app.store import db_session_manager, FusedProductBaseSchemas, DataFusionQueries
from ..fusion.merger import merge_platforms
from ..fusion.deduplicator import assign_duplicate_groups
from ..fusion.normalizer import normalize
from app.utils.logger        import get_logger

logger = get_logger(__name__)


async def run_fusion(query: str) -> pd.DataFrame:
    logger.info(f"=== Fusion START | query='{query}' ===")

    # Step 1: Merge — async concurrent DB reads
    df = await merge_platforms(query)
    if df.empty:
        logger.error("Fusion aborted — no data to fuse.")
        return pd.DataFrame()
    logger.info(f"Step 1 ✓ — {len(df)} rows merged")

    # Step 2: Deduplicate — now async (concurrent image fetching)
    df = await assign_duplicate_groups(df)
    logger.info("Step 2 ✓ — duplicate groups assigned")

    # Step 3: Normalize — CPU-bound, sync is fine
    df, norm_stats = normalize(df)
    logger.info(f"Step 3 ✓ — normalized {len(df)} rows")

    # Step 4: Save — async DB writes
    saved = await _save_fused(df, query)
    logger.info(f"Step 4 ✓ — {saved} rows saved to fused_products")

    logger.info(f"=== Fusion END | query='{query}' ===")
    return df


async def _save_fused(df: pd.DataFrame, query: str) -> int:
    if df.empty:
        return 0

    string_cols = ["product_name", "category", "product_url", "image_url", "source_platform"]
    for col in string_cols:
        df[col] = df[col].where(pd.notna(df[col]), "").astype(str)

    rows = []
    for _, row in df.iterrows():
        sentiment = row.get("sentiment_score")
        if sentiment is not None:
            sentiment = (sentiment + 1) / 2

        rows.append(
            FusedProductBaseSchemas(
                query           = query,
                source_platform = row.get("source_platform"),
                product_name    = row.get("product_name"),
                category        = row.get("category"),
                price           = row.get("price"),
                currency        = row.get("currency", "NGN"),
                rating          = row.get("rating"),
                review_count    = _safe_int(row.get("review_count")),
                sentiment_score = sentiment,
                product_url     = row.get("product_url"),
                image_url       = row.get("image_url"),
            )
        )

    async with db_session_manager.session() as session:
        fusion_query = DataFusionQueries(session)
        await fusion_query.save_fused_product(rows, query=query)

    return len(rows)



def _safe_int(val) -> int | None:
    try:
        if pd.isna(val):
            return None

        val = int(val)

       
        if val < 0:
            return 0  

        return val

    except (ValueError, TypeError):
        return None


# ── Standalone save (called from main.py after sentiment + normalize) ─────────

async def save_fused(df, query: str) -> int:
    """
    Persist the fully enriched fused DataFrame to the fused_products table.
    Called from main.py after sentiment analysis and normalization are done.
    """
    return await _save_fused(df, query)