from sqlalchemy import Index

from .product_model import ProductMixin
from ..connection import Base


class KongaProduct(Base, ProductMixin):
    __tablename__ = "konga_products"
    __table_args__ = (
        Index("ix_konga_query_name", "query", "product_name"),
    )