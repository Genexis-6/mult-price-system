"""
fusion/deduplicator.py
======================
Detects duplicate products across platforms using two signals:

  1. Fuzzy name matching  — RapidFuzz token_sort_ratio
  2. Image hash similarity — pHash via aiohttp (async, non-blocking)

Keeps ALL listings (one row per platform) but assigns a shared
`duplicate_group_id` so the ML layer and UI know which listings
are the same product on different platforms.

Install:
    pip install rapidfuzz imagehash pillow aiohttp
"""

import io
import re
import asyncio
from typing import Optional

import aiohttp
import pandas as pd
import numpy as np
from rapidfuzz import fuzz
from core.utils import get_logger

logger = get_logger(__name__)

NAME_SIMILARITY_THRESHOLD = 85
IMAGE_HASH_THRESHOLD      = 10
COMBINED_MATCH_THRESHOLD  = 70


# ── Name helpers ──────────────────────────────────────────────────────────────

def _clean_name(name: str) -> str:
    if not name:
        return ""
    name = name.lower()
    name = re.sub(r"[^\w\s]", " ", name)
    name = re.sub(r"\b(new|original|official|buy|best|cheap|free|shipping)\b", "", name)
    return re.sub(r"\s+", " ", name).strip()


def name_similarity(a: str, b: str) -> float:
    return fuzz.token_sort_ratio(_clean_name(a), _clean_name(b))


# ── Image hashing (async, non-blocking) ──────────────────────────────────────

async def _fetch_image_async(url: str, client: aiohttp.ClientSession) -> Optional[object]:
    """Async image fetch — does NOT block the event loop."""
    try:
        from PIL import Image
        timeout = aiohttp.ClientTimeout(total=10)
        async with client.get(url, timeout=timeout) as resp:
            if resp.status == 200:
                data = await resp.read()
                return Image.open(io.BytesIO(data)).convert("RGB")
    except Exception:
        pass
    return None


async def _phash_async(url: str, client: aiohttp.ClientSession) -> Optional[str]:
    try:
        import imagehash
        img = await _fetch_image_async(url, client)
        if img:
            return str(imagehash.phash(img))
    except Exception:
        pass
    return None


async def compute_all_hashes(urls: list[Optional[str]]) -> list[Optional[str]]:
    """
    Fetch and hash all images concurrently in one shared aiohttp session.
    Returns a list of hash strings (or None) aligned with input urls.
    """
    async with aiohttp.ClientSession(headers={"User-Agent": "Mozilla/5.0"}) as client:
        tasks = [
            _phash_async(url, client) if (url and pd.notna(url)) else asyncio.sleep(0, result=None)
            for url in urls
        ]
        return list(await asyncio.gather(*tasks))


# ── Hash comparison ───────────────────────────────────────────────────────────

def _hash_distance(h1: Optional[str], h2: Optional[str]) -> Optional[int]:
    if not h1 or not h2:
        return None
    try:
        import imagehash
        return imagehash.hex_to_hash(h1) - imagehash.hex_to_hash(h2)
    except Exception:
        return None


def image_similarity(h1: Optional[str], h2: Optional[str]) -> float:
    dist = _hash_distance(h1, h2)
    if dist is None:
        return 0.0
    return max(0.0, (1 - dist / 20) * 100)


def _combined_score(name_sim: float, img_sim: float) -> float:
    if img_sim == 0:
        return name_sim
    return name_sim * 0.7 + img_sim * 0.3


# ── Main deduplication ────────────────────────────────────────────────────────

async def assign_duplicate_groups(df: pd.DataFrame) -> pd.DataFrame:
    """
    Async version — fetches all image hashes concurrently first,
    then runs the O(n²) comparison synchronously.

    Assigns `duplicate_group_id` and `is_duplicate` columns.
    Same-platform rows are never grouped together.
    """
    if df.empty:
        return df

    df = df.copy()
    df["duplicate_group_id"] = np.nan
    df["is_duplicate"]       = False

    # Fetch all image hashes concurrently (non-blocking)
    logger.info(f"Fetching {len(df)} image hashes concurrently...")
    hashes = await compute_all_hashes(df["image_url"].tolist())
    df["_phash"] = hashes
    logger.info("Image hashes computed ✓")

    # O(n²) comparison — CPU-bound, runs synchronously
    group_id = 0
    indices  = df.index.tolist()
    n        = len(indices)

    for i in range(n):
        for j in range(i + 1, n):
            idx_i, idx_j = indices[i], indices[j]

            # Never group same-platform listings
            if df.at[idx_i, "source_platform"] == df.at[idx_j, "source_platform"]:
                continue

            name_sim = name_similarity(
                df.at[idx_i, "product_name"] or "",
                df.at[idx_j, "product_name"] or "",
            )
            img_sim = image_similarity(df.at[idx_i, "_phash"], df.at[idx_j, "_phash"])
            score   = _combined_score(name_sim, img_sim)

            if score >= COMBINED_MATCH_THRESHOLD:
                ei = df.at[idx_i, "duplicate_group_id"]
                ej = df.at[idx_j, "duplicate_group_id"]

                if pd.isna(ei) and pd.isna(ej):
                    group_id += 1
                    df.at[idx_i, "duplicate_group_id"] = group_id
                    df.at[idx_j, "duplicate_group_id"] = group_id
                elif pd.notna(ei):
                    df.at[idx_j, "duplicate_group_id"] = ei
                else:
                    df.at[idx_i, "duplicate_group_id"] = ej

                df.at[idx_i, "is_duplicate"] = True
                df.at[idx_j, "is_duplicate"] = True

                logger.debug(
                    f"Duplicate (score={score:.1f}): "
                    f"'{df.at[idx_i, 'product_name'][:35]}' [{df.at[idx_i, 'source_platform']}] "
                    f"↔ '{df.at[idx_j, 'product_name'][:35]}' [{df.at[idx_j, 'source_platform']}]"
                )

    df.drop(columns=["_phash"], inplace=True)
    logger.info(f"Deduplication done: {df['is_duplicate'].sum()} duplicates, {group_id} groups")
    return df