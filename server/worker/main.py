from taskiq import TaskiqState
from taskiq_redis import RedisAsyncResultBackend, RedisStreamBroker
from core.config import settings
from core.redis import close_redis, get_redis, init_redis
from core.utils import get_logger
from core.task_definition import TaskNames


logger = get_logger(__name__)

broker = RedisStreamBroker(
    url=settings.REDIS_BROKER_URL,
  
)

# Result backend
result_backend = RedisAsyncResultBackend(
    redis_url=settings.REDIS_BACKEND_URL,
    keep_results=True,
    result_ex_time= 172800
)


broker = broker.with_result_backend(result_backend)



async def startup(state: TaskiqState):
    logger.info("TaskIQ worker starting...")

    await init_redis()
    redis_client = await get_redis()
    redis_client.ping()

    logger.info("TaskIQ worker ready")


async def shutdown(state: TaskiqState):
    logger.info("TaskIQ worker shutting down...")
    await close_redis()


broker.add_event_handler("startup", startup)
broker.add_event_handler("shutdown", shutdown)
from worker.tasks import *
from worker.price_checker_task import *
