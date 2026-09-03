# Dockerfile - Application image
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    curl \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy virtual environment from base image
COPY --from=mult-price-base:latest /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Don't set these - they'll come from .env or docker-compose
# The .env file has TRANSFORMERS_CACHE=/tmp/huggingface_cache

# Create logs directory
RUN mkdir -p /app/logs

# Copy application code
COPY . .

# Run as root for development (fixes permission issues)
# USER appuser is REMOVED

# Run the application
CMD ["fastapi", "run", "app/main.py", "--host", "0.0.0.0", "--port", "8000"]