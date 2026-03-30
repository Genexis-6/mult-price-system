from fastapi import FastAPI
import contextlib
from core.store import db_session_manager
from core.utils import get_logger
from core.redis import init_redis, close_redis
from .routes.v1 import v1
from fastapi.middleware.cors import CORSMiddleware
logger = get_logger("app")


@contextlib.asynccontextmanager
async def lifespan(app):
    logger.debug("app starting.....")
    await db_session_manager.start()
    await init_redis()
    yield 
    await db_session_manager.start()
    await close_redis()
    logger.debug("app shuting down.....")
    


app = FastAPI(title="Mula Search Api", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(v1)