# import asyncio
# from datetime import datetime

# from asgiref.sync import async_to_sync

# import redis
# from .main import celery
# from typing import Literal, Optional
# from worker.pipelines import run_full_pipeline
# from celery import Task
# import json
# from .main import settings

# from core.utils import get_logger


# logger = get_logger(__name__)


# class RedisPublishTask(Task):
#     """Custom task that publishes progress updates to Redis"""
    
#     _redis_client = None
    
#     @property
#     def redis_client(self):
#         if not self._redis_client:
#             # Use sync Redis client
#             self._redis_client = redis.Redis(
#                 host=settings.REDIS_HOST, 
#                 port=settings.REDIS_PORT, 
#                 db=0,
#                 decode_responses=True
#             )
#         return self._redis_client
    
#     def publish_update(self, task_id, status, **kwargs):
#         """Publish update to Redis channel"""
#         try:
#             update = {
#                 "job_id": task_id,
#                 "status": status,
#                 "timestamp": datetime.utcnow().isoformat(),
#                 **kwargs
#             }
            
#             # Sync publish - no asyncio needed!
#             self.redis_client.publish(
#                 f"jobs:{task_id}",
#                 json.dumps(update)
#             )
#             logger.debug(f"Published {status} update for {task_id}")
            
#         except Exception as e:
#             logger.error(f"Failed to publish update: {e}")
    
#     def before_start(self, task_id, args, kwargs):
#         """Called before task starts"""
#         self.publish_update(task_id, "started", 
#                            message="Task started", 
#                            args=args)
    
#     def on_success(self, retval, task_id, args, kwargs):
#         """Called on task success"""
#         self.publish_update(task_id, "completed", 
#                            message="Task completed successfully",
#                            result=retval)
    
#     def on_failure(self, exc, task_id, args, kwargs, einfo):
#         """Called on task failure"""
#         self.publish_update(task_id, "failed",
#                            message=str(exc),
#                            error=str(exc))

# @celery.task(base=RedisPublishTask, name="worker.tasks.pipeline_task_handler")
# def pipeline_task_handler(query: str, mode: str = "predict", pages: int = 1):
#     """Run pipeline with fresh event loop"""
    
#     def run_in_new_loop():
#         """Create new event loop for this task"""
#         loop = asyncio.new_event_loop()
#         asyncio.set_event_loop(loop)
#         try:
#             return loop.run_until_complete(
#                 run_full_pipeline(
#                     query=query,
#                     mode=mode,
#                     pages=pages if mode == "train_model" else 1
#                 )
#             )
#         finally:
#             # Clean up
#             pending = asyncio.all_tasks(loop)
#             for task in pending:
#                 task.cancel()
#             loop.run_until_complete(asyncio.gather(*pending, return_exceptions=True))
#             loop.close()
    
#     # Run in a separate thread to avoid event loop conflicts
#     import concurrent.futures
#     with concurrent.futures.ThreadPoolExecutor() as executor:
#         future = executor.submit(run_in_new_loop)
#         return future.result()