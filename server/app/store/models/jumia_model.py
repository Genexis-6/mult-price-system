from sqlalchemy import Index

from .product_model import ProductMixin
from ..connection import Base


class JumiaProduct(Base, ProductMixin):
    __tablename__ = "jumia_products"
    __table_args__ = (
        Index("ix_jumia_query_name", "query", "product_name"),
    )
