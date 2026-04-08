from typing import Optional

from pydantic import BaseModel, ConfigDict




class CreateDeviceSchemas(BaseModel):
    fcm_token: Optional[str] = None
    
    

class StoreDeviceTaskIdSchemas(BaseModel):
    fcm_token: Optional[str] = None
    task_id:Optional[str] = None
    model_config = ConfigDict(from_attributes=True)
    
    
