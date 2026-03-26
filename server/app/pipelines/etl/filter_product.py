"""
etl/filters.py
==============
Query-aware product relevance filter used by all 3 ETL transformers.

Removes accessories, replacement parts, and noise from search results —
BUT only filters keywords that are NOT part of the user's search query.
"""

import re
from app.utils.logger import get_logger

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



# [{'rank': 1, 'product_name': 'Luxury Original T-Shirt for Men', 'source_platform': 'jiji', 'price': 24000.0, 'currency': 'NGN', 'rating': 0.0, 'review_count': 104, 'sentiment_score': 0.2, 'recommendation_score': 0.6611, 'product_url': 'https://jiji.ng/victoria-island/clothing/luxury-original-t-shirt-for-men-k7rgtzHwNHIw8Z1bVTYPFb2n.html', 'image_url': 'https://pictures-nigeria.jijistatic.net/143867354_MzAwLTQ1MS1jNGRhOTI3NmQx.webp'}, {'rank': 2, 'product_name': 'Classic Original T-Shirt', 'source_platform': 'jiji', 'price': 24000.0, 'currency': 'NGN', 'rating': 0.0, 'review_count': 104, 'sentiment_score': 0.2, 'recommendation_score': 0.6611, 'product_url': 'https://jiji.ng/surulere/clothing/classic-original-t-shirt-pWgd8vmuoBQehbyCTjGNPKVb.html', 'image_url': 'https://pictures-nigeria.jijistatic.net/141717671_MzAwLTMxOC0yNjY5MTIyY2Zh.webp'}, {'rank': 3, 'product_name': 'Luxury Original T-Shirt for Men', 'source_platform': 'jiji', 'price': 24000.0, 'currency': 'NGN', 'rating': 0.0, 'review_count': 104, 'sentiment_score': 0.2, 'recommendation_score': 0.6611, 'product_url': 'https://jiji.ng/ikeja/clothing/luxury-original-t-shirt-for-men-ys19R9TdzvPbMNim1URB2S2Q.html', 'image_url': 'https://pictures-nigeria.jijistatic.net/144463710_MzAwLTI5NS0wMWMxYjJkZWQ3.webp'}, {'rank': 4, 'product_name': 'Classic T-shirt For Men Cc', 'source_platform': 'jiji', 'price': 25000.0, 'currency': 'NGN', 'rating': 0.0, 'review_count': 104, 'sentiment_score': 0.2, 'recommendation_score': 0.6601, 'product_url': 'https://jiji.ng/maryland/clothing/classic-t-shirt-for-men-cc-oGbsKpoVu8Agn4x4oOO9Cd5j.html', 'image_url': 'https://pictures-nigeria.jijistatic.net/186162363_MzAwLTIyNS1mNzI3Nzg2YWU0.webp'}, {'rank': 5, 'product_name': 'Castore Junior Home Jersey Lapis Blue T Shirt', 'source_platform': 'konga', 'price': 15000.0, 'currency': 'NGN', 'rating': 0.0, 'review_count': 0, 'sentiment_score': 0.2, 'recommendation_score': 0.5216, 'product_url': 'https://www.konga.com/product/castore-junior-home-jersey-lapis-blue-t-shirt-6789998', 'image_url': 'https://www-konga-com-res.cloudinary.com/image/upload/f_auto,fl_lossy,dpr_auto,q_auto,w_1080/media/catalog/product//I/P/55707_1752309155.jpg'}, {'rank': 6, 'product_name': 'Pure Cotton Abstract Print T Shirt - Light Airforce', 'source_platform': 'konga', 'price': 15000.0, 'currency': 'NGN', 'rating': 0.0, 'review_count': 0, 'sentiment_score': 0.2, 'recommendation_score': 0.5216, 'product_url': 'https://www.konga.com/product/marks-and-spencer-pure-cotton-abstract-print-t-shirt-light-airforce-6011656', 'image_url': 'https://www-konga-com-res.cloudinary.com/image/upload/f_auto,fl_lossy,dpr_auto,q_auto,w_1080/media/catalog/product//R/V/4811_1675977231.jpg'}, {'rank': 7, 'product_name': 'Revenge Fuxk Vetemens Unisex T Shirt', 'source_platform': 'konga', 'price': 14000.0, 'currency': 'NGN', 'rating': 0.0, 'review_count': 0, 'sentiment_score': 0.2, 'recommendation_score': 0.5216, 'product_url': 'https://www.konga.com/product/revenge-fuxk-vetemens-unisex-t-shirt-5268080', 'image_url': 'https://www-konga-com-res.cloudinary.com/image/upload/f_auto,fl_lossy,dpr_auto,q_auto,w_1080/media/catalog/product//D/F/58617_1622068290.jpg'}, {'rank': 8, 'product_name': '4 In 1 Men Polo T Shirt', 'source_platform': 'konga', 'price': 15500.0, 'currency': 'NGN', 'rating': 0.0, 'review_count': 0, 'sentiment_score': 0.2, 'recommendation_score': 0.5215, 'product_url': 'https://www.konga.com/product/4-in-1-men-polo-t-shirt-5574676', 'image_url': 'https://www-konga-com-res.cloudinary.com/image/upload/f_auto,fl_lossy,dpr_auto,q_auto,w_1080/media/catalog/product//H/Y/174323_1641153909.jpg'}, {'rank': 9, 'product_name': 'Luxury T-Shirt', 'source_platform': 'jiji', 'price': 30000.0, 'currency': 'NGN', 'rating': 0.0, 'review_count': 104, 'sentiment_score': 0.2, 'recommendation_score': 0.6538, 'product_url': 'https://jiji.ng/eko-atlantic/clothing/luxury-t-shirt-nsnl6JmfTuKOH77kYW2s72YQ.html', 'image_url': 'https://pictures-nigeria.jijistatic.net/152023856_MzAwLTI5MS1kM2RkNDU3YjZm.webp'}, {'rank': 10, 'product_name': 'Original BALENCIAGA T-Shirt', 'source_platform': 'jiji', 'price': 30000.0, 'currency': 'NGN', 'rating': 0.0, 'review_count': 104, 'sentiment_score': 0.2, 'recommendation_score': 0.6538, 'product_url': 'https://jiji.ng/ikoyi-obalende/clothing/original-balenciaga-t-shirt-zpM5FrPF3uIbIWwRt4QW8UsT.html', 'image_url': 'https://pictures-nigeria.jijistatic.net/149632118_MzAwLTQwMC1kNzI0YWE5MDJh.webp'}]