from celery import Celery
from core.config import settings



celery = Celery(
    "worker", 
    backend=settings.REDIS_BACKEND_URL, 
    broker=settings.REDIS_BROKER_URL
)

celery.autodiscover_tasks(["worker.tasks"])