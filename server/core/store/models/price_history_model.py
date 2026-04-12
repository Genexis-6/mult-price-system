from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from datetime import datetime
from ..connection import Base

class PriceHistory(Base):
    __tablename__ = "price_history"
    
    id = Column(Integer, primary_key=True, index=True)
    alert_id = Column(Integer, ForeignKey("price_alerts.id"))
    platform = Column(String(50))
    price = Column(Float)
    product_url = Column(Text)
    product_name = Column(String(500))
    checked_at = Column(DateTime, default=datetime.utcnow)
    
    alert = relationship("PriceAlert", back_populates="price_history")