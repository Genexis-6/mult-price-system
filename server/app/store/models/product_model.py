from sqlalchemy import (
    Column, String, Float, Integer, Text,
    DateTime, Boolean, Index
)
from sqlalchemy.orm import declarative_base
from datetime import datetime

from sqlalchemy.dialects.postgresql import ARRAY




class ProductMixin:
    """
    Columns shared across all 3 platform tables.
    Jiji-specific seller fields will be NULL for jiji rows
    and populated for jumia/konga rows.
    """
    id               = Column(Integer, primary_key=True, autoincrement=True)
    query            = Column(String(255), nullable=False, index=True) 
    product_name     = Column(String(500), nullable=False)
    category         = Column(String(100))
    price            = Column(Float)
    currency         = Column(String(10), default="NGN")
    rating           = Column(Float)                                   
    review_count     = Column(Integer)
    product_url = Column(String, unique=True, nullable=True)
    image_url        = Column(Text)

   
    reviews_raw = Column(ARRAY(Text), nullable=True)

    sentiment_score  = Column(Float) 

  
    scraped_at       = Column(DateTime, default=datetime.utcnow)
    is_available     = Column(Boolean, default=True)