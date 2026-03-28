from ..base_etl import BaseETL
from .extractor import extract_jiji
from .loader import load_jiji
from .transformer import transform_jiji
from typing import List, Dict, Any


class JijiETL(BaseETL):
    def __init__(self):
        super().__init__("jiji")

    async def extract(self, query: str, pages: int = 3) -> List[Dict[str, Any]]:
        return await extract_jiji(query, pages)

    def transform(self, raw_data: List[Dict[str, Any]], query: str) -> List[Dict[str, Any]]:
        return transform_jiji(raw_data, query)

    async def load(self, products: List[Dict[str, Any]]) -> int:
        return await load_jiji(products)
