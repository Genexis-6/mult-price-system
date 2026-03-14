from pydantic import BaseModel, ConfigDict



from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime
from typing import List, Optional


class ProductSchemas(BaseModel):
    # Basic product information
    query: str
    product_name: Optional[str] = None
    category: Optional[str] = None
    price: Optional[float] = None
    currency: str = "NGN"
    rating: Optional[float] = None
    review_count: Optional[int] = None
    product_url: Optional[str] = None
    image_url: Optional[str] = None
    reviews_raw: Optional[List[str]] = None
    
    
    # Sentiment and metadata
    sentiment_score: Optional[float] = Field(default=None, ge=0, le=1)  # Assuming 0-1 range
    scraped_at: datetime = Field(default_factory=datetime.utcnow)
    is_available: bool = True
    
    model_config = ConfigDict(
        from_attributes=True,
    )




class ProductSentimentSchemas(BaseModel):
    id: int
    reviews: List[str]

    sentiments: List[str] = []
    score: float = 0.0