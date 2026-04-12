from fastapi import APIRouter, HTTPException
from core.store.queries import DeviceQueries
from core.schemas import StoreDeviceTaskIdSchemas, CustomResponseSchemas, CreateDeviceSchemas, NotificationSchemas,NotificationResponseSchemas
from app.helpers import db_injection
from core.utils.logger import get_logger
from core.notification.notification_handler import notification_service

logger = get_logger(__name__)

device_init = APIRouter(
    prefix="/device",
    tags=["device"],
    responses={
        404: {"description": "Not found"},
        500: {"description": "Server error"}
    }
)

@device_init.post('/register')
async def register_device(db: db_injection, payload: StoreDeviceTaskIdSchemas):
    """Register a device with FCM token (with optional task_id)"""
    logger.info(f"Received device registration request for token: {payload.fcm_token[:10]}...")
    
    try:
        device_query = DeviceQueries(db)
        
        # Validate FCM token
        if not payload.fcm_token or len(payload.fcm_token) < 10:
            logger.warning(f"Invalid FCM token provided: {payload.fcm_token}")
            return CustomResponseSchemas.error_response(
                status_code=400,
                message="Invalid FCM token",
                error_code="INVALID_TOKEN"
            )
        
        # Create or get device
        device = await device_query.create_device(payload.fcm_token)
        
        # If task_id is provided, store it
        if payload.task_id:
            logger.info(f"Storing task {payload.task_id} for device {device.id}")
            await device_query.store_task_id(payload)
        
        logger.info(f"✅ Device registered successfully: ID={device.id}")
        return CustomResponseSchemas.success_response(
            data={
                "device_id": device.id,
                "is_new": device.created_at is not None
            },
            status_code=200,
            message="Device registered successfully"
        )
        
    except Exception as e:
        logger.error(f"❌ Failed to register device: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to register device: {str(e)}"
        )


@device_init.post('/create')
async def create_device_only(db: db_injection, payload: CreateDeviceSchemas):
    """Create/register only the device (no task_id) - Called when app starts"""
    logger.info(f"📱 Creating device registration for token: {payload.fcm_token[:10]}...")
    
    try:
        device_query = DeviceQueries(db)
        
        # Validate FCM token
        if not payload.fcm_token or len(payload.fcm_token) < 10:
            logger.warning(f"❌ Invalid FCM token provided: {payload.fcm_token}")
            return CustomResponseSchemas.error_response(
                status_code=400,
                message="Invalid FCM token",
                error_code="INVALID_TOKEN"
            )
        
        # Create or get device (without storing any task)
        device = await device_query.create_device(payload.fcm_token)
        
        logger.info(f"✅ Device created/retrieved successfully: ID={device.id}")
        return CustomResponseSchemas.success_response(
            data={
                "device_id": device.id,
                "fcm_token": payload.fcm_token[:10] + "...",
                "is_new": device.created_at is not None
            },
            status_code=200,
            message="Device registered successfully"
        )
        
    except Exception as e:
        logger.error(f"❌ Failed to create device: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create device: {str(e)}"
        )


@device_init.post('/device-task')
async def store_device_task(db: db_injection, payload: StoreDeviceTaskIdSchemas):
    """Store a task ID for an existing device"""
    logger.info(f"📝 Storing task {payload.task_id} for device with token: {payload.fcm_token[:10]}...")
    
    try:
        device_query = DeviceQueries(db)
        
        # Validate inputs
        if not payload.fcm_token or len(payload.fcm_token) < 10:
            logger.warning(f"❌ Invalid FCM token provided: {payload.fcm_token}")
            return CustomResponseSchemas.error_response(
                status_code=400,
                message="Invalid FCM token",
                error_code="INVALID_TOKEN"
            )
        
        if not payload.task_id:
            logger.warning("❌ No task_id provided")
            return CustomResponseSchemas.error_response(
                status_code=400,
                message="Task ID is required",
                error_code="TASK_ID_REQUIRED"
            )
        
        # Store the task for the device
        await device_query.store_task_id(payload)
        
        logger.info(f"✅ Task {payload.task_id} stored successfully for device")
        return CustomResponseSchemas.success_response(
            data={
                "task_id": payload.task_id,
                "fcm_token": payload.fcm_token[:10] + "..."
            },
            status_code=200,
            message="Task stored successfully"
        )
        
    except Exception as e:
        logger.error(f"❌ Failed to store task: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to store task: {str(e)}"
        )




@device_init.delete('/task/{task_id}')
async def delete_device_task(db: db_injection, task_id: str):
    """Delete a specific task"""
    logger.info(f"🗑️ Deleting task: {task_id}")
    
    try:
        device_query = DeviceQueries(db)
        result = await device_query.delete_task(task_id)
        
        if result:
            logger.info(f"✅ Task {task_id} deleted successfully")
            return CustomResponseSchemas.success_response(
                data=None,
                status_code=200,
                message="Task deleted successfully"
            )
        else:
            logger.warning(f"⚠️ Task {task_id} not found")
            return CustomResponseSchemas.error_response(
                status_code=404,
                message="Task not found",
                error_code="TASK_NOT_FOUND"
            )
            
    except Exception as e:
        logger.error(f"❌ Failed to delete task: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete task: {str(e)}"
        )




@device_init.post("/notify")
async def send_notification(payload: NotificationSchemas):
    """
    Send a push notification to a device
    """
    logger.info(f"--- Sending notification to device: {payload.fcm_token[:20]}...")
    logger.info(f"--- Title: {payload.title}")
    logger.info(f"---Body: {payload.body}")
    
    try:
        # Send notification using the service
        result = notification_service.send_notification(
            token=payload.fcm_token,
            title=payload.title,
            body=payload.body,
            data=payload.data if payload.data else {}
        )
        
        # Check if there was an error
        if result and "error" in result:
            logger.error(f"---Failed to send notification: {result.get('error')}")
            return NotificationResponseSchemas(
                success=False,
                message=result.get('error', 'Unknown error'),
                data={}
            )
        
        logger.info(f"---Notification sent successfully to {payload.fcm_token[:20]}...")
        
        return NotificationResponseSchemas(
            success=True,
            message="Notification sent successfully",
            data=result if result else {}
        )
        
    except Exception as e:
        logger.error(f"---Failed to send notification: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to send notification: {str(e)}"
        )

