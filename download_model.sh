#!/bin/bash
# download_models.sh
set -e

echo "Downloading HuggingFace models..."

# Create cache directory if it doesn't exist
mkdir -p /root/.cache/huggingface

# Download models using Python
python3 << 'EOF'
import os
import sys
from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Set environment variable before importing
os.environ['TRANSFORMERS_CACHE'] = '/root/.cache/huggingface'

models_to_download = [
    # Sentiment analysis model (adjust to your actual model)
    "distilbert-base-uncased-finetuned-sst-2-english",
    # Add any other models your app uses
    # "bert-base-uncased",
    # "cardiffnlp/twitter-roberta-base-sentiment",
]

for model_name in models_to_download:
    try:
        logger.info(f"Downloading {model_name}...")
        # Download tokenizer and model
        tokenizer = AutoTokenizer.from_pretrained(
            model_name,
            cache_dir='/root/.cache/huggingface'
        )
        model = AutoModelForSequenceClassification.from_pretrained(
            model_name,
            cache_dir='/root/.cache/huggingface'
        )
        logger.info(f"✅ Successfully downloaded {model_name}")
    except Exception as e:
        logger.error(f"❌ Failed to download {model_name}: {e}")
        sys.exit(1)

logger.info("All models downloaded successfully!")
EOF

echo "Model download complete!"