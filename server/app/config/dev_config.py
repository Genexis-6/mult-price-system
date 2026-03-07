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
    SCRAPE_API_KEY:str
    
    # sites url
    KONGA_TARGET_URL:str
    JIJI_TARGER_URL:str
    JUMIA_TARGET_URL:str

settings = DevSettings()