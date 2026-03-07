
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
import contextlib
from typing_extensions import AsyncIterable
from app.config.dev_config import settings

BASE = declarative_base()

class DbSessionManager:
    def __init__(self, host_url: str):
        self._engin = create_async_engine(url=host_url)
        self._session_maker = async_sessionmaker(
            bind=self._engin,
            autoflush=True, 
            class_=AsyncSession, 
            expire_on_commit=True
        )
        
    

    async def start(self):
        if self._engin is  None:
            print("error occured while stating session engin")
            return
        
        async with self._engin.begin() as conn:
            await conn.run_sync(BASE.metadata.create_all)
        
    
 
    async def end(self):
        if self._engin is  None:
            raise RuntimeError("Database engine not initialized")
        self._engin.dispose()
        self._engin = None
        self._session_maker = None
        print("db session is closed")
        
    
    
    @contextlib.asynccontextmanager
    async def session(self)-> AsyncIterable[AsyncSession]:
        if self._session_maker is  None:
            print("no session engin was provided")
            return
        
        conn = self._session_maker()
        try:
            yield conn
        except Exception as e:
            print(f"error occured in session due to: {e}")
            await conn.rollback()
            raise
        finally:
            await conn.close()
        
    
    
    


db_session_manager = DbSessionManager(
    host_url=settings.DATABASE_URL
)