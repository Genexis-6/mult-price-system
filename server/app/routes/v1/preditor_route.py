# app/routes/v1/preditor_route.py
from datetime import datetime
import uuid
import json
from core.notification.notification_handler import send_push, notification_service

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException

from core.schemas import PredictQerySchemas, CustomResponseSchemas
from app.helpers import redis_injection
from core.task_definition import TaskNames, TaskResults
from core.utils import get_logger
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




@pred.get("/test-notification")
async def test_notification():
    """Test endpoint for push notifications"""
    try:
        # Get a valid FCM token from your database or request
        test_token = "fdgiAUhATrK-SiPOpzVQwv:APA91bEc_9Rv8pYB5YQvKZyk4k34BRA3wP3c5ngh4fcb4yqbIrS-Tzk3YiirUGFQAvwtP5eKRfoTsoTXadAqCXDtrpFlJxHtHeac3nwEi_rw6SWPFRAonmU"
        
        result = notification_service.send_notification(
            token=test_token,
            title="Test Notification",
            body="This is a test message from the server!",
            data={"type": "test", "timestamp": "now"}
        )
        
        if "error" not in result:
            return CustomResponseSchemas.success_response(
                data=result,
                message="Push notification sent successfully",
                status_code=200
            )
        else:
            return CustomResponseSchemas.error_response(
                message=f"Failed to send notification: {result.get('error', 'Unknown error')}",
                status_code=500
            )
    except Exception as e:
        logger.error(f"Error in test notification: {e}")
        return CustomResponseSchemas.error_response(
            message=str(e),
            status_code=500
        )



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
async def get_task_status(job_id: str):
    try:
        from worker.main import result_backend  # wherever you defined it
        
        result = await result_backend.get_result(job_id)
        
        # logger.debug(result)

        if result is None:
            raise HTTPException(status_code=404, detail="Task not found")

        return CustomResponseSchemas.success_response(
            data={
                "job_id": job_id,
                # "status": result.status.name,  # e.g. PENDING, SUCCESS, FAILED
                "result": result.return_value if not result.is_err else None
            },
            message="Task status retrieved",
            status_code=200
        )

    except Exception as e:
        logger.error(f"Error checking task status: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    

@pred.websocket("/ws/{job_id}")
async def websocket_endpoint(websocket: WebSocket, job_id: str):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(websocket, job_id)
    
    try:
        while True:
            data = await websocket.receive_text()
            logger.debug(f"Received from {job_id}: {data}")
            
            if data == "ping":
                await websocket.send_text("pong")
            
    except WebSocketDisconnect:
        manager.disconnect(job_id)
    except Exception as e:
        logger.error(f"WebSocket error for {job_id}: {e}")
        manager.disconnect(job_id)    
        
        

# taskiq worker worker.main:broker --workers 8 --log-level INFO 