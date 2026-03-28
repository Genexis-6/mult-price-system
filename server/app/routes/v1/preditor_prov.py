from fastapi import APIRouter



pred = APIRouter(
    tags=["predict"],
    prefix="pre",
    responses={
        404:{
            "message": "not found"
        }, 
        500:{
            "message": "server error"
        }
    }
)


@pred.post("/")
async def predict_product():
    pass