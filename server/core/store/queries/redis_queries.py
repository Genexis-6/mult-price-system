import json
import uuid
from redis.asyncio import Redis
from core.utils.logger import get_logger

logger = get_logger(__name__)


class RedisQuery:
    
    def __init__(self, redis: Redis):
        self.re = redis
    
    async def create_index(self):
        exists = await self.index_exists()

        if exists:
            logger.debug("Index already exists")
            return

        await self.re.execute_command(
            "FT.CREATE", "idx:search",
            "ON", "HASH",
            "PREFIX", "1", "search:",
            "SCHEMA",
            "query", "TEXT"
        )

        logger.debug("Index created")
        
    async def index_exists(self, index_name="idx:search"):
        try:
            await self.re.execute_command("FT.INFO", index_name)
            return True
        except Exception:
            return False
    
    async def store_result(self, query: str, data: list):
        key = f"search:{uuid.uuid4()}"
    
        pipe = self.re.pipeline()
        
        pipe.hset(
            key,
            mapping={
                "query": query.lower(),
                "data": json.dumps(data)
            },
        )
        pipe.expire(key, 172800)
    
        await pipe.execute()
    
        return key
        
    async def fuzzy_search(self, query: str, limit=5):
        """
        Search for similar queries using RediSearch
        Supports partial matching and typo tolerance
        """
        query = query.lower().strip()
        
        if not query:
            return [0]
        
        # Try different search strategies in order
        search_strategies = [
            f"{query}*",  # Prefix search (fastest)
            f"*{query}*",  # Contains search (slower but more flexible)
        ]
        
        # Add word-by-word fuzzy search if query has multiple words
        words = query.split()
        if len(words) > 1:
            # Match any of the words with fuzzy
            fuzzy_terms = [f"{word}~" for word in words]
            search_strategies.insert(0, " ".join(fuzzy_terms))
            
            # Match exact phrase
            search_strategies.insert(0, f'"{query}"')
        
        # Try each strategy until we find results
        for search_query in search_strategies:
            try:
                logger.debug(f"Trying search query: {search_query}")
                results = await self.re.execute_command(
                    "FT.SEARCH",
                    "idx:search",
                    search_query,
                    "LIMIT", "0", str(limit)
                )
                
                if results and results[0] > 0:
                    logger.debug(f"Found {results[0]} results with query: {search_query}")
                    return results
                    
            except Exception as e:
                logger.debug(f"Search strategy '{search_query}' failed: {e}")
                continue
        
        # If all strategies fail, try a simple scan as last resort
        logger.debug("All search strategies failed, trying simple scan")
        return await self.fallback_search(query, limit)
    
    async def fallback_search(self, query: str, limit=5):
        """Fallback to simple SCAN when RediSearch queries fail"""
        results = []
        cursor = 0
        
        while len(results) < limit:
            cursor, keys = await self.re.scan(cursor, match="search:*", count=100)
            
            for key in keys:
                if len(results) >= limit:
                    break
                    
                data = await self.re.hgetall(key)
                if data and query in data.get("query", "").lower():
                    # Format to match RediSearch output format
                    results.append(key)
                    results.append(["query", data["query"], "data", data["data"]])
            
            if cursor == 0:
                break
        
        # Format results like RediSearch would
        if results:
            return [len(results)//2] + results
        return [0]
    
    def parse_results(self, results):
        if not results or results[0] == 0:
            return None

        parsed = []
        
        # Results format: [count, key1, [field, value, field, value], key2, [...]]
        for i in range(1, len(results), 2):
            fields = results[i + 1]
            # Convert flat array to dict
            data_dict = {}
            for j in range(0, len(fields), 2):
                data_dict[fields[j]] = fields[j + 1]

            parsed.append({
                "query": data_dict.get("query", ""),
                "data": json.loads(data_dict.get("data", "[]"))
            })

        return parsed