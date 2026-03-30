from celery import Celery
from celery.result import AsyncResult
from core.config import settings
from core.store import getdb, AsyncSession
from fastapi import Depends
from typing import Annotated
from core.redis import get_redis, Redis


db_injection = Annotated[AsyncSession, Depends(getdb)]


celery = Celery(
    "client",
    broker=settings.REDIS_BROKER_URL,
    backend=settings.REDIS_BACKEND_URL
)


redis_injection = Annotated[Redis, Depends(get_redis)]