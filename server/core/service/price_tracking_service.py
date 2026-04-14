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
                
                await self.queries.update_alert_check_schedule(alert.id)
                await self._publish_alert_update(alert, result)
                
                if result:
                    await self._send_push_notification_for_alert(alert.id)
                
                await asyncio.sleep(2)
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
            await self.queries.update_alert_check_schedule(alert_id)
            await self._publish_alert_update(alert, result)
            
            if result:
                await self._send_push_notification_for_alert(alert_id)
            
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
            return False
        
        all_prices = []
        for platform, data in comparison['all_platforms'].items():
            all_prices.append({
                "platform": platform,
                "price": data['price'],
                "product_name": data.get('product_name', alert.product_name),
                "url": data.get('url', '')
            })
        
        await self.queries.update_alert_prices(
            alert_id=alert.id,
            best_price=comparison['current_best_price'],
            best_platform=comparison['current_best_platform'],
            best_url=comparison['current_best_url'],
            all_prices=all_prices
        )
        
        if comparison['is_target_reached'] and not alert.notification_sent:
            logger.info(f"🎯 Alert {alert.id} triggered! Target: ₦{alert.target_price:,}, Current: ₦{comparison['current_best_price']:,}")
            
            # Send email notification
            await self._send_price_alert_email(alert, comparison)
            
            # Send push notification using alert_id
            await self._send_push_notification_for_alert(alert.id)
            
            # Mark as triggered
            await self.queries.mark_alert_triggered(alert.id)
            
            return True
        
        return False
    
    async def _send_price_alert_email(self, alert, comparison):
        """Send email notification for triggered price alert"""
        try:
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
            logger.info(f"📧 Price alert email sent to {alert.email} for alert {alert.id}")
        except Exception as e:
            logger.error(f"Failed to send price alert email: {e}")
    
    async def _send_push_notification_for_alert(self, alert_id: int):
        """Send push notification for a triggered price alert using alert_id as task_id"""
        try:
            from core.store.queries.device_queries import DeviceQueries
            from core.notification.notification_handler import notification_service
            
            # Get alert details first
            alert = await self.queries.get_alert_by_id(alert_id)
            if not alert:
                logger.warning(f"Alert {alert_id} not found")
                return
            
            device_queries = DeviceQueries(self.db)
            # Look up device by task_id (which is the alert_id)
            device = await device_queries.get_task_by_id(str(alert_id))
            
            if not device or not device.fcm_token:
                logger.warning(f"No device found for alert_id/task_id: {alert_id}")
                return
            
            savings = alert.target_price - alert.current_best_price if alert.current_best_price else 0
            savings_percentage = (savings / alert.target_price) * 100 if alert.target_price > 0 else 0
            
            title = "🎯 Price Alert Triggered!"
            body = f"{alert.product_name} is now ₦{alert.current_best_price:,.0f} on {alert.current_best_platform}!"
            
            if savings > 0:
                body += f" Save ₦{savings:,.0f} ({savings_percentage:.0f}% off)!"
            
            result = notification_service.send_notification(
                token=device.fcm_token,
                title=title,
                body=body,
                data={
                    "type": "price_alert_triggered",
                    "alert_id": str(alert_id),
                    "product_name": alert.product_name,
                    "target_price": str(alert.target_price),
                    "current_price": str(alert.current_best_price) if alert.current_best_price else "",
                    "platform": alert.current_best_platform or "",
                    "url": alert.current_best_url or "",
                    "savings": str(savings),
                    "savings_percentage": str(savings_percentage),
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                    "screen": "price_tracking"
                }
            )
            logger.info(f"📱 Push notification sent for alert {alert_id} to device")
                        
        except Exception as e:
            logger.error(f"Failed to send push notification for alert {alert_id}: {e}")
    
    async def _publish_alert_update(self, alert, triggered: bool):
        """Publish alert update to Redis for WebSocket broadcasting"""
        try:
            redis_client = await get_redis()
            
            update_data = {
                "type": "alert_update",
                "alert_id": alert.id,
                "product_name": alert.product_name,
                "target_price": alert.target_price,
                "current_best_price": alert.current_best_price,
                "current_best_platform": alert.current_best_platform,
                "current_best_url": alert.current_best_url,
                "target_reached": triggered,
                "status": alert.status,
                "next_check_at": alert.next_check_at.isoformat() if alert.next_check_at else None,
                "timestamp": datetime.now().isoformat()
            }
            
            await redis_client.publish(
                f"price_alerts:{alert.email}",
                json.dumps(update_data)
            )
            logger.info(f"📡 Published alert update for {alert.email} (alert {alert.id}, triggered={triggered})")
            
        except Exception as e:
            logger.error(f"Failed to publish alert update: {e}")
    
    async def create_alert(self, email: str, product_name: str, target_price: float):
        """Create a new price alert"""
        from core.schemas.price_tracking_schemas import CreatePriceAlertSchema
        
        existing_alert = await self.queries.get_active_alert_by_product(email, product_name)
        
        if existing_alert:
            logger.warning(f"Active alert already exists for {product_name} (ID: {existing_alert.id})")
            raise HTTPException(
                status_code=400, 
                detail=f"You already have an active price alert for '{product_name}'."
            )
        
        alert_data = CreatePriceAlertSchema(
            email=email,
            product_name=product_name,
            target_price=target_price
        )
        
        alert = await self.queries.create_alert(alert_data)
        await self.email_service.send_welcome_email(email)
        await self.queries.update_alert_check_schedule(alert.id, hours=0, minutes=0, seconds=5)
        
        try:
            from worker.price_checker_task import check_single_alert_task
            await check_single_alert_task.kiq(alert.id)
            logger.info(f"📤 Queued price check task for alert {alert.id}")
        except Exception as e:
            logger.error(f"Failed to queue task: {e}")
        
        return alert