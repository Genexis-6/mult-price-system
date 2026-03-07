from pydantic_settings import BaseSettings
from dotenv import load_dotenv


load_dotenv()
class DevSettings(BaseSettings):
    DATABASE_URL: str
    APP_NAME:str
    MODE:str
    PORT:int
    LHOST:str
    PHOS:str
    DEBUG:bool
    
    
    

settings = DevSettings()