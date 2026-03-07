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
    
    
    # sites url
    KONGA_TARGET_URL:str
    JIJI_TARGER_URL:str
    JUMIA_TARGET_URL:str
    
    # scraper data
    SCRAPE_API_KEY:str
    MAX_RETIRES:int
    SCRAPE_API_BASE:str
    REQUEST_TIME_OUT:int
    PAGE_TO_SCRAPE:int

settings = DevSettings()