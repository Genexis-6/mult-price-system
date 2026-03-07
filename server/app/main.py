from fastapi import FastAPI
import contextlib
from app.store import db_session_manager
from app.utils.logger import get_logger
from app.routes.test import test

logger = get_logger("app")


@contextlib.asynccontextmanager
async def lifespan(app):
    logger.debug("app starting.....")
    await db_session_manager.start()
    yield 
    await db_session_manager.start()
    logger.debug("app shuting down.....")
    


app = FastAPI(title="Mula Search Api", lifespan=lifespan)


app.include_router(test)