import redis.asyncio
import json
from core.schemas import RedisPublishSchemas

async def publish_redis_job(redis: redis.asyncio.Redis, job:RedisPublishSchemas):
    if redis is None:
        return None
    
    return await redis.publish(
        f"jobs:{job.task_id}",json.dumps(job.model_dump(mode="json"))
    )
    