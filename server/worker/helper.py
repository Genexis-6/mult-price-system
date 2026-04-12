import redis.asyncio
import json
from datetime import datetime
from core.schemas import RedisPublishSchemas
from core.utils.logger import get_logger

logger = get_logger(__name__)

# When publishing progress, also store in Redis keys
async def publish_redis_job(redis_client, job: RedisPublishSchemas):
    if redis_client is None:
        return None
    
    # Store current progress and message in Redis keys for later retrieval
    await redis_client.set(f"task:{job.task_id}:progress", job.progress, ex=3600)
    await redis_client.set(f"task:{job.task_id}:message", job.message, ex=3600)
    await redis_client.set(f"task:{job.task_id}:status", job.status.value if hasattr(job.status, 'value') else str(job.status), ex=3600)
    
    # Publish to channel for real-time updates
    job_dict = job.model_dump(mode="json")
    if 'timestamp' in job_dict and isinstance(job_dict['timestamp'], datetime):
        job_dict['timestamp'] = job_dict['timestamp'].isoformat()
    
    channel = f"jobs:{job.task_id}"
    result = await redis_client.publish(channel, json.dumps(job_dict))
    logger.info(f"📡 Published to {channel}: {job.progress}% - {job.message}")
    return result