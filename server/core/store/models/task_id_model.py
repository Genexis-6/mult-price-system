from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from ..connection import Base
# Task table
class TaskIdModel(Base):
    __tablename__ = "task_id_model"

    id = Column(Integer, primary_key=True, autoincrement=True)
    task_id = Column(String(200), unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Foreign key to DeviceModel
    device_id = Column(Integer, ForeignKey("device_model.id"))
    device = relationship("DeviceModel", back_populates="tasks")