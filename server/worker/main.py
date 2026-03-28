from celery import Celery
from core.config import settings



celery = Celery(
    "worker", 
    backend=settings.REDIS_URL, 
    broker=settings.REDIS_URL
)

celery.autodiscover_tasks(["tasks"])