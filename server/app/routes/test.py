from fastapi import APIRouter, BackgroundTasks
from worker.pipelines import run_full_pipeline




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
    backgoundTask.add_task(run_full_pipeline, "itel phone", 1, "predict") 
    # res = requests.post(settings.OLLAMA_AI, json={"model":"phi3", "prompt":"hello"})
    # print(res.text)
    return  {"message": "predicting"}


@test.get("/train-model")
async def train_model(bac_task: BackgroundTasks):
    bac_task.add_task(run_full_pipeline, "tecno phones", 8, "train_model")
    return  {"message": "trainig model"}
