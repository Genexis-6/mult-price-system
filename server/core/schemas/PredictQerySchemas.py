from pydantic import BaseModel



class PredictQerySchemas(BaseModel):
    query: str