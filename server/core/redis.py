from typing import Optional

from redis.asyncio import from_url, Redis
from core.config import settings
from core.utils import get_logger


logger = get_logger(__name__)


redis: Redis | None = None


async def init_redis():
    global redis
    redis = from_url(settings.REDIS_BROKER_URL, decode_responses=True)
    await redis.ping()
    logger.info("starting redis session")
    


async def close_redis():
    global redis
    if redis:
        await redis.close()
        logger.info("ending redis session")
        
        


async def get_redis():
    return redis



async def get_r_task_status(redis, task_id: str) -> Optional[str]:
    """
    Returns:
        - status string if task exists
        - None if task does not exist
    """
    if redis is None:
        return None
        
    exists = await redis.get(f"task:{task_id}:exists")
    if not exists:
        return None
        
    status = await redis.get(f"task:{task_id}:status")
    if status is None:
        return "UNKNOWN"
    
    # In async Redis client, values are already strings
    return status