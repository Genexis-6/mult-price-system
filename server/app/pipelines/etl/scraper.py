import time
import requests
from app.config.dev_config import settings
from typing import Optional
from app.utils.logger import get_logger


logger = get_logger("scraper")

def scrape_url(url: str, render_js: bool = False) -> Optional[str]:
    #render_js allows for handling SPA
    params = {
        "api_key": settings.SCRAPE_API_KEY,
        "url":     url,
        "render":  "true" if render_js else "false",
        "country_code": "ng",
    }

    for attempt in range(1, settings.MAX_RETIRES + 1):
        try:
            response = requests.get(
                settings.SCRAPE_API_BASE,
                params=params,
                timeout=settings.REQUEST_TIME_OUT,
            )
            if response.status_code == 200:
                return response.text

            logger.warning(
                f"Attempt {attempt} — status {response.status_code} for {url}"
            )

        except requests.exceptions.Timeout:
            logger.warning(f"Attempt {attempt} — timeout for {url}")
        except requests.exceptions.RequestException as e:
            logger.error(f"Attempt {attempt} — request error: {e}")

        time.sleep(2 ** attempt)

    logger.error(f"All {settings.MAX_RETIRES} attempts failed for {url}")
    return None
