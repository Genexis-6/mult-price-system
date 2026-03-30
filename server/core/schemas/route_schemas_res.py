from pydantic import BaseModel



class PredictQerySchemas(BaseModel):
    query: str
    
    

class TrainModelQuerySchemas(BaseModel):
    query: str
    page: int