import redis.asyncio
import json
from datetime import datetime
from core.schemas import RedisPublishSchemas
from core.utils.logger import get_logger

logger = get_logger(__name__)

async def publish_redis_job(redis: redis.asyncio.Redis, job: RedisPublishSchemas):
    if redis is None:
        logger.error("Redis client is None, cannot publish")
        return None
    
    # Convert to dict with proper datetime serialization
    job_dict = job.model_dump(mode="json")
    
    # Ensure timestamp is ISO format string
    if 'timestamp' in job_dict and isinstance(job_dict['timestamp'], datetime):
        job_dict['timestamp'] = job_dict['timestamp'].isoformat()
    
    channel = f"jobs:{job.task_id}"
    message = json.dumps(job_dict)
    
    logger.info(f"📡 Publishing to Redis channel {channel}: {job.progress}% - {job.message}")
    
    try:
        result = await redis.publish(channel, message)
        logger.info(f"✅ Published to Redis channel {channel}, subscribers: {result}")
        return result
    except Exception as e:
        logger.error(f"Failed to publish to Redis: {e}")
        return None