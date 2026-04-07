
from datetime import datetime
from typing import Any, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field

from core.task_definition import TaskResults





class RedisPublishSchemas(BaseModel):
    task_id: str
    message: Optional[str] = None
    result: Optional[Any] = None
    progress: Optional[int] = 0
    timestamp: Optional[datetime] = Field(default_factory=datetime.now)
    status: Optional[TaskResults] = TaskResults.PENDING
    mode: Optional[Literal["train_model", "predict"]] = "predict"
    
    model_config = ConfigDict(
        from_attributes=True, 
        arbitrary_types_allowed=True,
        json_encoders={
            datetime: lambda v: v.isoformat()
        }
    )