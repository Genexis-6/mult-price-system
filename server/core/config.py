from pydantic_settings import BaseSettings
from dotenv import load_dotenv
from typing import Optional


load_dotenv()

class DevSettings(BaseSettings):
    # Application - Added defaults for problematic fields
    DATABASE_URL: str
    APP_NAME: str
    MODE: str
    PORT: int
    LHOST: str = "0.0.0.0"     
    PHOS: str = "0.0.0.0"      
    DEBUG: bool = True          
    
    # Scraper data - Keep MAX_RETIRES with default
    SCRAPE_API_KEY: str
    MAX_RETIRES: int = 3        
    SCRAPE_API_BASE: str
    REQUEST_TIME_OUT: int = 60  
    PAGE_TO_SCRAPE: int = 3     
    SEMAPHORE_LIMIT: int = 5    
    BATCH_SIZE: int = 5         
    BATCH_DELAY: int = 6        
    
    # HuggingFace
    HF_HUB_OFFLINE: bool = False
    TRANSFORMERS_OFFLINE: bool = False
    TOKENIZERS_PARALLELISM: bool = False
    
    # Redis - Fixed REDIS_PORT to int with default
    REDIS_BROKER_URL: str
    REDIS_BACKEND_URL: str
    REDIS_HOST: str = "redis"   
    REDIS_PORT: int = 6379       # Changed from str to int, added default
    
    # Email
    APP_EMAIL_SENDER: str
    MAIL_JET_API: str
    MAIL_JET_SK: str
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "allow"           # Ignore any extra fields


settings = DevSettings()