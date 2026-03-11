import asyncio
import json
import math
import re
import argparse
import random
import time
from typing import Any, Literal, Optional
from urllib.parse import urljoin, urlencode
from ..http_client import fetch
from app.config.dev_config import settings

import aiohttp
from bs4 import BeautifulSoup


BASE_URL     = "https://jiji.ng"
SEARCH_URL   = "https://jiji.ng/search"
OPINIONS_API = "https://jiji.ng/api_web/v1/opinions"
REQUEST_TIME_OUT = aiohttp.ClientTimeout(total=60)
MAX_RETRIES  = settings.MAX_RETIRES
SEMAPHORE_LIMIT = settings.SEMAPHORE_LIMIT        # max concurrent requests in-flight at any moment
BATCH_SIZE = settings.BATCH_SIZE         # products processed per batch
BATCH_DELAY = settings.BATCH_DELAY         # seconds to pause between batches




def soup_from(html: str) -> BeautifulSoup:
    return BeautifulSoup(html, "html.parser")


def build_search_url(keyword: str, page: int = 1) -> str:
    params = {"query": keyword}
    if page > 1:
        params["page"] = page
    return f"{SEARCH_URL}?{urlencode(params)}"

def parse_listing_cards(soup: BeautifulSoup) -> list:
    """
    Parse product cards from a search results page.
    Cards are <a class="... qa-advert-list-item ..."> elements.
    """
    cards = soup.select("a.qa-advert-list-item")
    if not cards:
        print("  [!] No cards matched 'a.qa-advert-list-item'.")
        return []

    products = []
    for card in cards:
        try:
            href        = card.get("href", "")
            product_url = urljoin(BASE_URL, href.split("?")[0])

            name_tag  = card.select_one(".b-advert-title-inner.qa-advert-title")
            price_tag = card.select_one(".qa-advert-price")
            loc_tag   = card.select_one("span.b-list-advert__region__text")
            desc_tag  = card.select_one(".b-list-advert-base__description-text")

            img_tag   = card.select_one("picture img")
            image_url = None
            if img_tag:
                image_url = img_tag.get("src") or img_tag.get("data-src")
            if not image_url:
                src_tag = card.select_one("picture source")
                if src_tag:
                    image_url = src_tag.get("srcset", "").split(" ")[0]

            rating = None
            for label in card.select(".b-list-advert-base__label__inner"):
                if label.select_one(".vue-star-rating"):
                    m = re.search(r"(\d+(\.\d+)?)", label.get_text(separator=" ", strip=True))
                    if m:
                        rating = float(m.group(1))
                    break

            products.append({
                "product_name": name_tag.get_text(strip=True) if name_tag else "N/A",
                "price":        price_tag.get_text(strip=True) if price_tag else "N/A",
                "description":  desc_tag.get_text(strip=True)  if desc_tag  else None,
                "location":     loc_tag.get_text(strip=True)   if loc_tag   else None,
                "product_url":  product_url,
                "image_url":    image_url,
                "rating":       rating,
                "review_count": None,
                "opinions_url": None,
                "reviews_raw":      [],
            })
        except Exception as e:
            print(f"  [!] Card parse error: {e}")

    return products


def parse_opinions_page(data: dict) -> list:
    return [
    item.get("comment") for item in data.get("results", [])
    ]



async def fetch_opinions(
    session: aiohttp.ClientSession,
    seller_id: str,
) -> list:
   
    data_p1 = await fetch(
        session,
        f"{OPINIONS_API}/{seller_id}/1.json",
        as_json=True,
        payload={"reply_limit": 2},
        baseUrl=BASE_URL,
    )

    if not data_p1 or data_p1.get("status") != "ok":
        return []

    results_p1 = data_p1.get("results", [])
    all_comments = [item.get("comment") for item in results_p1]

    if not data_p1.get("has_more", False):
        return all_comments  # single page — done

  
    total_count = data_p1.get("count", 0)
    per_page    = len(results_p1) or 20
    total_pages = math.ceil(total_count / per_page)  

   
    pages = await asyncio.gather(*[
        fetch(
            session,
            f"{OPINIONS_API}/{seller_id}/{p}.json",
            as_json=True,
            payload={"reply_limit": 2},
            baseUrl=BASE_URL,
        )
        for p in range(2, total_pages + 1)
    ])

    for data in pages:
        if not data or data.get("status") != "ok":
            continue
        all_comments.extend(item.get("comment") for item in data.get("results", []))

    return all_comments

async def enrich_product(
    session: aiohttp.ClientSession,
    product: dict,
) -> dict:
    """
    Fetch product detail page → review_count + seller_id.
    Then fetch opinions if the seller has reviews.
    """
    html = await fetch(session, product["product_url"], baseUrl=BASE_URL)
    if not html:
        return product

    soup = soup_from(html)

    # Review count
    btn = soup.select_one(".b-feedback-count")
    if btn:
        m = re.search(r"(\d+)", btn.get_text())
        if m:
            product["review_count"] = int(m.group(1))

    # Seller ID → opinions URL + reviews
    seller_a = soup.select_one("a[href*='sellerpage-']")
    if seller_a:
        m = re.search(r"sellerpage-([A-Za-z0-9]+)", seller_a.get("href", ""))
        if m:
            seller_id = m.group(1)
            product["opinions_url"] = f"{BASE_URL}/opinions/{seller_id}"
            if product.get("review_count", 0):
                product["reviews_raw"] = await fetch_opinions(session, seller_id)

    return product


async def extract_jiji(
    keyword: str,
    max_pages: int = 1,

) -> list:
   

    all_products: list = []

    async with aiohttp.ClientSession() as session:

     
        search_urls = [build_search_url(keyword, p) for p in range(1, max_pages + 1)]
        print(f"\n[*] Fetching {len(search_urls)} search page(s)...")

        search_htmls = await asyncio.gather(
            *[fetch(session, u, baseUrl=BASE_URL) for u in search_urls]
        )

        for page_num, html in enumerate(search_htmls, 1):
            if not html:
                print(f"  [!] Page {page_num} failed.")
                continue
            cards = parse_listing_cards(soup_from(html))
            if not cards:
                print(f"  [!] Page {page_num}: no products found.")
                continue
            print(f"  [+] Page {page_num}: {len(cards)} products found.")
            all_products.extend(cards)

        if not all_products:
            return all_products
        
        

        # Phase 2 — enrich in batches
        total_batches = (len(all_products) + BATCH_SIZE - 1) // BATCH_SIZE
        print(f"\n[*] Enriching {len(all_products)} products "
              f"(batch={BATCH_SIZE}, concurrency={SEMAPHORE_LIMIT})...")

        for batch_start in range(0, len(all_products), BATCH_SIZE):
            batch     = all_products[batch_start: batch_start + BATCH_SIZE]
            batch_num = batch_start // BATCH_SIZE + 1

            print(f"\n  Batch {batch_num}/{total_batches} "
                  f"(products {batch_start + 1}–{batch_start + len(batch)})")

            enriched = await asyncio.gather(
                *[enrich_product(session, p) for p in batch]
            )

            for i, p in enumerate(enriched):
                rc = p.get("review_count") or 0
                rv = len(p.get("reviews_raw") or [])
                print(f"    [{batch_start + i + 1:02d}] {p['product_name'][:55]}"
                      f"  | reviews_raw: {rv}/{rc}")

            all_products[batch_start: batch_start + BATCH_SIZE] = list(enriched)

            if batch_start + BATCH_SIZE < len(all_products):
                print(f"  [~] Pausing {BATCH_DELAY}s before next batch...")
                await asyncio.sleep(BATCH_DELAY)

    return all_products
