from ..connection import AsyncSession
from ..models import JijiProduct
from .base_product_queries import BaseProductQueries
from core.utils import get_logger

logger = get_logger(__name__)

class JijiQueries(BaseProductQueries):
    def __init__(self, db: AsyncSession):
        super().__init__(db, JijiProduct)