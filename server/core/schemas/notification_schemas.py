from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime

class NotificationSchemas(BaseModel):
    """Schema for sending push notifications"""
    title: str = Field(..., description="Notification title")
    body: str = Field(..., description="Notification body")
    fcm_token: str = Field(..., description="FCM device token")
    data: Optional[Dict[str, Any]] = Field(default={}, description="Additional data payload")
    
    class Config:
        json_schema_extra = {
            "example": {
                "title": "Task Completed",
                "body": "Your task has been completed successfully",
                "fcm_token": "your-fcm-token-here",
                "data": {"task_id": "123", "type": "task_completed"}
            }
        }

class NotificationResponseSchemas(BaseModel):
    """Response schema for notification operations"""
    success: bool = Field(..., description="Whether the operation succeeded")
    message: Optional[str] = Field(None, description="Response message")
    data: Dict[str, Any] = Field(default={}, description="Response data")
    timestamp: datetime = Field(default_factory=datetime.now, description="Response timestamp")