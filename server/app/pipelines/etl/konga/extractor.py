import asyncio
import json
import time
import random
from datetime import datetime
from pathlib import Path
from typing import Dict, List
import aiohttp
from bs4 import BeautifulSoup
import requests
from app.config.dev_config import settings
from app.utils.logger import get_logger
from ..http_client import fetch, getHeaders




GRAPHQL_URL  = "https://api.konga.com/v1/graphql"
PRODUCT_BASE = "https://www.konga.com/product"   
IMAGE_URL="https://www-konga-com-res.cloudinary.com/image/upload/f_auto,fl_lossy,dpr_auto,q_auto,w_1080/media/catalog/product"

PAGE_SIZE    = 40                                
DELAY        = (0.5, 1.5)                        
BASE_URL="https://www.konga.com"
REQUEST_TIME_OUT = aiohttp.ClientTimeout(total=60)
BATCH_SIZE = settings.BATCH_SIZE
BATCH_DELAY = settings.BATCH_DELAY




SEARCH_QUERY = """
{
  searchByStore(
    search_term: []
    numericFilters: []
    sortBy: ""
    query: "{query}"
    paginate: { page: {page}, limit: {limit} }
    store_id: 1
  ) {
    pagination { limit page total }
    products {
      name
      final_price
      original_price
      deal_price
      special_price
      price
      image_thumbnail_path
      image_full
      url_key
      product_id
      sku
      brand
      description
      status
      stock { in_stock quantity quantity_sold }
      product_rating {
        quality {
          average
          number_of_ratings
          one_star two_star three_star four_star five_star
          percentage
        }
        total_ratings
      }
    }
  }
}
"""


def fetch_page(session: requests.Session, query: str, page: int, limit: int, log) -> dict | None:
    # Make one GraphQL request and return the parsed JSON response
    gql = SEARCH_QUERY.replace("{query}", query).replace("{page}", str(page)).replace("{limit}", str(limit))
    payload = {"query": gql}
    try:
        resp = session.post(GRAPHQL_URL, json=payload, headers=getHeaders(BASE_URL), timeout=REQUEST_TIME_OUT)
        resp.raise_for_status()
        data = resp.json()
        if "errors" in data:
            log.error(f"  [GraphQL Error] {data['errors']}")
            return None

        return data.get("data", {}).get("searchByStore", {})

    except requests.RequestException as e:
        log.error(f"Request Error ==? {e}")
        return None
    


def _extract_price(raw: dict) -> str:
    candidates = [
        raw.get("deal_price"),
        raw.get("final_price"),
        raw.get("special_price"),
        raw.get("original_price"),
        raw.get("price"),
    ]
    for val in candidates:
        if val and float(val) > 0:
            try:
                return f"{float(val):,.2f}"
            except (ValueError, TypeError):
                return str(val)
    return None


def _extract_rating(raw: dict) -> dict:
    pr = raw.get("product_rating") or {}
    quality = pr.get("quality") or {}

    average = quality.get("average")
    total   = quality.get("number_of_ratings") or pr.get("total_ratings")

    breakdown = [
               { "5_star": quality.get("five_star")},
       { "4_star": quality.get("four_star")},
        {"3_star": quality.get("three_star")},
        {"2_star": quality.get("two_star")},
        {"1_star": quality.get("one_star")},
    ]

    return {
        "average":      float(average) if average else None,
        "total_ratings": int(total)    if total   else None,
        "breakdown":    breakdown,
    }


def _build_url(prefix: str, url_key: str) -> str:
    if not url_key:
        return None
    return f"{prefix}/{url_key}"



def _get_product_info(raw: dict) -> dict:
    rating_data = _extract_rating(raw)
    return {
       
        "product_name":  raw.get("name"),
        "price":         _extract_price(raw),
        "rating":        rating_data.get("average"),
        "review_count":  rating_data.get("total_ratings"),
        "product_url":   _build_url(PRODUCT_BASE, raw.get("url_key")),
        "image_url":    _build_url(IMAGE_URL,  raw.get("image_full") or raw.get("image_thumbnail_path")),
        
    }

    
 
#Batch helpers
def _chunks(lst: list, n: int):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i : i + n]


def _extract_reviews(html: str) -> list[str]:
    """Sync function — safe to run in asyncio.to_thread."""
    try:
        soup = BeautifulSoup(html, "html.parser")
        script = soup.find("script", {"id": "__NEXT_DATA__"})
        if not script:
            return []
        next_data = json.loads(script.string)
        reviews = (
            next_data["props"]["initialProps"]["pageProps"]
            ["data"]["product"]["product_reviews"]
        )
        return [r["comment"] for r in reviews if r.get("comment")]
    except Exception as e:
        print(f"[review parse error] {e}")
        return []


async def _process_product(session: aiohttp.ClientSession, product: dict) -> dict:
    url = product.get("product_url")
    if not url:
        return product

    html = await fetch(session=session, url=url, baseUrl=BASE_URL)
    if html is None:
        print(f"[skip] could not fetch {url}")
        return product

    product["reviews_raw"] = await asyncio.to_thread(_extract_reviews, html)
    return product


async def extract_konga(query: str, pages: int = 1, limit: int = 40) -> list[dict]:
    all_products = []
    total_available = None

    print(f"[Konga catalog] fetching {pages} page(s) for '{query}' …")

    async with aiohttp.ClientSession() as session:

        for page in range(pages):
            gql = (
                SEARCH_QUERY
                .replace("{query}", query)
                .replace("{page}", str(page))
                .replace("{limit}", str(limit))
            )
            payload = {"query": gql}

            print(f"→ Konga etl Fetching page {page}")
            data = await fetch(
                session=session, method="POST",
                url=GRAPHQL_URL, payload=payload, baseUrl=BASE_URL
            )

            if not data:
                print("[STOP] Empty response.")
                break

            result = data.get("data", {}).get("searchByStore", {})

            if total_available is None:
                total_available = (result.get("pagination") or {}).get("total", 0)
                print(f"Konga reports {total_available} total results for '{query}'")

            raw_products = result.get("products") or []
            if not raw_products:
                print("[STOP] No products in response.")
                break

            for raw in raw_products:
                all_products.append(_get_product_info(raw))

            print(f"✓ Page {page} → {len(raw_products)} products (total: {len(all_products)})")
            await asyncio.sleep(random.uniform(*DELAY))

        
        results = []
        for batch_num, batch in enumerate(_chunks(all_products, BATCH_SIZE), start=1):
            print(f"[Konga batch {batch_num}] processing {len(batch)} products …")
            batch_results = await asyncio.gather(
                *[_process_product(session, prod) for prod in batch]
            )
            results.extend(batch_results)

            
            remaining = len(all_products) - len(results)
            if remaining > 0:
                print(f"[Konga batch {batch_num}] done — waiting {BATCH_DELAY}s "
                      f"({remaining} products left) …")
                await asyncio.sleep(BATCH_DELAY)

    return results

