import redis.asyncio
from core.schemas import RedisPublishSchemas

async def publish_redis_job(redis: redis.asyncio.Redis, job:RedisPublishSchemas):
    if redis is None:
        return None
    
    return await redis.publish(
        f"jobs:{job.job_id}", job.model_dump()
    )
    