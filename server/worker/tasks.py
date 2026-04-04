
from datetime import datetime
import json
from taskiq import Context, TaskiqDepends
from typing import Optional, Literal
from core.task_definition import TaskNames, TaskResults
from core.redis import  get_redis, init_redis
from core.utils import get_logger
from .helper import publish_redis_job
from core.schemas import RedisPublishSchemas
from .main import broker

logger = get_logger(__name__)


@broker.task(
    task_name=TaskNames.PIPELINE_TASK,
    retry_backoff=True,
    max_retries=3,
    time_limit=3600,
)
async def pipeline_task_handler(
    query: str,
    mode: Optional[Literal["train_model", "predict"]] = "predict",
    pages: int = 1,
    context: Context = TaskiqDepends(),
):
    task_id = context.message.task_id
    redis_client = await get_redis()

    if redis_client is None:  
        await init_redis()
        redis_client = await get_redis()



    try:
        logger.info(f"Task {task_id} started for query: {query}")
        await publish_redis_job(redis_client, RedisPublishSchemas(
            progress=0,
            task_id=task_id,
            
            # job_id=task_id,
            status=TaskResults.STARTED,
            mode=mode,
            result=None,
            message=f"Processing query: {query}"
        ))


        from worker.pipelines import run_full_pipeline

        result = await run_full_pipeline(
            task_id= task_id,
            query=query,
            mode=mode,
            pages=pages if mode == "train_model" else 1
        )
        await publish_redis_job(redis_client, RedisPublishSchemas(
            task_id=task_id,
            status=TaskResults.COMPLETED.value,
            mode=mode,
            result=result,
            progress=100,
            message="Your recommendation is complete"
        ))
        
        return result

    except Exception as e:
        await redis_client.publish(
            f"jobs:{task_id}",
            json.dumps({
                "job_id": task_id,
                "status": TaskResults.FAILED,
                "error": str(e),
            })
        )
        raise
    
    
    
# taskiq worker worker.main:broker --workers 8 --log-level INFO