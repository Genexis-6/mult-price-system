from typing import List, Dict, Any
from app.store import ProductSchemas, KongaQueries
from app.store import db_session_manager

async def load_konga(products: List[Dict[str, Any]]) -> int:
    if not products:
        return 0
    
    rows = [ProductSchemas(**p) for p in products]
    
    async with db_session_manager.session() as session: 
        konga_queries = KongaQueries(session)
        result = await konga_queries.save_bulk_data(rows)
        
    return result.get("inserted", 0)