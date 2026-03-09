# import json
# import time
# import random
# from typing import List, Dict, Any, Optional
# from bs4 import BeautifulSoup
# from ..scraper import scrape_url
# from app.config.dev_config import settings




# def extract_jumia(query: str, pages: int = 0) -> List[Dict[str, Any]]:
#     """
#     Scrape Jumia search results for a given query.
#     Iterates through `pages` pages and returns raw product dicts.
#     """
#     raw_products = []

#     for page in range(1, pages + 1):
#         url  = f"https://www.jumia.com.ng/catalog/?q={query.replace(' ', '+')}&page={page}"
#         html = scrape_url(url, render_js=False)

#         if not html:
#             continue
        
      

#         soup  = BeautifulSoup(html, "html.parser")
#         cards = soup.select("-phs -pvxs row _no-g _4cl-3cm-shs")  # Jumia product card selector
#         print(cards)
        
#         # for card in cards:
#         #     try:
#         #         raw_products.append({
#         #             "product_name": _text(card, "h3.name"),
#         #             "price":        _text(card, "div.prc"),
#         #             "rating":       _text(card, "div.stars._s"),
#         #             "review_count": _text(card, "div.rev"),
#         #             "product_url":  _href(card, "a.core"),
#         #             "image_url":    _img(card,  "img.img"),
#         #             "seller_name":  _text(card, "div.sku"),   # may be None
#         #         })
#         #     except Exception:
#         #         continue  # skip malformed cards silently

#         # ── Seller detail pages (ratings, tenure, etc.) ───────────────────────
#         # Jumia seller info lives on the product detail page.
#         # We fetch the first N results' detail pages for richer seller data.
#         # for product in raw_products[-len(cards):]:
#         #     if product.get("product_url"):
#         #         _enrich_with_seller_data(product)

#         # # ── Reviews ──────────────────────────────────────────────────────────
#         # for product in raw_products[-len(cards):]:
#         #     if product.get("product_url"):
#         #         _enrich_with_reviews(product)

#     return raw_products


# # ── Private helpers ───────────────────────────────────────────────────────────

# # def _text(tag, selector: str) -> str | None:
# #     el = tag.select_one(selector)
# #     return el.get_text(strip=True) if el else None


# # def _href(tag, selector: str) -> str | None:
# #     el = tag.select_one(selector)
# #     if el and el.get("href"):
# #         href = el["href"]
# #         return f"https://www.jumia.com.ng{href}" if href.startswith("/") else href
# #     return None


# # def _img(tag, selector: str) -> str | None:
# #     el = tag.select_one(selector)
# #     return el.get("data-src") or el.get("src") if el else None


# # def _enrich_with_seller_data(product: dict) -> None:
# #     """Fetch product detail page to get seller info."""
# #     html = scrape_url(product["product_url"])
# #     if not html:
# #         return
# #     soup = BeautifulSoup(html, "html.parser")

# #     product["seller_name"]          = _text(soup, "a.seller")
# #     product["seller_rating"]        = _text(soup, "div.seller-info .rating")
# #     product["seller_total_sales"]   = _text(soup, "span.sold-count")
# #     product["seller_quality_score"] = _text(soup, "span.quality-score")
# #     product["seller_tenure_months"] = _text(soup, "span.member-since")
# #     product["seller_shipping_days"] = _text(soup, "span.shipping-days")
# #     product["seller_followers"]     = _text(soup, "span.followers")


# # def _enrich_with_reviews(product: dict) -> None:
# #     """Fetch reviews from the product detail page."""
# #     html = scrape_url(product["product_url"])
# #     if not html:
# #         return
# #     soup = BeautifulSoup(html, "html.parser")

# #     reviews = [el.get_text(strip=True) for el in soup.select("article.-pvs p.bd")]
# #     product["reviews_raw"] = json.dumps(reviews[:50])  # cap at 50 reviews