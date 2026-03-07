from datetime import datetime

from sqlalchemy import (
    Column, String, Float, Integer, Text,
    DateTime, Boolean, Index
)
from ..connection import Base


class FusedProduct(Base):
    __tablename__ = "fused_products"

    id               = Column(Integer, primary_key=True, autoincrement=True)
    query            = Column(String(255), nullable=False, index=True)
    source_platform  = Column(String(50))   # jumia / jiji / konga
    product_name     = Column(String(500))
    category         = Column(String(100))
    price            = Column(Float)
    currency         = Column(String(10), default="NGN")
    rating           = Column(Float)
    review_count     = Column(Integer)
    sentiment_score  = Column(Float)
    product_url      = Column(Text)
    image_url        = Column(Text)

    # seller (imputed NULLs from jiji filled here)
    seller_name          = Column(String(255))
    seller_tenure_months = Column(Integer)
    seller_shipping_days = Column(Float)
    seller_total_sales   = Column(Integer)
    seller_quality_score = Column(Float)
    seller_rating        = Column(Float)
    seller_followers     = Column(Integer)

    # ML output (filled by Layer 4)
    recommendation_score = Column(Float)

    fused_at         = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        Index("ix_fused_query_score", "query", "recommendation_score"),
    )
