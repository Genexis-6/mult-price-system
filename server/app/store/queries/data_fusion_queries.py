from typing import List

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import delete

from app.store import FusedProductBaseSchemas, FusedProduct
from app.utils.logger import get_logger

logger = get_logger(__name__)


class DataFusionQueries:
    def __init__(self, db: AsyncSession):
        self.session = db

    async def save_fused_product(self, products: List[FusedProductBaseSchemas], query: str) -> int:
        # Guard — don't wipe existing data if there's nothing new to replace it
        if not products:
            logger.warning(f"save_fused_product called with empty list for query='{query}' — skipping")
            return 0

        await self.session.execute(
            delete(FusedProduct).where(FusedProduct.query == query)
        )

        db_products = [FusedProduct(**product.model_dump()) for product in products]
        self.session.add_all(db_products)
        await self.session.commit()

        logger.info(f"Saved {len(db_products)} fused products for query='{query}'")
        return len(db_products)