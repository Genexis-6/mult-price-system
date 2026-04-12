from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from datetime import datetime
from enum import Enum

class AlertStatus(str, Enum):
    ACTIVE = "active"
    TRIGGERED = "triggered"
    EXPIRED = "expired"
    CANCELLED = "cancelled"

class CreatePriceAlertSchema(BaseModel):
    email: EmailStr
    product_name: str = Field(..., min_length=3, max_length=500)
    target_price: float = Field(..., gt=0)
    
    class Config:
        json_schema_extra = {
            "example": {
                "email": "user@example.com",
                "product_name": "iPhone 15 Pro Max",
                "target_price": 1200000
            }
        }

class UpdatePriceAlertSchema(BaseModel):
    target_price: Optional[float] = None
    status: Optional[AlertStatus] = None

class PriceAlertResponse(BaseModel):
    id: int
    email: str
    product_name: str
    target_price: float
    current_best_price: Optional[float]
    current_best_platform: Optional[str]
    status: str
    notification_sent: bool
    created_at: datetime
    updated_at: datetime
    
class PriceHistoryResponse(BaseModel):
    id: int
    platform: str
    price: float
    product_name: str
    checked_at: datetime

class PriceComparisonResponse(BaseModel):
    product_name: str
    target_price: float
    current_best_price: float
    current_best_platform: str
    current_best_url: str
    savings: float
    savings_percentage: float
    all_platform_prices: List[dict]
    timestamp: datetime