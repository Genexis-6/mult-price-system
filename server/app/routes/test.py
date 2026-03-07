from fastapi import APIRouter
from app.pipelines.etl.scraper import scrape_url



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
async def testing_scraper():
   
    
    return ""