import asyncio
import time
from typing import List, Type
from sqlalchemy.ext.asyncio import AsyncSession
from core.store import ProductSentimentSchemas, db_session_manager
import os
from core.utils import get_logger
from transformers import pipeline, logging as hf_logging
from core.store import JijiQueries, JumiaQueries, KongaQueries
from core.config import settings


settings.TOKENIZERS_PARALLELISM
settings.HF_HUB_OFFLINE

hf_logging.set_verbosity_error()

logger = get_logger(__name__)

LABEL_MAP = {"negative": "NEGATIVE", "neutral": "NEUTRAL", "positive": "POSITIVE"}


_classifier = None
sem = asyncio.Semaphore(1)

def get_classifier():
    global _classifier
    if _classifier is None:
        logger.info("Loading sentiment model...")
        _classifier = pipeline(
            task="sentiment-analysis",
            model="cardiffnlp/twitter-roberta-base-sentiment-latest",
            local_files_only=True,
            truncation=True,
            max_length=512,
        )
        logger.info("Sentiment model loaded")
    return _classifier




async def score_sentiment(QueryClass):
    source = QueryClass.__name__
    pipeline_start = time.perf_counter()
    logger.info(f"[{source}] starting sentiment pipeline")
    async with db_session_manager.session() as session:
        query = QueryClass(session)
        # --- DB fetch ---
        logger.debug(f"[{source}] fetching products from DB")
        products = await query.get_products()
        if not products:
            logger.warning(f"[{source}] no products found, skipping")
            return
        logger.info(f"[{source}] fetched {len(products)} products")
        # --- Review collection ---
        all_reviews, product_map = [], []
        for i, product in enumerate(products):
            for review in product.reviews:
                if review and review.strip():
                    all_reviews.append(review)
                    product_map.append(i)
        if not all_reviews:
            logger.warning(f"[{source}] no non-empty reviews found across {len(products)} products")
            return
        logger.info(f"[{source}] collected {len(all_reviews)} reviews across {len(products)} products")
        # --- Inference ---
        logger.info(f"[{source}] running inference on {len(all_reviews)} reviews (batch_size=32)")
        inference_start = time.perf_counter()
        async with sem:
            loop = asyncio.get_event_loop()
            results = await loop.run_in_executor(
                None, lambda: get_classifier()(all_reviews, batch_size=32)
            )
        inference_elapsed = time.perf_counter() - inference_start
        logger.info(f"[{source}] inference complete in {inference_elapsed:.2f}s")
        # --- Label distribution (useful for spotting model drift) ---
        label_counts = {"POSITIVE": 0, "NEUTRAL": 0, "NEGATIVE": 0}
        for idx, res in enumerate(results):
            sentiment = LABEL_MAP.get(res["label"].lower(), res["label"].upper())
            label_counts[sentiment] = label_counts.get(sentiment, 0) + 1
            products[product_map[idx]].sentiments.append(sentiment)
        logger.debug(
            f"[{source}] label distribution — "
            f"POS={label_counts['POSITIVE']} "
            f"NEU={label_counts['NEUTRAL']} "
            f"NEG={label_counts['NEGATIVE']}"
        )
        # --- Scoring ---
        for product in products:
            score(product, source)
        # --- DB writes ---
        logger.info(f"[{source}] persisting scores for {len(products)} products")
        saved, failed = 0, 0
        for prd in products:
            try:
                await query.add_sentiment_score(prd)
                saved += 1
                logger.debug(f"[{source}] saved score for product id={prd.id} score={prd.score}")
            except Exception as e:
                failed += 1
                logger.error(f"[{source}] failed to save score for product id={prd.id}: {e}")
        pipeline_elapsed = time.perf_counter() - pipeline_start
        logger.info(
            f"[{source}] pipeline complete — "
            f"saved={saved} failed={failed} "
            f"elapsed={pipeline_elapsed:.2f}s"
        )
        
        
        
def score(product: ProductSentimentSchemas, source: str = "unknown") -> ProductSentimentSchemas:
    sem = product.sentiments
    if not sem:
        logger.debug(f"[{source}] product id={product.id} has no sentiments, score=0.0")
        product.score = 0.0
        return product
    raw = sum(1 if s == "POSITIVE" else -1 if s == "NEGATIVE" else 0 for s in sem)
    product.score = round(raw / len(sem), 2)
    logger.debug(
        f"[{source}] product id={product.id} → score={product.score} "
        f"({len(sem)} reviews)"
    )
    return product




async def run_sentiment():
    logger.info("run_sentiment started for all sources")
    start = time.perf_counter()
    tasks = [
        asyncio.create_task(score_sentiment(JumiaQueries)),
        asyncio.create_task(score_sentiment(KongaQueries)),
        asyncio.create_task(score_sentiment(JijiQueries)),
    ]
    await asyncio.gather(*tasks, return_exceptions=True)
    logger.info(f"run_sentiment finished in {time.perf_counter() - start:.2f}s")