from sqlalchemy import Index

from .product_model import ProductMixin
from ..connection import Base



class JijiProduct(Base, ProductMixin):
    """
    Jiji does not expose seller_tenure_months, seller_shipping_days,
    seller_total_sales, seller_quality_score, seller_followers.
    Those columns will be NULL and imputed during data fusion (Layer 3).
    """
    __tablename__ = "jiji_products"
    __table_args__ = (
        Index("ix_jiji_query_name", "query", "product_name"),
    )
