from fastapi import FastAPI
import contextlib
from app.store import db_session_manager





@contextlib.asynccontextmanager
async def lifespan(app):
    await db_session_manager.start()
    yield 
    await db_session_manager.start()


app = FastAPI(title="Mula Search Api", lifespan=lifespan)