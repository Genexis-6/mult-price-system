from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from core.store import DeviceModel, TaskIdModel
from core.schemas import StoreDeviceTaskIdSchemas
from core.utils.logger import get_logger
from sqlalchemy.orm import selectinload

logger = get_logger(__name__)

class DeviceQueries:
    def __init__(self, db: AsyncSession):
        self.__session = db
        logger.debug("DeviceQueries initialized with database session")
        
    async def check_device_exist(self, fcm_token: str):
        """Check if device exists by FCM token"""
        logger.debug(f"Checking if device exists with FCM token: {fcm_token[:10]}...")
        try:
            result = await self.__session.execute(
                select(DeviceModel).where(DeviceModel.device_fcm == fcm_token)
            )
            device = result.scalar_one_or_none()
            if device:
                logger.debug(f"Device found with ID: {device.id}")
            else:
                logger.debug("Device not found")
            return device
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
            logger.info(f"✅ Device created successfully with ID: {new_device.id}")
            return new_device
        except Exception as e:
            logger.error(f"❌ Failed to create device: {e}")
            await self.__session.rollback()
            raise
    
    async def store_task_id(self, std: StoreDeviceTaskIdSchemas):
        """Store task ID for a device"""
        logger.info(f"Storing task : {std} for device")
        try:
            # Check if device exists - using scalar() instead of scalar_one_or_none()
            device = await self.check_device_exist(std.fcm_token)
            
            if device is None:
                logger.info(f"Device not found, creating new device for FCM token: {std.fcm_token[:10]}...")
                device = await self.create_device(std.fcm_token)
            
            # Check if task already exists - FIX: Use proper async pattern
        
            result = await self.__session.execute(select(TaskIdModel).where(TaskIdModel.task_id == std.task_id))
            existing_task = result.scalar_one_or_none()
            
            if existing_task:
                logger.warning(f"Task ID {std.task_id} already exists, skipping")
                return
            
            # Create task record
            # task_record = TaskIdModel(
            #     task_id=std.task_id,
            #     device_id=device.id
            # )
            
            self.__session.add(
                TaskIdModel(
                    task_id=std.task_id,
                    device_id=device.id,
                    # device=device
                )
            )
            await self.__session.commit()
            # self.__session.add(task_record)
            # await self.__session.commit()
            logger.info(f"✅ Task ID {std.task_id} stored successfully for device {device.id}")
            
        except Exception as e:
            logger.error(f"❌ Failed to store task ID: {e}")
            await self.__session.rollback()
            raise
    


    async def get_task_by_id(self, task_id: str):
        logger.debug(f"Fetching task with ID: {task_id}")
        try:
            stmt = (
                select(TaskIdModel)
                .options(selectinload(TaskIdModel.device))  # ✅ IMPORTANT
                .where(TaskIdModel.task_id == task_id)
            )

            result = await self.__session.execute(stmt)
            task = result.scalar_one_or_none()

            if task is None:
                logger.warning(f"Task {task_id} not found")
                return None

            return StoreDeviceTaskIdSchemas(
                task_id=task.task_id,
                fcm_token=task.device.device_fcm if task.device else None
            )

        except Exception as e:
            logger.error(f"Error fetching task {task_id}: {e}")
            raise