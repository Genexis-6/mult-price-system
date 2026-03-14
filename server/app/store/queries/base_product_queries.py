from typing import List, Type
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..schemas import ProductSchemas, ProductSentimentSchemas
from app.utils.logger import get_logger

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

            product_urls = [p.product_url for p in data if p.product_url]

            existing_urls = set()

            if product_urls:
                result = await self.session.execute(
                    select(self.model.product_url).where(
                        self.model.product_url.in_(product_urls)
                    )
                )

                existing_urls = {row[0] for row in result}

            new_products = []
            skipped_count = 0

            for product in data:

                if product.product_url in existing_urls:
                    skipped_count += 1
                    logger.debug(f"Skipping duplicate: {product.product_name}")

                else:
                    new_products.append(product)

            if not new_products:
                logger.info("All products are duplicates")
                return {"inserted": 0, "skipped": skipped_count, "total": len(data)}

            model_fields = {c.key for c in self.model.__table__.columns}

            orm_objects = [
                self.model(
                    **{k: v for k, v in p.model_dump().items() if k in model_fields}
                )
                for p in new_products
            ]

            self.session.add_all(orm_objects)

            await self.session.commit()

            logger.info(
                f"Saved {len(orm_objects)} new products, skipped {skipped_count}"
            )

            return {
                "inserted": len(orm_objects),
                "skipped": skipped_count,
                "total": len(data),
            }

        except Exception as e:
            await self.session.rollback()
            logger.error(f"Error saving bulk data: {e}")
            raise
    
    async def get_products(self) -> List[ProductSentimentSchemas]:
        res = await self.session.execute(select(self.model))
        output = res.scalars().all()
        if output is None:
            return []
        
        
        
        return [ProductSentimentSchemas(
            id=pd.id,
            reviews=pd.reviews_raw
            ) for pd in output if pd.reviews_raw and pd.sentiment_score is None]
    
    
    async def get_product_reviews(self, id: int)-> List[str] | None:
        res = await self.session.execute(select(self.model).where(self.model.id == id))
        if res is None:
            return None
        return res.scalar_one_or_none()
    
    async def add_sentiment_score(self, prd: ProductSentimentSchemas):
        res = await self.session.execute(select(self.model).where(self.model.id == prd.id))
        output = res.scalar_one_or_none()
        
        if output is None:
            return None
        
        output.sentiment_score = prd.score
        
        await self.session.commit()
        