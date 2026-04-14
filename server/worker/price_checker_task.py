from datetime import datetime
from taskiq import Context, TaskiqDepends
from core.store import db_session_manager
from core.service import PriceTrackingService
from core.utils.logger import get_logger
from .main import broker
from core.redis import get_redis, init_redis
import json

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
            
            logger.info(f"✅ Alert {alert_id} check completed. Target reached: {result}")
            return {"alert_id": alert_id, "triggered": result}
    
    return None