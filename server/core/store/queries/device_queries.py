from sqlalchemy import select
from core.store import DeviceModel, TaskIdModel
from ..connection import AsyncSession
from core.schemas import StoreDeviceTaskIdSchemas
from core.utils.logger import get_logger

logger = get_logger(__name__)

class DeviceQueries:
    def __init__(self, db: AsyncSession):
        self.__session = db
        logger.debug("DeviceQueries initialized with database session")
        
    async def check_device_exist(self, fcm_token: str):
        """Check if device exists by FCM token"""
        logger.debug(f"Checking if device exists with FCM token: {fcm_token[:10]}...")
        try:
            res = await self.__session.execute(
                select(DeviceModel).where(DeviceModel.device_fcm == fcm_token)
            )
            output = res.scalar_one_or_none()
            if output:
                logger.debug(f"Device found with ID: {output.id}")
            else:
                logger.debug("Device not found")
            return output
        except Exception as e:
            logger.error(f"Error checking device existence: {e}")
            raise
    
    async def create_device(self, fcm_token: str):
        """Create a new device record"""
        logger.info(f"Creating new device with FCM token: {fcm_token[:10]}...")
        try:
            # Check if device already exists
            existing_device = await self.check_device_exist(fcm_token)
            if existing_device:
                logger.warning(f"Device with FCM token {fcm_token[:10]}... already exists (ID: {existing_device.id})")
                return existing_device
            
            # Create new device
            new_device = DeviceModel(device_fcm=fcm_token)
            self.__session.add(new_device)
            await self.__session.commit()
            await self.__session.refresh(new_device)
            logger.info(f" Device created successfully with ID: {new_device.id}")
            return new_device
        except Exception as e:
            logger.error(f"Failed to create device: {e}")
            await self.__session.rollback()
            raise
    
    async def get_task_by_id(self, task_id: str):
        """Get task details by task ID"""
        logger.debug(f"Fetching task with ID: {task_id}")
        try:
            res = await self.__session.execute(
                select(TaskIdModel).where(TaskIdModel.task_id == task_id)
            )
            output = res.scalar_one_or_none()
            
            if output is None:
                logger.warning(f"Task {task_id} not found")
                return None
            
            logger.debug(f"Task found: {task_id} for device ID: {output.device_id}")
            return StoreDeviceTaskIdSchemas(
                task_id=output.task_id,
                fcm_token=output.device.device_fcm
            )
        except Exception as e:
            logger.error(f"Error fetching task {task_id}: {e}")
            raise
    
    async def store_task_id(self, std: StoreDeviceTaskIdSchemas):
        """Store task ID for a device"""
        logger.info(f"Storing task ID: {std.task_id} for device")
        try:
            # Check if device exists
            device = await self.check_device_exist(std.fcm_token)
            
            if device is None:
                logger.info(f"Device not found, creating new device for FCM token: {std.fcm_token[:10]}...")
                device = await self.create_device(std.fcm_token)
            
            # Check if task already exists
            existing_task = await self.__session.execute(
                select(TaskIdModel).where(TaskIdModel.task_id == std.task_id)
            )
            if existing_task.scalar_one_or_none():
                logger.warning(f"Task ID {std.task_id} already exists, skipping")
                return
            
            # Create task record
            task_record = TaskIdModel(
                task_id=std.task_id,
                device_id=device.id
            )
            self.__session.add(task_record)
            await self.__session.commit()
            logger.info(f" Task ID {std.task_id} stored successfully for device {device.id}")
        except Exception as e:
            logger.error(f"Failed to store task ID: {e}")
            await self.__session.rollback()
            raise
    
    async def get_device_tasks(self, fcm_token: str):
        """Get all tasks for a device"""
        logger.debug(f"Fetching all tasks for device with token: {fcm_token[:10]}...")
        try:
            device = await self.check_device_exist(fcm_token)
            if device is None:
                logger.warning(f"No device found for token: {fcm_token[:10]}...")
                return []
            
            res = await self.__session.execute(
                select(TaskIdModel).where(TaskIdModel.device_id == device.id)
            )
            tasks = res.scalars().all()
            logger.info(f"Found {len(tasks)} tasks for device {device.id}")
            return tasks
        except Exception as e:
            logger.error(f"Error fetching device tasks: {e}")
            raise
    
    async def delete_task(self, task_id: str):
        """Delete a task record"""
        logger.info(f"Deleting task: {task_id}")
        try:
            res = await self.__session.execute(
                select(TaskIdModel).where(TaskIdModel.task_id == task_id)
            )
            task = res.scalar_one_or_none()
            
            if task is None:
                logger.warning(f"Task {task_id} not found for deletion")
                return False
            
            await self.__session.delete(task)
            await self.__session.commit()
            logger.info(f"✅ Task {task_id} deleted successfully")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to delete task {task_id}: {e}")
            await self.__session.rollback()
            raise