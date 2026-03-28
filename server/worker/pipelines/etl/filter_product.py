"""
etl/filters.py
==============
Query-aware product relevance filter used by all 3 ETL transformers.

Removes accessories, replacement parts, and noise from search results —
BUT only filters keywords that are NOT part of the user's search query.
"""

import re
from core.utils import get_logger

logger = get_logger(__name__)

ACCESSORY_KEYWORDS = [
    # Screens & display parts
    "screen replacement", "replacement screen", "lcd screen",
    "screen protector", "tempered glass", "screen guard",
    "screen film", "anti-scratch", "lens protector", "camera lens protector",
    "camera protector", "camera lens",

    # Cases & covers
    "phone case", "back case", "flip case", "silicone case", "tpu case",
    "wallet case", "leather case", "pouch", "protective case",
    "magsafe case", "magsafe transparent", "defender case", "defender pro",
    "otterbox", "spigen", "ringke", "clear case", "bumper case",
    "ring holder", "phone stand", "car mount", "phone holder",
    "luxury protective", "sleek luxury", "transparent case",

    # Power & cables
    "battery", "charger", "charging cable", "usb cable", "power bank",
    "fast charger", "wireless charger", "cablepulse", "data cable",
    "lightning cable", "type-c cable", "usb-c cable",

    # Audio
    "earphone", "earbuds", "headphone", "bluetooth earphone",
    "wireless earphone", "airpods", "neckband",

    # Non-phone devices that share brand names with phone makers
    "hair trimmer", "trimmer", "electric shaver", "shaver", "clipper",
    "hair clipper", "beard trimmer", "electric razor",
    "blender", "fan", "iron", "bulb", "torch", "flashlight",
    "watch strap", "smartwatch strap", "band strap",

    # Generic noise
    "compatible with", "spare part", "replacement part",
    "for tecno", "for iphone", "for samsung", "for infinix",
    "for android", "for xiaomi", "for oppo", "for itel",
]


def _build_filter_regex(query: str) -> re.Pattern | None:
    """
    Build a regex from ACCESSORY_KEYWORDS, excluding any keyword
    that overlaps with the user's search query.
    """
    query_lower     = query.lower()
    active_keywords = [
        kw for kw in ACCESSORY_KEYWORDS
        if kw.lower() not in query_lower
    ]

    if not active_keywords:
        return None

    pattern = r"\b(" + "|".join(re.escape(k) for k in active_keywords) + r")\b"
    return re.compile(pattern, re.IGNORECASE)


def is_relevant_product(product_name: str, filter_re: re.Pattern | None) -> bool:
    if not product_name:
        return False
    if filter_re is None:
        return True
    if filter_re.search(product_name):
        logger.debug(f"Filtered: {product_name[:70]}")
        return False
    return True


def filter_products(products: list[dict], query: str, log_prefix: str = "") -> list[dict]:
    filter_re = _build_filter_regex(query)
    before    = len(products)
    filtered  = [
        p for p in products
        if is_relevant_product(p.get("product_name", ""), filter_re)
    ]
    removed = before - len(filtered)
    if removed:
        logger.info(
            f"{log_prefix} Filtered {removed} irrelevant items "
            f"({before} → {len(filtered)}) for query='{query}'"
        )
    return filtered


