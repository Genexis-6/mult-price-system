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



