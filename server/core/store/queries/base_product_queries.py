from typing import List, Type
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.postgresql import insert

from core.schemas import ProductSchemas, ProductSentimentSchemas
from core.utils import get_logger

logger = get_logger(__name__)


class BaseProductQueries:

    def __init__(self, db: AsyncSession, model: Type):
        self.session = db
        self.model = model

    async def save_bulk_data(self, data: List[ProductSchemas]) -> dict:
        try:
            if not data:
                logger.info("No data to save")
                return {"inserted": 0, "skipped": 0, "total": 0}

            # Exclude 'id' — let PostgreSQL auto-generate it via the sequence.
            # Including id=None in the INSERT causes NotNullViolationError with asyncpg.
            model_fields = {
                c.key for c in self.model.__table__.columns
                if not c.primary_key
            }

            rows = [
                {k: v for k, v in p.model_dump().items() if k in model_fields}
                for p in data
            ]

            stmt = (
                insert(self.model)
                .values(rows)
                .on_conflict_do_nothing(index_elements=["product_url"])
            )

            result = await self.session.execute(stmt)
            await self.session.commit()

            inserted = result.rowcount
            skipped  = len(data) - inserted

            logger.info(f"Saved {inserted} new products, skipped {skipped}")
            return {"inserted": inserted, "skipped": skipped, "total": len(data)}

        except Exception as e:
            await self.session.rollback()
            logger.error(f"Error saving bulk data: {e}")
            raise

    async def get_products(self) -> List[ProductSentimentSchemas]:
        res    = await self.session.execute(select(self.model))
        output = res.scalars().all()
        if not output:
            return []
        return [
            ProductSentimentSchemas(id=pd.id, reviews=pd.reviews_raw)
            for pd in output
            if pd.reviews_raw and pd.sentiment_score is None
        ]

    async def get_product_reviews(self, id: int) -> List[str] | None:
        res = await self.session.execute(
            select(self.model).where(self.model.id == id)
        )
        return res.scalar_one_or_none()

    async def add_sentiment_score(self, prd: ProductSentimentSchemas):
        res    = await self.session.execute(
            select(self.model).where(self.model.id == prd.id)
        )
        output = res.scalar_one_or_none()
        if output is None:
            return None
        output.sentiment_score = prd.score
        await self.session.commit()

    async def load_product(self, query: str) -> List[ProductSchemas]:
        res    = await self.session.execute(
            select(self.model).where(self.model.query == query)
        )
        output = res.scalars().all()
        if not output:
            return []
        return [
            ProductSchemas(
                id              = prd.id,
                query           = prd.query,
                product_name    = prd.product_name,
                category        = prd.category,
                price           = prd.price,
                currency        = prd.currency,
                rating          = prd.rating,
                review_count    = prd.review_count,
                product_url     = prd.product_url,
                image_url       = prd.image_url,
                sentiment_score = prd.sentiment_score,
                scraped_at      = prd.scraped_at,
            )
            for prd in output
        ]