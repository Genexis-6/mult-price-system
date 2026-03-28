from abc import ABC, abstractmethod
from typing import Any, Dict, List
from core.utils.logger import get_logger
from core.config import settings


class BaseETL(ABC):
    def __init__(self, platform: str):
        super().__init__()
        self.platform = platform
        self.logger = get_logger(platform)

    @abstractmethod
    async def extract(self, query: str, page: int = settings.PAGE_TO_SCRAPE) -> List[Dict[str, Any]]:
        ...

    @abstractmethod
    def transform(self, data: List[Dict[str, Any]], query: str) -> List[Dict[str, Any]]:
        ...

    @abstractmethod
    async def load(self, products: List[Dict[str, Any]]) -> int:
        ...

    async def run(self, query: str, pages: int = 3) -> int: 
        self.logger.info(f"[{self.platform.upper()}] Starting ETL for query='{query}'")
        try:
            raw   = await self.extract(query, pages)
            self.logger.info(f"[{self.platform.upper()}] Extracted {len(raw)} raw items")

            clean = self.transform(raw, query)
            self.logger.info(f"[{self.platform.upper()}] Transformed → {len(clean)} products")

            count = await self.load(clean)    
            self.logger.info(f"[{self.platform.upper()}] Loaded {count} rows into DB")
            return count

        except Exception as e:
            self.logger.error(f"[{self.platform.upper()}] ETL failed: {e}", exc_info=True)
            return 0