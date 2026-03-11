
import re


class HelperTransformers:

    
    #Parsing helpers
    def parse_price(self, value) -> float | None:
        """'₦ 125,000' → 125000.0"""
        if not value:
            return None
        cleaned = re.sub(r"[^\d.]", "", str(value).replace(",", ""))
        try:
            return float(cleaned)
        except ValueError:
            return None
    
    
    def parse_float(self,value) -> float | None:
        if not value:
            return None
        cleaned = re.sub(r"[^\d.]", "", str(value))
        try:
            return float(cleaned)
        except ValueError:
            return None
    
    
    def parse_int(self,value) -> int | None:
        if not value:
            return None
        cleaned = re.sub(r"[^\d]", "", str(value))
        try:
            return int(cleaned)
        except ValueError:
            return None
    
    
    def infer_category(self,query: str) -> str:
        query = query.lower()
        if any(k in query for k in ["phone", "iphone", "samsung", "tecno", "infinix"]):
            return "phones"
        if any(k in query for k in ["laptop", "tv", "speaker", "earphone", "camera"]):
            return "electronics"
        if any(k in query for k in ["shirt", "dress", "shoe", "bag", "trouser"]):
            return "fashion"
        return "general"
    
    
    
    
    def clean_text(self,value: str | None) -> str | None:
        if not value:
            return None
        return " ".join(value.split())
    
    
    
    
    def parse_rating(self,rating: str | None) -> float | None:
        if not rating:
            return None
    
        match = re.search(r"(\d+(?:\.\d+)?)", rating)
        return float(match.group(1)) if match else None
    
    
    def parse_review_count(review: str | None) -> int | None:
        if not review:
            return None
    
        match = re.search(r"\((\d+)\)", review)
        return int(match.group(1)) if match else None