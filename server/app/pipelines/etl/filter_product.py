"""
etl/filters.py
==============
Query-aware product relevance filter used by all 3 ETL transformers.

Removes accessories, replacement parts, and noise from search results —
BUT only filters keywords that are NOT part of the user's search query.

Example:
  query="power bank"  → "power bank" removed from filter → all results kept
  query="samsung phone" → "power bank" still filtered → power banks removed
"""

import re
from app.utils.logger import get_logger

logger = get_logger(__name__)

# ── Full accessory keyword list ───────────────────────────────────────────────
# Each entry is filtered UNLESS it appears in the user's query.

ACCESSORY_KEYWORDS = [
    # Screens & display parts
    "screen replacement", "replacement screen", "lcd screen",
    "screen protector", "tempered glass", "screen guard",
    "screen film", "anti-scratch",

    # Cases & covers
    "phone case", "back case", "flip case", "silicone case", "tpu case",
    "wallet case", "leather case", "pouch", "protective case",
    "ring holder", "phone stand", "car mount", "phone holder",

    # Power & cables
    "battery", "charger", "charging cable", "usb cable", "power bank",
    "fast charger", "wireless charger",

    # Audio
    "earphone", "earbuds", "headphone", "bluetooth earphone",
    "wireless earphone", "airpods", "neckband",

    # Generic noise patterns
    "compatible with", "spare part", "replacement part",
    "for tecno", "for iphone", "for samsung", "for infinix",
    "for android", "for xiaomi", "for oppo",
]


def _build_filter_regex(query: str) -> re.Pattern:
    """
    Build a regex from ACCESSORY_KEYWORDS, excluding any keyword
    that overlaps with the user's search query.

    e.g. query="power bank charger" → removes "power bank" and "charger"
    from the filter so those results are not discarded.
    """
    query_lower = query.lower()

    # Keep only keywords NOT present in the query
    active_keywords = [
        kw for kw in ACCESSORY_KEYWORDS
        if kw.lower() not in query_lower
    ]

    if not active_keywords:
        # Query matches everything — don't filter anything
        return None

    pattern = r"\b(" + "|".join(re.escape(k) for k in active_keywords) + r")\b"
    return re.compile(pattern, re.IGNORECASE)


def is_relevant_product(product_name: str, filter_re: re.Pattern | None) -> bool:
    """
    Returns True if the product should be kept.
    filter_re=None means no filtering (query matches all keywords).
    """
    if not product_name:
        return False
    if filter_re is None:
        return True
    if filter_re.search(product_name):
        logger.debug(f"Filtered: {product_name[:70]}")
        return False
    return True


def filter_products(products: list[dict], query: str, log_prefix: str = "") -> list[dict]:
    """
    Filter a list of product dicts, removing accessories that are
    irrelevant to the user's query.

    Args:
        products:   List of product dicts from transformer
        query:      The original user search query (used to exempt keywords)
        log_prefix: Platform name for logging e.g. "[jumia]"
    """
    filter_re = _build_filter_regex(query)
    before    = len(products)

    filtered = [
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