"""
Price Check Pipeline - Scrapes fresh data for price tracking
"""

import asyncio
from typing import List, Dict, Optional
from worker.pipelines.etl.jumia import JumiaETL
from worker.pipelines.etl.konga import KongaETL
from worker.pipelines.etl.jiji import JijiETL
from core.store import db_session_manager
from core.store.queries.product_queries import ProductQueryService
from core.utils.logger import get_logger

logger = get_logger(__name__)

class PriceCheckPipeline:
    """Scrapes fresh product prices from all platforms for price tracking"""
    
    def __init__(self):
        self.etls = {
            "jumia": JumiaETL(),
            "konga": KongaETL(),
            "jiji": JijiETL(),
        }
    
    async def check_product_prices(self, query: str, target_price: float = None, pages: int = 1) -> List[Dict]:
        """Scrape fresh prices, load to DB, then query for best match"""
        logger.info(f"🔍 Scraping fresh prices for: {query} (Target: ₦{target_price:,.0f} if provided)")
        
        async def scrape_and_load(platform_name, etl):
            try:
                # Run ETL - this loads data to database
                count = await etl.run(query, pages)
                logger.info(f"✓ {platform_name}: Loaded {count} products into DB")
                return platform_name
            except Exception as e:
                logger.error(f"❌ Failed to scrape {platform_name}: {e}")
                return None
        
        # Run all ETLs in parallel to load data
        tasks = [
            scrape_and_load(name, etl) 
            for name, etl in self.etls.items()
        ]
        
        await asyncio.gather(*tasks)
        
        # Now query the database for products
        async with db_session_manager.session() as session:
            query_service = ProductQueryService(session)
            
            # Search for products across all platforms
            all_products = await query_service.search_across_platforms(query, limit=50)
            
            if not all_products:
                logger.warning(f"No products found in database for {query}")
                return []
            
            # If target price provided, find closest match from each platform
            if target_price:
                # Group by platform
                platform_products = {}
                for product in all_products:
                    platform = product['platform']
                    if platform not in platform_products:
                        platform_products[platform] = []
                    platform_products[platform].append(product)
                
                # Find closest to target price for each platform
                results = []
                for platform, products in platform_products.items():
                    if products:
                        # Find product closest to target price
                        closest = min(products, key=lambda x: abs(x['price'] - target_price))
                        price_diff = abs(closest['price'] - target_price)
                        results.append(closest)
                        logger.info(f"✓ {platform}: Found {len(products)} products, closest to target: ₦{closest['price']:,.0f} (diff: ₦{price_diff:,.0f})")
                
                return results
            else:
                # Return all products sorted by price
                all_products.sort(key=lambda x: x['price'])
                logger.info(f"✅ Found {len(all_products)} products across all platforms")
                return all_products
    
    async def get_best_price(self, query: str, target_price: float = None) -> Optional[Dict]:
        """Get the best match across all platforms"""
        results = await self.check_product_prices(query, target_price)
        
        if not results:
            return None
        
        if target_price:
            # Find product closest to target price
            best = min(results, key=lambda x: abs(x['price'] - target_price))
            logger.info(f"🏆 Best match for {query} (target ₦{target_price:,.0f}): ₦{best['price']:,} on {best['platform']} (diff: ₦{abs(best['price'] - target_price):,.0f})")
        else:
            # Find cheapest product
            best = min(results, key=lambda x: x['price'])
            logger.info(f"🏆 Best price for {query}: ₦{best['price']:,} on {best['platform']}")
        
        return best
    
    async def compare_with_target(self, query: str, target_price: float) -> Dict:
        """Compare current prices with target price by scraping fresh data"""
        # This will scrape, load to DB, then query
        results = await self.check_product_prices(query, target_price)
        
        if not results:
            return {
                "product_name": query,
                "target_price": target_price,
                "found": False,
                "message": "No products found"
            }
        
        # Find best match for target price (closest to target)
        best = min(results, key=lambda x: abs(x['price'] - target_price))
        
        # Create detailed platform results
        all_platforms = {}
        for product in results:
            price_diff = abs(product['price'] - target_price)
            all_platforms[product['platform']] = {
                "price": product['price'],
                "product_name": product['product_name'],
                "url": product['url'],
                "image_url": product.get('image_url', ''),
                "price_difference": price_diff,
                "is_closest": product['platform'] == best['platform']
            }
        
        return {
            "product_name": query,
            "target_price": target_price,
            "current_best_price": best['price'],
            "current_best_platform": best['platform'],
            "current_best_url": best['url'],
            "current_best_image": best.get('image_url', ''),
            "current_best_name": best.get('product_name', ''),
            "price_difference": abs(best['price'] - target_price),
            "savings": max(0, target_price - best['price']),
            "savings_percentage": ((target_price - best['price']) / target_price * 100) if best['price'] < target_price else 0,
            "is_target_reached": best['price'] <= target_price,
            "all_platforms": all_platforms,
            "found": True
        }

price_check_pipeline = PriceCheckPipeline()