from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from datetime import datetime

from core.utils.price_alert_status_enum import PriceAlertStatus
from ..connection import Base


class PriceAlert(Base):
    __tablename__ = "price_alerts"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), nullable=False, index=True)
    product_name = Column(String(500), nullable=False)
    target_price = Column(Float, nullable=False)
    current_best_price = Column(Float, nullable=True)
    current_best_platform = Column(String(50), nullable=True)
    current_best_url = Column(Text, nullable=True)
    status = Column(String(20), default="active")
    notification_sent = Column(Boolean, default=False)
    last_checked = Column(DateTime, nullable=True)
    last_checked_at = Column(DateTime, nullable=True)  # Track when last check was performed
    next_check_at = Column(DateTime, nullable=True)    # When next check should occur
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    price_history = relationship("PriceHistory", back_populates="alert", cascade="all, delete-orphan")