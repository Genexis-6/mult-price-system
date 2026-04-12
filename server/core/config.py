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
    
    
    
    
    # scraper data
    SCRAPE_API_KEY:str
    MAX_RETIRES:int
    SCRAPE_API_BASE:str
    REQUEST_TIME_OUT:int
    PAGE_TO_SCRAPE:int
    SEMAPHORE_LIMIT:int
    BATCH_SIZE:int
    BATCH_DELAY:int
    
    TOKENIZERS_PARALLELISM:bool
    HF_HUB_OFFLINE:str
    
    # ollama ai
    REDIS_BROKER_URL:str
    REDIS_BACKEND_URL:str
    
    REDIS_HOST:str
    REDIS_PORT:str
    
    APP_EMAIL_SENDER:str
    MAIL_JET_API:str
    MAIL_JET_SK:str
    

settings = DevSettings()