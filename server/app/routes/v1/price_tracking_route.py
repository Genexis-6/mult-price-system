from fastapi import APIRouter, HTTPException
from core.store.queries.price_tracking_queries import PriceTrackingQueries
from core.service import PriceTrackingService
from core.schemas.price_tracking_schemas import CreatePriceAlertSchema, UpdatePriceAlertSchema
from app.helpers import db_injection
from core.utils.logger import get_logger
from core.store import db_session_manager

from fastapi import WebSocket, WebSocketDisconnect
from app.websocket.manager import manager

logger = get_logger(__name__)

price_tracking = APIRouter(prefix="/price-tracking", tags=["price-tracking"])

@price_tracking.post("/alert", operation_id="create_price_alert")
async def create_price_alert(alert_data: CreatePriceAlertSchema, db: db_injection):
    """Create a new price alert"""
    try:
        service = PriceTrackingService(db)
        alert = await service.create_alert(
            email=alert_data.email,
            product_name=alert_data.product_name,
            target_price=alert_data.target_price
        )
        
        return {
            "success": True,
            "message": "Price alert created successfully",
            "data": {
                "alert_id": alert.id,
                "product_name": alert.product_name,
                "target_price": alert.target_price
            }
        }
    except Exception as e:
        logger.error(f"Failed to create alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
    
@price_tracking.get("/alerts/{email}", operation_id="get_user_alerts")
async def get_user_alerts(email: str, db: db_injection):
    """Get all alerts for a user"""
    try:
        queries = PriceTrackingQueries(db)
        alerts = await queries.get_alerts_by_email(email)
        
        return {
            "success": True,
            "data": [
                {
                    "id": a.id,
                    "product_name": a.product_name,
                    "target_price": a.target_price,
                    "current_best_price": a.current_best_price,
                    "current_best_platform": a.current_best_platform,
                    "current_best_url": a.current_best_url,  # IMPORTANT: Include URL
                    "status": a.status.value if hasattr(a.status, 'value') else a.status,
                    "created_at": a.created_at.isoformat()
                }
                for a in alerts
            ]
        }
    except Exception as e:
        logger.error(f"Failed to get alerts: {e}")
        raise HTTPException(status_code=500, detail=str(e))
@price_tracking.delete("/alert/{alert_id}", operation_id="cancel_alert")
async def cancel_alert(alert_id: int, db: db_injection):
    """Cancel a price alert"""
    try:
        queries = PriceTrackingQueries(db)
        result = await queries.cancel_alert(alert_id)
        
        if result:
            return {"success": True, "message": "Alert cancelled"}
        raise HTTPException(status_code=404, detail="Alert not found")
    except Exception as e:
        logger.error(f"Failed to cancel alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
    
    

@price_tracking.post("/check-alerts", operation_id="trigger_alert_check")
async def manually_check_alerts():
    """Manually trigger price check for all alerts (for testing)"""
    try:
        from worker.price_checker_task import check_all_price_alerts
        
        task = await check_all_price_alerts.kiq()
        
        return {
            "success": True,
            "message": "Price check task queued",
            "task_id": task.task_id
        }
    except Exception as e:
        logger.error(f"Failed to queue price check: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@price_tracking.post("/check-alert/{alert_id}", operation_id="trigger_single_alert_check")
async def manually_check_single_alert(alert_id: int):
    """Manually check a single price alert"""
    try:
        from worker.price_checker_task import check_single_alert_task
        
        task = await check_single_alert_task.kiq(alert_id)
        
        return {
            "success": True,
            "message": f"Price check queued for alert {alert_id}",
            "task_id": task.task_id
        }
    except Exception as e:
        logger.error(f"Failed to queue single alert check: {e}")
        raise HTTPException(status_code=500, detail=str(e))

    
@price_tracking.websocket("/ws/{email}")
async def price_tracking_websocket(websocket: WebSocket, email: str):
    """WebSocket endpoint for real-time price tracking updates"""
    await manager.connect(websocket, email, channel_type="price_alerts")
    
    try:
        async with db_session_manager.session() as session:
            queries = PriceTrackingQueries(session)
            alerts = await queries.get_alerts_by_email(email)
            
            initial_data = {
                "type": "initial_status",
                "alerts": [
                    {
                        "id": a.id,
                        "product_name": a.product_name,
                        "target_price": a.target_price,
                        "current_best_price": a.current_best_price,
                        "current_best_platform": a.current_best_platform,
                        "current_best_url": a.current_best_url,  # ADD THIS LINE
                        "status": a.status.value if hasattr(a.status, 'value') else a.status,
                        "next_check_at": a.next_check_at.isoformat() if a.next_check_at else None
                    }
                    for a in alerts
                ]
            }
            await websocket.send_json(initial_data)
        
        while True:
            data = await websocket.receive_text()
            
            if data == "ping":
                await websocket.send_text("pong")
            elif data == "refresh":
                async with db_session_manager.session() as session:
                    queries = PriceTrackingQueries(session)
                    alerts = await queries.get_alerts_by_email(email)
                    
                    refresh_data = {
                        "type": "refresh",
                        "alerts": [
                            {
                                "id": a.id,
                                "product_name": a.product_name,
                                "target_price": a.target_price,
                                "current_best_price": a.current_best_price,
                                "current_best_platform": a.current_best_platform,
                                "current_best_url": a.current_best_url,  # ADD THIS LINE
                                "status": a.status.value if hasattr(a.status, 'value') else a.status
                            }
                            for a in alerts
                        ]
                    }
                    await websocket.send_json(refresh_data)
                    
    except WebSocketDisconnect:
        manager.disconnect(email)
    except Exception as e:
        logger.error(f"WebSocket error for {email}: {e}")
        manager.disconnect(email)
        
             

@price_tracking.patch("/alert/{alert_id}", operation_id="update_price_alert")
async def update_price_alert(
    alert_id: int, 
    alert_data: UpdatePriceAlertSchema, 
    db: db_injection
):
    """Update a price alert's target price"""
    try:
        queries = PriceTrackingQueries(db)
        alert = await queries.get_alert_by_id(alert_id)
        
        if not alert:
            raise HTTPException(status_code=404, detail="Alert not found")
        
        # Update target price
        if alert_data.target_price is not None:
            alert.target_price = alert_data.target_price
        
        # Update status if provided
        if alert_data.status is not None:
            alert.status = alert_data.status.value if hasattr(alert_data.status, 'value') else alert_data.status
        
        await db.commit()
        await db.refresh(alert)
        
        # Trigger a price check for the updated alert
        from worker.price_checker_task import check_single_alert_task
        task = await check_single_alert_task.kiq(alert_id)
        
        return {
            "success": True,
            "message": "Price alert updated successfully",
            "data": {
                "alert_id": alert.id,
                "product_name": alert.product_name,
                "target_price": alert.target_price,
                "status": alert.status,
                "task_id": task.task_id
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))