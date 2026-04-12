from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Dict, Optional
from core.store import JumiaProduct, JijiProduct, KongaProduct
from core.utils.logger import get_logger

logger = get_logger(__name__)

class ProductQueryService:
    """Unified service to query products across all platforms"""
    
    def __init__(self, session: AsyncSession):
        self.session = session
    
    async def search_across_platforms(self, product_name: str, limit: int = 50) -> List[Dict]:
        """Search for a product across all platforms in the database"""
        import asyncio
        
        async def search_platform(platform_name, model):
            try:
                result = await self.session.execute(
                    select(model)
                    .where(model.product_name.ilike(f"%{product_name}%"))
                    .order_by(model.price.asc())
                    .limit(limit)
                )
                products = result.scalars().all()
                
                return [
                    {
                        "platform": platform_name,
                        "product_name": p.product_name,
                        "price": p.price,
                        "currency": getattr(p, 'currency', 'NGN'),
                        "url": p.product_url,
                        "image_url": p.image_url,
                        "rating": p.rating,
                        "review_count": p.review_count,
                        "sentiment_score": p.sentiment_score,
                        "id": p.id
                    }
                    for p in products
                ]
            except Exception as e:
                logger.error(f"Error searching {platform_name}: {e}")
                return []
        
        jumia_task = asyncio.create_task(search_platform("jumia", JumiaProduct))
        konga_task = asyncio.create_task(search_platform("konga", KongaProduct))
        jiji_task = asyncio.create_task(search_platform("jiji", JijiProduct))
        
        results = await asyncio.gather(jumia_task, konga_task, jiji_task)
        
        all_products = []
        for platform_results in results:
            all_products.extend(platform_results)
        
        return all_products
    
    async def get_best_price_for_product(self, product_name: str) -> Optional[Dict]:
        """Get the best price for a product across all platforms"""
        products = await self.search_across_platforms(product_name, limit=1)
        return products[0] if products else None
    
    async def get_price_comparison(self, product_name: str) -> Dict:
        """Get price comparison across all platforms"""
        products = await self.search_across_platforms(product_name, limit=10)
        
        if not products:
            return {
                "found": False,
                "product_name": product_name,
                "message": "No products found"
            }
        
        # Group by platform and get best from each
        best_per_platform = {}
        for product in products:
            platform = product['platform']
            if platform not in best_per_platform or product['price'] < best_per_platform[platform]['price']:
                best_per_platform[platform] = product
        
        # Get overall best
        all_best = min(best_per_platform.values(), key=lambda x: x['price'])
        
        return {
            "found": True,
            "product_name": product_name,
            "best_price": all_best['price'],
            "best_platform": all_best['platform'],
            "best_url": all_best['url'],
            "all_platforms": best_per_platform,
            "all_products": products
        }