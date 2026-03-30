from sqlalchemy.ext.asyncio import AsyncSession


class PersistentTaskQueries:
    def __init__(self, db: AsyncSession):
        self.__session = db
        
        
    
    
    async def store_task():
        pass