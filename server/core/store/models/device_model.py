from datetime import datetime
from sqlalchemy import Column, DateTime, Integer, String
from sqlalchemy.orm import relationship
from ..connection import Base  

# Device table
class DeviceModel(Base):
    __tablename__ = "device_model"

    id = Column(Integer, primary_key=True, autoincrement=True)
    device_fcm = Column(String(200), unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationship to tasks
    tasks = relationship("TaskIdModel", back_populates="device", cascade="all, delete-orphan")