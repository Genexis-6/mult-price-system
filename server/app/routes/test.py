from fastapi import APIRouter, BackgroundTasks
from app.pipelines import run_full_pipeline




test = APIRouter(
    prefix="/test",
    responses={
        404:{
            "message":"not found"
        }
    },
    tags=["test"]
)


@test.get("/")
async def testing_scraper(backgoundTask: BackgroundTasks):
    backgoundTask.add_task(run_full_pipeline, "samsung s24", 1)  
    return  {"message": "running pipeline in background"}