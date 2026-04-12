import asyncio
import json
from typing import List, Dict, Optional
from datetime import datetime, timedelta

from fastapi import HTTPException
from core.store.queries.price_tracking_queries import PriceTrackingQueries
from core.notification.email_service import EmailService
from worker.pipelines.price_tracking import price_check_pipeline
from core.redis import get_redis
from core.utils.logger import get_logger

logger = get_logger(__name__)

class PriceTrackingService:
    def __init__(self, db_session):
        self.db = db_session
        self.queries = PriceTrackingQueries(db_session)
        self.email_service = EmailService()
    
    async def check_all_alerts(self):
        """Check all alerts that are due for checking (24-hour schedule)"""
        logger.info("🔍 Starting price check for due alerts")
        
        alerts = await self.queries.get_alerts_due_for_check()
        logger.info(f"Found {len(alerts)} alerts due for check")
        
        results = []
        for alert in alerts:
            try:
                result = await self._check_single_alert(alert)
                results.append(result)
                
                # Schedule next check in 24 hours
                await self.queries.update_alert_check_schedule(alert.id)
                
                # Publish update via Redis for WebSocket
                await self._publish_alert_update(alert, result)
                
                await asyncio.sleep(2)  # Rate limiting
            except Exception as e:
                logger.error(f"Failed to check alert {alert.id}: {e}")
        
        triggered = len([r for r in results if r])
        logger.info(f"✅ Price check completed: {triggered} alerts triggered")
        return results
    
    async def check_single_alert(self, alert_id: int):
        """Check a single alert (immediate/manual check)"""
        alert = await self.queries.get_alert_by_id(alert_id)
        if alert:
            result = await self._check_single_alert(alert)
            # Reset schedule after manual check
            await self.queries.update_alert_check_schedule(alert_id)
            # Publish update
            await self._publish_alert_update(alert, result)
            return result
        return None
    
    async def _check_single_alert(self, alert):
        """Internal method to check a single alert"""
        logger.info(f"🔍 Checking alert {alert.id}: {alert.product_name}")

        comparison = await price_check_pipeline.compare_with_target(
            query=alert.product_name,
            target_price=alert.target_price
        )
        
        if not comparison['found']:
            logger.warning(f"No products found for {alert.product_name}")
            return None
        
        # Prepare all platform prices for history
        all_prices = []
        for platform, data in comparison['all_platforms'].items():
            all_prices.append({
                "platform": platform,
                "price": data['price'],
                "product_name": data.get('product_name', alert.product_name),
                "url": data.get('url', '')
            })
        
        # Update alert with current best prices
        await self.queries.update_alert_prices(
            alert_id=alert.id,
            best_price=comparison['current_best_price'],
            best_platform=comparison['current_best_platform'],
            best_url=comparison['current_best_url'],
            all_prices=all_prices
        )
        
        # Check if target price is reached
        if comparison['is_target_reached'] and not alert.notification_sent:
            logger.info(f"🎯 Alert {alert.id} triggered! Target: ₦{alert.target_price:,}, Current: ₦{comparison['current_best_price']:,}")
            
            # Send email notification
            await self._send_price_alert_email(alert, comparison)
            
            # Mark as triggered (no more checks)
            await self.queries.mark_alert_triggered(alert.id)
            
            return True
        
        return False
    
    async def _publish_alert_update(self, alert, triggered: bool):
        """Publish alert update to Redis for WebSocket broadcasting"""
        try:
            redis_client = await get_redis()
            
            update_data = {
                "type": "price_alert_update",
                "alert_id": alert.id,
                "product_name": alert.product_name,
                "target_price": alert.target_price,
                "current_best_price": alert.current_best_price,
                "current_best_platform": alert.current_best_platform,
                "target_reached": triggered,
                "status": alert.status,
                "next_check_at": alert.next_check_at.isoformat() if alert.next_check_at else None,
                "timestamp": datetime.now().isoformat()
            }
            
            # Publish to user-specific channel
            await redis_client.publish(
                f"price_alerts:{alert.email}",
                json.dumps(update_data)
            )
            logger.info(f"📡 Published price alert update for {alert.email}")
            
        except Exception as e:
            logger.error(f"Failed to publish alert update: {e}")
    
    async def _send_price_alert_email(self, alert, comparison):
        """Send email notification for price alert"""
        await self.email_service.send_price_alert_with_comparison(
            email=alert.email,
            product_name=alert.product_name,
            target_price=alert.target_price,
            best_price=comparison['current_best_price'],
            best_platform=comparison['current_best_platform'],
            best_url=comparison['current_best_url'],
            all_platform_prices=comparison['all_platforms'],
            savings=comparison['savings'],
            savings_percentage=comparison['savings_percentage']
        )
        
        
    async def create_alert(self, email: str, product_name: str, target_price: float):
        """Create a new price alert - worker will handle the check"""
        from core.schemas.price_tracking_schemas import CreatePriceAlertSchema
        
        # Check for existing alert
        existing_alert = await self.queries.get_active_alert_by_product(email, product_name)
        
        if existing_alert:
            logger.warning(f"Active alert already exists for {product_name} (ID: {existing_alert.id})")
            raise HTTPException(
                status_code=400, 
                detail=f"You already have an active price alert for '{product_name}'. Please wait for it to trigger or cancel it first."
            )
        
        alert_data = CreatePriceAlertSchema(
            email=email,
            product_name=product_name,
            target_price=target_price
        )
        
        alert = await self.queries.create_alert(alert_data)
        
        # Send welcome email (fast operation)
        await self.email_service.send_welcome_email(email)
        
        # Schedule first check in 5 seconds (offload to worker)
        await self.queries.update_alert_check_schedule(alert.id, hours=0, minutes=0, seconds=5)
        
        # Trigger worker task for immediate check
        try:
            from worker.price_checker_task import check_single_alert_task
            await check_single_alert_task.kiq(alert.id)
            logger.info(f"📤 Queued price check task for alert {alert.id}")
        except Exception as e:
            logger.error(f"Failed to queue task: {e}")
        
        return alert