from typing import List
from sqlalchemy import select
from ..schemas import ProductSchemas
from ..connection import AsyncSession
from ..models import JumiaProduct
from .base_product_queries import BaseProductQueries
from app.utils.logger import get_logger

logger = get_logger(__name__)

class JumiaQueries(BaseProductQueries):
    def __init__(self, db: AsyncSession):
        super().__init__(db, JumiaProduct)