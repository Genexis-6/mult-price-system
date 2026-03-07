from .connection import db_session_manager, AsyncSession
from fastapi import Depends
from typing import Annotated



async def getdb():
    async with db_session_manager.session() as session:
        yield session
        
        
    
db_injection = Annotated[AsyncSession, Depends(getdb)]