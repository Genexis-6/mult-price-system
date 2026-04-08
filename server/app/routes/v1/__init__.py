from fastapi import APIRouter
from .preditor_route import pred
from .train_route import trainer
from .device_init_route import device_init

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
v1.include_router(trainer)
v1.include_router(device_init)