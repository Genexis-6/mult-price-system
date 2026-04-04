
class TaskNames:
    PIPELINE_TASK = "pipeline_task_handler"
    
from enum import Enum

class TaskResults(Enum):
    PENDING = "pending"
    STARTED = "started"
    COMPLETED = "completed"
    FAILED = "failed"