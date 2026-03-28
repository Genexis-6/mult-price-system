from typing import List, Dict, Any
from core.store import ProductSchemas, JumiaQueries
from core.store import db_session_manager

async def load_jumia(products: List[Dict[str, Any]]) -> int:
    if not products:
        return 0
    
    rows = [ProductSchemas(**p) for p in products]
    
    async with db_session_manager.session() as session: 
        jumia_query = JumiaQueries(session)
        result = await jumia_query.save_bulk_data(rows)
        
    return result.get("inserted", 0)