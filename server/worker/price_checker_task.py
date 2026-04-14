from datetime import datetime
from taskiq import Context, TaskiqDepends
from core.store import db_session_manager
from core.service import PriceTrackingService
from core.utils.logger import get_logger
from .main import broker
from core.redis import get_redis, init_redis
import json
from core.store import db_session_manager
from core.store.queries.price_tracking_queries import PriceTrackingQueries
from core.notification.notification_handler import notification_service
from core.utils.logger import get_logger


logger = get_logger(__name__)

# Run every 24 hours at midnight
@broker.task(
    schedule=[{"time": 120}],  # Run at midnight every day
    time_limit=7200  # 2 hours max execution time
)
async def check_all_price_alerts(context: Context = TaskiqDepends()):
    """Scheduled task to check all price alerts (every 24 hours)"""
    logger.info("🕐 Running scheduled 24-hour price check for all alerts")
    
    async with db_session_manager.session() as session:
        service = PriceTrackingService(session)
        results = await service.check_all_alerts()
        
        triggered = len([r for r in results if r])
        logger.info(f"✅ 24-hour price check completed: {triggered} alerts triggered")
        
        return {"triggered": triggered, "total": len(results)}
    
    
    
@broker.task
async def check_single_alert_task(alert_id: int):
    """Task to check a single price alert and publish updates via Redis"""
    logger.info(f"🔍 Starting immediate price check for alert: {alert_id}")
    
    redis_client = await get_redis()
    if redis_client is None:
        await init_redis()
        redis_client = await get_redis()
    
    async with db_session_manager.session() as session:
        service = PriceTrackingService(session)
        alert = await service.queries.get_alert_by_id(alert_id)
        
        if alert:
            result = await service._check_single_alert(alert)
            
            if redis_client:
                await redis_client.publish(
                    f"price_alerts:{alert.email}",
                    json.dumps({
                        "type": "alert_update",
                        "alert_id": alert.id,
                        "product_name": alert.product_name,
                        "target_price": alert.target_price,
                        "current_best_price": alert.current_best_price,
                        "current_best_platform": alert.current_best_platform,
                        "current_best_url": alert.current_best_url,  # ADD THIS LINE
                        "target_reached": result,
                        "timestamp": datetime.now().isoformat()
                    })
                )
                logger.info(f"📡 Published update for alert {alert_id}")
                
            
            await send_price_alert_push_notification(alert_id)
            
            logger.info(f"✅ Alert {alert_id} check completed. Target reached: {result}")
            return {"alert_id": alert_id, "triggered": result}
    
    return None







async def send_price_alert_push_notification(alert_id: int):
    """Send push notification when a price alert is triggered using alert_id as task_id"""
    try:
        async with db_session_manager.session() as session:
            # Get the alert details
            alert_queries = PriceTrackingQueries(session)
            alert = await alert_queries.get_alert_by_id(alert_id)
            
            if not alert:
                logger.warning(f"Alert {alert_id} not found")
                return
            
            # Get device by task_id (which is the alert_id)
            from core.store.queries.device_queries import DeviceQueries
            device_queries = DeviceQueries(session)
            device = await device_queries.get_task_by_id(str(alert_id))
            
            if not device or not device.fcm_token:
                logger.warning(f"No device found for alert_id/task_id: {alert_id}")
                return
            
            # Calculate savings
            savings = alert.target_price - alert.current_best_price if alert.current_best_price else 0
            savings_percentage = (savings / alert.target_price) * 100 if alert.target_price > 0 else 0
            
            # Send notification
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
                    "savings_percentage": f"{savings_percentage:.0f}",
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                    "screen": "price_tracking"
                }
            )
            logger.info(f"📱 Push notification sent for alert {alert_id}")
            
    except Exception as e:
        logger.error(f"Failed to send price alert push notification for alert {alert_id}: {e}")