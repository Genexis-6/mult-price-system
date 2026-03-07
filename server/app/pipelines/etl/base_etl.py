from abc import ABC, abstractmethod
from typing import Any, Dict, List
from app.utils.logger import get_logger
from app.config.dev_config import settings


class BaseETL(ABC):
    """
    Abstract base class for all platform ETLs.

    Each subclass must implement:
        - extract(query)   → raw scraped data
        - transform(data)  → cleaned, normalised list of product dicts
        - load(products)   → persist to PostgreSQL
    The run() method connects them together and handles top-level error catching.
    """
    def __init__(self, platform: str):
        super().__init__()
        self.platform = platform
        self.logger= get_logger(platform)
        
    @abstractmethod
    def extract(self, query: str, page: int = settings.PAGE_TO_SCRAPE) -> List[Dict[str, Any]]:
        """
        implement extraction of data from specified platform
        
        """
        ...
    
    
    @abstractmethod
    def tranform(self, query: str, data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Clean, normalise and validate raw dicts.
        Missing fields are set to null
        
        """
        ...
        
    @abstractmethod
    def load(self, products: List[Dict[str, Any]]) -> int:
        """
        Insert transformed products into the platform's PostgreSQL table.
        Returns the number of rows inserted.
        """
        ...

   

    def run(self, query: str, pages: int = 3) -> int:
        """
        Full ETL pipeline: extract → transform → load.
        Returns number of products loaded, or 0 on failure.
        """
        self.logger.info(f"[{self.platform.upper()}] Starting ETL for query='{query}'")
        try:
            raw   = self.extract(query, pages)
            self.logger.info(f"[{self.platform.upper()}] Extracted {len(raw)} raw items")

            clean = self.transform(raw, query)
            self.logger.info(f"[{self.platform.upper()}] Transformed → {len(clean)} products")

            count = self.load(clean)
            self.logger.info(f"[{self.platform.upper()}] Loaded {count} rows into DB")
            return count

        except Exception as e:
            self.logger.error(f"[{self.platform.upper()}] ETL failed: {e}", exc_info=True)
            return 0