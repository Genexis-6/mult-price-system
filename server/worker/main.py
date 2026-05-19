from taskiq import TaskiqScheduler, TaskiqState
from taskiq_redis import RedisAsyncResultBackend, ListQueueBroker  # Use ListQueueBroker instead of StreamBroker
from core.config import settings
from core.redis import close_redis, get_redis, init_redis
from taskiq.schedule_sources import LabelScheduleSource
from core.utils import get_logger

logger = get_logger(__name__)

# Use ListQueueBroker instead of RedisStreamBroker for better compatibility
broker = ListQueueBroker(url=settings.REDIS_BROKER_URL)

# Result backend
result_backend = RedisAsyncResultBackend(
    redis_url=settings.REDIS_BACKEND_URL,
    keep_results=True,
    result_ex_time=172800
)

broker = broker.with_result_backend(result_backend)

# Create scheduler properly
scheduler = TaskiqScheduler(
    broker=broker,
    sources=[LabelScheduleSource(broker)]
)

async def startup(state: TaskiqState):
    logger.info("TaskIQ worker starting...")
    await init_redis()
    redis_client = await get_redis()
    await redis_client.ping()
    logger.info("TaskIQ worker ready")

async def shutdown(state: TaskiqState):
    logger.info("TaskIQ worker shutting down...")
    await close_redis()

broker.add_event_handler("startup", startup)
broker.add_event_handler("shutdown", shutdown)

# Import tasks
from worker.price_checker_task import *  # noqa
from worker.tasks import *  # noqa

# Export both
__all__ = ["broker", "scheduler"]