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
    backgoundTask.add_task(run_full_pipeline, "iphone 17", 2) 
    # res = requests.post(settings.OLLAMA_AI, json={"model":"phi3", "prompt":"hello"})
    # print(res.text)
    return  {"message": "hehehe"}
