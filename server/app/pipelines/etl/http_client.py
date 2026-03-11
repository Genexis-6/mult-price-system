import asyncio
import random
from typing import Any, Optional, Literal

import aiohttp
from app.config.dev_config import settings

REQUEST_TIME_OUT = aiohttp.ClientTimeout(total=60)
MAX_RETRIES  = settings.MAX_RETIRES
SEMAPHORE_LIMIT = settings.SEMAPHORE_LIMIT        # max concurrent requests in-flight at any moment
BATCH_SIZE = settings.BATCH_SIZE         # products processed per batch
BATCH_DELAY = settings.BATCH_DELAY         # seconds to pause between batches



sem = asyncio.Semaphore(SEMAPHORE_LIMIT)

async def fetch(session: aiohttp.ClientSession, url: str, 
                payload: Optional[dict] = None,
                method:Optional[Literal["GET", "POST"]] = "GET",
                headers: Optional[dict] = None,
                ) -> Optional[Any]:
    if not isinstance(url, str):
        print(f"[invalid url] {url}")
        return None
    
    headers = headers or {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"
    }

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            async with sem:
                if method == "GET":
                    async with session.get(url=url, timeout=REQUEST_TIME_OUT, headers=headers, params=payload) as resp:
                        if resp.status == 429:
                            # Back off longer than normal — we're hitting the wall
                            wait = (2 ** attempt) * 10
                            print(f"[429] rate-limited — waiting {wait}s (attempt {attempt})")
                            await asyncio.sleep(wait)
                            continue

                        if resp.status == 200:
                            return await resp.text()

                        print(f"[{resp.status}] attempt {attempt} for {url}")
                if method == "POST":
                    async with session.post(url=url, headers=headers, json=payload, timeout=REQUEST_TIME_OUT) as resp:
                        if resp.status == 429:
                            # Back off longer than normal — we're hitting the wall
                            wait = (2 ** attempt) * 10
                            print(f"[429] rate-limited — waiting {wait}s (attempt {attempt})")
                            await asyncio.sleep(wait)
                            continue
                        resp.raise_for_status()
                        data = await resp.json()

                        if "errors" in data:
                            print(f"[Error] {data['errors']}")
                            return None
                        
                        return data

        except asyncio.TimeoutError:
            print(f"[timeout] attempt {attempt} for {url}")
        except aiohttp.ClientError as e:
            print(f"[error]   attempt {attempt} for {url}: {e}")

        if attempt < MAX_RETRIES:
            await asyncio.sleep((2 ** attempt) + random.uniform(0, 1))

    print(f"[failed]  all {MAX_RETRIES} attempts exhausted for {url}")
    return None
