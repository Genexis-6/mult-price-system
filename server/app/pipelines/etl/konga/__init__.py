from typing import Any, Dict, List

from ..base_etl import BaseETL
from .extractor import extract_konga
from .loader import load_konga
from .transformer import transform_konga


class KongaETL(BaseETL):
    def __init__(self):
        super().__init__("konga")
    
    async def extract(self, query: str, pages: int = 3) -> List[Dict[str, Any]]:
        return await extract_konga(query=query, pages=pages,log=self.logger)

    def transform(self, raw_data: List[Dict[str, Any]], query: str) -> List[Dict[str, Any]]:
        return transform_konga(raw_data, query)

    async def load(self, products: List[Dict[str, Any]]) -> int:
        return await load_konga(products)