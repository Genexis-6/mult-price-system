from typing import List
from sqlalchemy import select, and_
from ..schemas import ProductSchemas
from ..connection import AsyncSession
from ..models import JumiaProduct
from app.utils.logger import get_logger

logger = get_logger(__name__)

class JumiaQueries():
    def __init__(self, db: AsyncSession):
        self.__session = db
        
    async def save_bulk_jumia_data(self, data: List[ProductSchemas]) -> dict:
        """
        Save multiple products with duplicate checking.
        Returns dict with inserted and skipped counts.
        """
        try:
            if not data:
                logger.info("No data to save")
                return {"inserted": 0, "skipped": 0, "total": 0}
            
            # Extract URLs that exist
            product_urls = [product.product_url for product in data if product.product_url]
            
            existing_urls = set()
            if product_urls:
                # Check for existing products by URL
                result = await self.__session.execute(
                    select(JumiaProduct.product_url).where(
                        JumiaProduct.product_url.in_(product_urls)
                    )
                )
                existing_urls = {row[0] for row in result}
            
            new_products = []
            skipped_count = 0
            
            for product in data:
                if product.product_url in existing_urls:
                    skipped_count += 1
                    logger.debug(f"Skipping duplicate product: {product.product_name}")
                else:
                    new_products.append(product)
            
            if not new_products:
                logger.info("All products are duplicates, nothing to insert")
                return {"inserted": 0, "skipped": skipped_count, "total": len(data)}
            
        
            model_fields = {c.key for c in JumiaProduct.__table__.columns}
            orm_objects = [
                JumiaProduct(**{k: v for k, v in product.model_dump().items() if k in model_fields})
                for product in new_products
            ]
            
            
            self.__session.add_all(orm_objects)
            
        
            await self.__session.commit()
            
            logger.info(
                f"Saved {len(orm_objects)} new products, "
                f"skipped {skipped_count} duplicates"
            )
            
            return {
                "inserted": len(orm_objects),
                "skipped": skipped_count,
                "total": len(data)
            }
            
        except Exception as e:
            await self.__session.rollback()
            logger.error(f"Error saving bulk data: {e}")
            raise