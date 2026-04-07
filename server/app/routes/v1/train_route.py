from fastapi import APIRouter, HTTPException

from core.schemas import TrainModelQuerySchemas
from worker.tasks import pipeline_task_handler
from core.utils import get_logger


logger = get_logger(__name__)




trainer = APIRouter(
    tags=["train"],
    prefix="/train",
    responses={
        404: {
            "message":"not found"
        },
        500:{
            "message":"server error"
        }
    }
)




@trainer.post("/")
async def train_model(t: TrainModelQuerySchemas):
    try:
        task = await pipeline_task_handler.kiq(
            t.query,
            "train_model",
            t.page,
        )

        job_id = task.task_id

        return {
            "job_id": job_id,
            "status": "pending",
            "mode": "taining model",
            "message": "Task submitted successfully"
        }

    except Exception as e:
        logger.error(f"Error starting task: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
      