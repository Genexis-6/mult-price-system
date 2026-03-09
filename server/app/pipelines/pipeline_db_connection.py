# session manager for pipeline
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.config.dev_config import settings

engine = create_engine(
    pool_size=10,          # 3 ETLs run in parallel — give enough connections
    max_overflow=5,
    pool_pre_ping=True,    # drop stale connections automatically
    url=settings.DATABASE_URL
)
session_manager = sessionmaker(
    bind=engine, autoflush=True, autocommit=False, 
)


def get_session():
    return session_manager()