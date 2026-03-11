import asyncio
import time
import random
from datetime import datetime
from pathlib import Path
from typing import Dict, List
import aiohttp
import requests
from app.config.dev_config import settings
from app.utils.logger import get_logger
from ..http_client import fetch




GRAPHQL_URL  = "https://api.konga.com/v1/graphql"
PRODUCT_BASE = "https://www.konga.com/product"   
IMAGE_URL="https://www-konga-com-res.cloudinary.com/image/upload/f_auto,fl_lossy,dpr_auto,q_auto,w_1080/media/catalog/product"

PAGE_SIZE    = 40                                
DELAY        = (0.5, 1.5)                        

HEADERS = {
    "Content-Type":    "application/json",
    "Accept":          "application/json",
    "Origin":          "https://www.konga.com",
    "Referer":         "https://www.konga.com/",
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/122.0.0.0 Safari/537.36"
    ),
}



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
        resp = session.post(GRAPHQL_URL, json=payload, headers=HEADERS, timeout=settings.REQUEST_TIME_OUT)
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



def _extract_product_info(raw: dict) -> dict:
    rating_data = _extract_rating(raw)
    return {
       
        "product_name":  raw.get("name"),
        "price":         _extract_price(raw),
        "rating":        rating_data.get("average"),
        "review_count":  rating_data.get("total_ratings"),
        "product_url":   _build_url(PRODUCT_BASE, raw.get("url_key")),
        "image_url":    _build_url(IMAGE_URL,  raw.get("image_full") or raw.get("image_thumbnail_path")),
        "reviews": list(str(rating_data.get("breakdown"))),
        
    }

    
 
 



async def extract_konga(query: str, pages: int, limit: int = 40, output: str = None, log=None) -> List[Dict]:

    all_products = []
    page = 0
    total_available = None

    print(f"[catalog] fetching {pages} page(s) for '{query}' …")
    gql = SEARCH_QUERY.replace("{query}", query).replace("{page}", str(page)).replace("{limit}", str(limit))
    payload = {"query": gql}

    async with aiohttp.ClientSession() as session:

        while page < pages:

            log.info(f"→ Fetching page {page}")

            data = await fetch(session=session, method="POST", url=GRAPHQL_URL, payload=payload, headers=HEADERS,)
            

            if not data:
                log.error("[STOP] Empty response.")
                break
            
            result = data.get("data", {}).get("searchByStore", {})

            if total_available is None:
                pagination = result.get("pagination") or {}
                total_available = pagination.get("total", 0)

                log.info(f"Konga reports {total_available} total results for '{query}'")

            raw_products = result.get("products") or []

            if not raw_products:
                log.error("[STOP] No products in response.")
                break

            for raw in raw_products:
                all_products.append(_extract_product_info(raw))

            log.info(f"✓ Page {page} → {len(raw_products)} products (total: {len(all_products)})")

            page += 1

            await asyncio.sleep(random.uniform(*DELAY))

    return all_products