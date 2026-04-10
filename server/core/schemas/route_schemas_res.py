from typing import Optional

from pydantic import BaseModel



class PredictQerySchemas(BaseModel):
    query: str
    # fcm_token:Optional[str] = None
    
    

class TrainModelQuerySchemas(BaseModel):
    query: str
    page: int