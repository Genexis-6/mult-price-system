import asyncio
# from .etl.jumia import JumiaETL
# from .etl.konga import KongaETL
from .etl.jiji import JijiETL
from app.utils.logger import get_logger

logger = get_logger("main")


async def run_etl_layer(query: str, pages: int = 3) -> dict:
    etls = {
        # "konga": KongaETL(),
        "jiji":  JijiETL(),
        
    }

    # Run all ETLs concurrently in the same event loop
    tasks = {
        name: asyncio.create_task(etl.run(query, pages))
        for name, etl in etls.items()
    }

    results = {}
    for name, task in tasks.items():
        try:
            count = await task
            results[name] = count
            logger.info(f"✓ {name}: {count} products loaded")
        except Exception as e:
            results[name] = 0
            logger.error(f"✗ {name}: failed — {e}")

    return results


async def run_full_pipeline(query: str, pages: int = 1) -> None:
    logger.info(f"=== Pipeline START | query='{query}' ===")

    etl_results = await run_etl_layer(query, pages)
    logger.info(f"ETL complete: {etl_results}")

    logger.info("Layer 2: Sentiment analysis — coming next")
    logger.info("Layer 3: Data fusion — coming next")
    logger.info("Layer 4: ML recommendation — coming next")

    logger.info(f"=== Pipeline END | query='{query}' ===")