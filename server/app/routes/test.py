from fastapi import APIRouter, BackgroundTasks
from app.pipelines import run_full_pipeline
from app.config.dev_config import settings
import requests



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
    backgoundTask.add_task(run_full_pipeline, "oppo reno 5", 1)  

    return  {"message": "hehehe"}
