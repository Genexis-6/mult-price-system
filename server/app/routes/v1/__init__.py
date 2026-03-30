from fastapi import APIRouter
from .preditor_route import pred


v1 = APIRouter(
    prefix="/v1",
    tags=["v1"],
    responses={
        404:{
            "message":"not found"
        },
        500 :{
            "message":'server error'
        }
    }
)

v1.include_router(pred)