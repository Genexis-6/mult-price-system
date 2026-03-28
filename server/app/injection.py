from core.store import getdb, AsyncSession
from fastapi import Depends
from typing import Annotated



db_injection = Annotated[AsyncSession, Depends(getdb)]


