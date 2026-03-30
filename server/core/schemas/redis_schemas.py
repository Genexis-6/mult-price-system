
from typing import Any, Literal, Optional

from pydantic import BaseModel, ConfigDict

from core.task_definition import TaskResults




class RedisPublishSchemas(BaseModel):
    task_id: str
    message:Optional[str] = None
    result: Optional[Any] = None
    progress: Optional[int] = 0,
    status: Optional[TaskResults] = TaskResults.PENDING
    mode: Optional[Literal["train_model", "predict"]] = "predict"
    model_config = ConfigDict(from_attributes=True, arbitrary_types_allowed=True)
    