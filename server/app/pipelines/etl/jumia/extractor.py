import asyncio
import random
import json
import aiohttp
from bs4 import BeautifulSoup
from typing import Optional, List
from ..http_client import fetch
from app.config.dev_config import settings

REQUEST_TIME_OUT = aiohttp.ClientTimeout(total=60)
MAX_RETRIES  = settings.MAX_RETIRES
SEMAPHORE_LIMIT = settings.SEMAPHORE_LIMIT        # max concurrent requests in-flight at any moment
BATCH_SIZE = settings.BATCH_SIZE         # products processed per batch
BATCH_DELAY = settings.BATCH_DELAY         # seconds to pause between batches



sem = asyncio.Semaphore(SEMAPHORE_LIMIT)



def _href(href: Optional[str]) -> Optional[str]:
    if href is None:
        return None
    return f"https://www.jumia.com.ng{href}" if href.startswith("/") else href


def _build_catalog_url(query: str, page: int = 1) -> str:
    return f"https://www.jumia.com.ng/catalog/?q={query}"



def _parse_catalog_page(html: str) -> List[dict]:
    """Extract raw product cards from a catalog page."""
    soup    = BeautifulSoup(html, "html.parser")
    catalog = soup.find("div", attrs={"data-catalog": "true"})
    if not catalog:
        return []

    products = []
    for article in catalog.find_all("article", class_="prd _fb col c-prd"):
        url_tag      = article.find("a", class_="core")
        product_url  = _href(url_tag["href"]) if url_tag else None

        info         = article.find("div", class_="info")
        name_tag     = info.find("h3", class_="name")      if info else None
        price_tag    = info.find("div", class_="prc")      if info else None
        stats        = info.find("div", class_="rev")      if info else None
        rating_tag   = stats.find("div", class_="stars _s") if stats else None

        review_count = None
        if stats:
            parts = stats.get_text(strip=True).split(" ")
            review_count = parts[-1] if parts else None

        img_c    = article.find("div", class_="img-c")
        img_tag  = img_c.find("img", class_="img") if img_c else None

        products.append({
            "product_name": name_tag.get_text(strip=True)   if name_tag   else None,
            "price":        price_tag.get_text(strip=True)   if price_tag  else None,
            "rating":       rating_tag.get_text(strip=True)  if rating_tag else None,
            "review_count": review_count,
            "product_url":  product_url,
            "image_url":    img_tag.get("data-src")          if img_tag    else None,
        })
    return products


def _get_review_url(html: str) -> Optional[str]:
    soup     = BeautifulSoup(html, "html.parser")
    see_all  = soup.find("a", class_="btn _def _ti -mhs -fsh0")
    return _href(see_all["href"]) if see_all else None


def _extract_reviews(html: str) -> List[str]:
    soup     = BeautifulSoup(html, "html.parser")
    comments = []
    for cm in soup.find_all("article", class_="-pvs -hr _bet"):
        h   = cm.find("h3", class_="-m -fs16 -pvs")
        sub = cm.find("p",  class_="-pvs")
        comments.append(
            f"{h.get_text(separator=' ', strip=True) if h else ''} "
            f"{sub.get_text(separator=' ', strip=True) if sub else ''}".strip()
        )
    return comments


async def _process_product(session: aiohttp.ClientSession, product: dict) -> dict:
    """Fetch product page + reviews """
    url  = product["product_url"]
    html = await fetch(session=session, url=url)

    if html is None:
        print(f"[skip] could not fetch {url}")
        return product

    review_url = await asyncio.to_thread(_get_review_url, html)
    
  
    if isinstance(review_url, str) and review_url.startswith("http"):

        review_html = await fetch(session=session,url= review_url)

        if review_html:
            product["reviews_raw"] = await asyncio.to_thread(
                _extract_reviews, review_html
            )
            
    return product


#Batch helpers
def _chunks(lst: list, n: int):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i : i + n]



async def _scrape_jumia_async(query: str, pages: int) -> List[dict]:
    async with aiohttp.ClientSession() as session:

        # Fetch catalog pages — small page counts are fine to do together
        print(f"[catalog] fetching {pages} page(s) for '{query}' …")
        catalog_htmls = await asyncio.gather(
            *[fetch(session=session,url= _build_catalog_url(query, p)) for p in range(1, pages + 1)]
        )
        
        
        

        #Parse catalog HTML (CPU → thread-pool)
        parsed_pages = await asyncio.gather(
            *[asyncio.to_thread(_parse_catalog_page, html)
              for html in catalog_htmls if html]
        )
        raw_products = [p for page in parsed_pages for p in page
                        if p.get("product_url")]
        
    
        print(f"[catalog] found {len(raw_products)} products — "
              f"processing in batches of {BATCH_SIZE} …")

        #Process products in controlled batches so we never flood the API
        results = []
        for batch_num, batch in enumerate(_chunks(raw_products, BATCH_SIZE), start=1):
            print(f"[batch {batch_num}] processing {len(batch)} products …")
            batch_results = await asyncio.gather(
                *[_process_product(session, prod) for prod in batch]
            )
            results.extend(batch_results)

           
            remaining = len(raw_products) - len(results)
            if remaining > 0:
                print(f"[batch {batch_num}] done — waiting {BATCH_DELAY}s before next batch "
                      f"({remaining} products left) …")
                await asyncio.sleep(BATCH_DELAY)

    print(f"[done] scraped {len(results)} products total")
    return results


async def extract_jumia(query: str, pages: int = 1) -> List[dict]:
    """Public entry-point — runs the full async pipeline and returns products."""
    return await _scrape_jumia_async(query, pages)
