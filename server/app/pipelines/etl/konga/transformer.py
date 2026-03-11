

import re
from typing import List, Dict, Any
from datetime import datetime
from ..helpers import HelperTransformers


def transform_konga(raw_data: List[Dict[str, Any]], query: str) -> List[Dict[str, Any]]:
    """
    Clean and normalise raw Jumia scraped data.
    Returns list of dicts ready for DB insertion.
    """
    products = []

    # print(raw_data)
    for raw in raw_data:
        try:
            product = {
                "query":        query,
                "product_name": _clean_text(raw.get("product_name")),
                "category":     _infer_category(query),
                "price":        _parse_price(raw.get("price")),
                "currency":     "NGN",
                "rating":       _parse_rating(raw.get("rating")),
                "review_count": _parse_review_count(raw.get("review_count")),
                "product_url":  raw.get("product_url"),
                "image_url":    raw.get("image_url"),
                "reviews_raw":  raw.get("reviews"),

                # Sentiment filled later by Layer 2
                "sentiment_score": None,
                "scraped_at":      datetime.utcnow(),
                "is_available":    True,
            }

            # Skip products with no name or price
            if not product["product_name"] or product["price"] is None:
                continue

            products.append(product)

        except Exception:
            continue

    return products





#Parsing helpers
def _parse_price(value) -> float | None:
    """'₦ 125,000' → 125000.0"""
    if not value:
        return None
    cleaned = re.sub(r"[^\d.]", "", str(value).replace(",", ""))
    try:
        return float(cleaned)
    except ValueError:
        return None


def _parse_float(value) -> float | None:
    if not value:
        return None
    cleaned = re.sub(r"[^\d.]", "", str(value))
    try:
        return float(cleaned)
    except ValueError:
        return None


def _parse_int(value) -> int | None:
    if not value:
        return None
    cleaned = re.sub(r"[^\d]", "", str(value))
    try:
        return int(cleaned)
    except ValueError:
        return None


def _infer_category(query: str) -> str:
    query = query.lower()
    if any(k in query for k in ["phone", "iphone", "samsung", "tecno", "infinix"]):
        return "phones"
    if any(k in query for k in ["laptop", "tv", "speaker", "earphone", "camera"]):
        return "electronics"
    if any(k in query for k in ["shirt", "dress", "shoe", "bag", "trouser"]):
        return "fashion"
    return "general"




def _clean_text(value: str | None) -> str | None:
    if not value:
        return None
    return " ".join(value.split())




def _parse_rating(rating: str | None) -> float | None:
    if not rating:
        return None

    match = re.search(r"(\d+(?:\.\d+)?)", rating)
    return float(match.group(1)) if match else None


def _parse_review_count(review: str | None) -> int | None:
    if not review:
        return None

    match = re.search(r"\((\d+)\)", review)
    return int(match.group(1)) if match else None