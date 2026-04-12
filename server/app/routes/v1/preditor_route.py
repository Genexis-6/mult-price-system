# app/routes/v1/preditor_route.py
import asyncio
from datetime import datetime
import uuid
import json
from core.notification.notification_handler import send_push, notification_service

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException

from core.schemas import PredictQerySchemas, CustomResponseSchemas
from app.helpers import redis_injection, db_injection
from core.redis import get_r_task_status
from core.task_definition import TaskNames, TaskResults
from core.utils import get_logger
from core.store.queries import DeviceQueries
from app.websocket.manager import manager
from worker.tasks import pipeline_task_handler

logger = get_logger(__name__)

pred = APIRouter(tags=["predict"], prefix="/predict", 
                 responses={
        404: {
            "message":"not found"
        },
        500:{
            "message":"server error"
        }
    })




# @pred.get("/test-notification")
# async def test_notification():
#     """Test endpoint for push notifications"""
#     try:
#         # Get a valid FCM token from your database or request
#         test_token = "fdgiAUhATrK-SiPOpzVQwv:APA91bEc_9Rv8pYB5YQvKZyk4k34BRA3wP3c5ngh4fcb4yqbIrS-Tzk3YiirUGFQAvwtP5eKRfoTsoTXadAqCXDtrpFlJxHtHeac3nwEi_rw6SWPFRAonmU"
        
#         result = notification_service.send_notification(
#             token=test_token,
#             title="Test Notification",
#             body="This is a test message from the server!",
#             data={"type": "test", "timestamp": "now"}
#         )
        
#         if "error" not in result:
#             return CustomResponseSchemas.success_response(
#                 data=result,
#                 message="Push notification sent successfully",
#                 status_code=200
#             )
#         else:
#             return CustomResponseSchemas.error_response(
#                 message=f"Failed to send notification: {result.get('error', 'Unknown error')}",
#                 status_code=500
#             )
#     except Exception as e:
#         logger.error(f"Error in test notification: {e}")
#         return CustomResponseSchemas.error_response(
#             message=str(e),
#             status_code=500
#         )



@pred.post("/")
async def predict_product(q: PredictQerySchemas):
    try:
        task = await pipeline_task_handler.kiq(
            q.query,
            "predict",
            1,
        )
        job_id = task.task_id
        return CustomResponseSchemas.success_response(
           data={
            "job_id": job_id,
            "status": "pending",
        }, 
           message="Task submitted successfully",
           status_code=200
             
        )

    except Exception as e:
        logger.error(f"Error starting task: {e}")
        raise CustomResponseSchemas.error_response(status_code=500, message=str(e), data=None)
   
   
@pred.get("/status/{job_id}")
async def get_task_status(job_id: str, redis: redis_injection):
    try:
        # First check Redis for task status
        task_exists = await redis.get(f"task:{job_id}:exists")
        
        if not task_exists:
            logger.warning(f"Task {job_id} not found")
            return CustomResponseSchemas.error_response(
                status_code=404,
                message="Task not found",
                error_code="TASK_NOT_FOUND"
            )
        
        # Get task status from Redis (no decode needed)
        status = await redis.get(f"task:{job_id}:status") or "UNKNOWN"
        
        # Get task result if completed
        result_data = None
        if status in ["SUCCESS", "COMPLETED"]:
            result_data = await redis.get(f"task:{job_id}:result")
            if result_data:
                result_data = json.loads(result_data)
        
        # Get error if failed
        error_msg = None
        if status == "FAILED":
            error_msg = await redis.get(f"task:{job_id}:error")
        
        return CustomResponseSchemas.success_response(
            data={
                "job_id": job_id,
                "status": status,
                "result": result_data,
                "error": error_msg,
                "exists": True
            },
            message=f"Task status: {status}",
            status_code=200
        )
        
    except Exception as e:
        logger.error(f"Error checking task status: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
    
    
    
@pred.websocket("/ws/{job_id}")
async def websocket_endpoint(websocket: WebSocket, job_id: str, redis: redis_injection):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(websocket, job_id)
    
    try:
        # Send the last known task status immediately on connection
        task_exists = await redis.get(f"task:{job_id}:exists")
        if task_exists:
            # Redis returns string directly in async mode, no need to decode
            status_str = await redis.get(f"task:{job_id}:status") or "UNKNOWN"
            
            progress_val = await redis.get(f"task:{job_id}:progress")
            progress_val = int(progress_val) if progress_val else 0
            
            message_str = await redis.get(f"task:{job_id}:message") or "Processing..."
            
            result = None
            if status_str in ["SUCCESS", "COMPLETED"]:
                result_data = await redis.get(f"task:{job_id}:result")
                if result_data:
                    result = json.loads(result_data)
            
            current_status = {
                "task_id": job_id,
                "status": status_str,
                "progress": progress_val,
                "message": message_str,
                "result": result,
                "timestamp": datetime.now().isoformat()
            }
            await websocket.send_text(json.dumps(current_status))
            logger.info(f"📤 Sent current task status to {job_id}: {status_str} ({progress_val}%)")
        
        while True:
            data = await asyncio.wait_for(websocket.receive_text(), timeout=60.0)
            logger.debug(f"Received from {job_id}: {data}")
            
            if data == "ping":
                await websocket.send_text("pong")
            
            task_exists = await redis.get(f"task:{job_id}:exists")
            if not task_exists:
                logger.info(f"Task {job_id} no longer exists, disconnecting")
                break
            
            task_status = await redis.get(f"task:{job_id}:status")
            if task_status and task_status in ["SUCCESS", "COMPLETED", "FAILED"]:
                logger.info(f"Task {job_id} is {task_status}, disconnecting")
                break
                    
    except asyncio.TimeoutError:
        logger.info(f"WebSocket heartbeat timeout for {job_id}, disconnecting")
    except WebSocketDisconnect:
        logger.info(f"WebSocket client disconnected for {job_id}")
    except Exception as e:
        logger.error(f"WebSocket error for {job_id}: {e}")
    finally:
        manager.disconnect(job_id)
        
# taskiq worker worker.main:broker --workers 8 --log-level INFO 