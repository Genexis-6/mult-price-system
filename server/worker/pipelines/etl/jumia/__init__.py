from ..base_etl import BaseETL
from .extractor import extract_jumia
from .loader import load_jumia
from .transformer import transform_jumia
from typing import List, Dict, Any


class JumiaETL(BaseETL):
    def __init__(self):
        super().__init__("jumia")

    async def extract(self, query: str, pages: int = 3) -> List[Dict[str, Any]]:
        return await extract_jumia(query, pages)

    def transform(self, raw_data: List[Dict[str, Any]], query: str) -> List[Dict[str, Any]]:
        return transform_jumia(raw_data, query)

    async def load(self, products: List[Dict[str, Any]]) -> int:
        return await load_jumia(products)
