from sqlalchemy import (
    Column, String, Float, Integer, Text,
    DateTime, Boolean, Index
)
from sqlalchemy.orm import declarative_base
from datetime import datetime

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
    product_url      = Column(Text)
    image_url        = Column(Text)

   
    reviews_raw      = Column(Text) 

    sentiment_score  = Column(Float) 

    
    seller_name          = Column(String(255))
    seller_tenure_months = Column(Integer)   # how long selling on platform
    seller_shipping_days = Column(Float)     # avg shipping speed in days
    seller_total_sales   = Column(Integer)   # number of successful sales
    seller_quality_score = Column(Float)     # platform quality badge / score
    seller_rating        = Column(Float)     # seller-specific rating 0-5
    seller_followers     = Column(Integer)

  
    scraped_at       = Column(DateTime, default=datetime.utcnow)
    is_available     = Column(Boolean, default=True)