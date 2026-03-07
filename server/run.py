
from app.config.dev_config import settings
import uvicorn



ADDR= settings.LHOST if settings.MODE=="DEV" else settings.PHOS


if __name__ == "__main__":
    uvicorn.run(
        app=settings.APP_NAME, host=ADDR, reload=settings.DEBUG
    )