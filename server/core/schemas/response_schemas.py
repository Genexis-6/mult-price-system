from pydantic import BaseModel, Field
from typing import TypeVar, Generic, Optional, Any
from datetime import datetime


T = TypeVar('T')

class CustomResponseSchemas(BaseModel, Generic[T]):
    status_code: int = Field(default=200, description="HTTP status code")
    message: str = Field(default="Success", description="Response message")
    data: Optional[T] = Field(default=None, description="Response data")
    success: bool = Field(default=True, description="Indicates if request was successful")
    error_code: Optional[str] = Field(default=None, description="Error code if any")

    class Config:
        json_schema_extra = {
            "example": {
                "status_code": 200,
                "message": "Success",
                "data": None,
                "success": True,
                "error_code": None,
            }
        }
    
    @classmethod
    def success_response(cls, data: T, message: str = "Success", status_code: int = 200):
        """Create a success response"""
        return cls(
            status_code=status_code,
            message=message,
            data=data,
            success=True,
            error_code=None
        )
    
    @classmethod
    def error_response(cls, message: str, error_code: str = None, status_code: int = 400, data: Any = None):
        """Create an error response"""
        return cls(
            status_code=status_code,
            message=message,
            data=data,
            success=False,
            error_code=error_code
        )
    
