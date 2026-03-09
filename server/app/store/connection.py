
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
import contextlib
from typing_extensions import AsyncIterable
from app.config.dev_config import settings
from app.utils.logger import get_logger

Base = declarative_base()
logger = get_logger("db-connection")

class DbSessionManager:
    def __init__(self, host_url: str):
        self._engin = create_async_engine(
            url=host_url,
            echo=False,)
        
        self._session_maker = async_sessionmaker(
            bind=self._engin,
            autoflush=True, 
            class_=AsyncSession, 
            expire_on_commit=True
        )
        
    

    async def start(self):
        if self._engin is  None:
            logger.debug("error occured while stating session engin")
            return
        try:
            async with self._engin.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            logger.info(f"db connection initialized")
        except Exception as e:
            logger.fatal(f"error occured while starting engine {e}")
        
        
    
 
    async def end(self):
        if self._engin is  None:
            raise RuntimeError("Database engine not initialized")
        self._engin.dispose()
        self._engin = None
        self._session_maker = None
        logger.debug("db session is closed")
        
    
    
    @contextlib.asynccontextmanager
    async def session(self)-> AsyncIterable[AsyncSession]:
        if self._session_maker is  None:
            logger.fatal("no session engin was provided")
            return
        
        conn = self._session_maker()
        try:
            yield conn
            await conn.commit()
            
        except Exception as e:
            logger.debug(f"error occured in session due to: {e}")
            await conn.rollback()
            raise
        finally:
            await conn.close()
        
    
    
    


db_session_manager = DbSessionManager(
    host_url=settings.DATABASE_URL
)