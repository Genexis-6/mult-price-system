import asyncio
import redis.asyncio as redis

async def test_connection():
    try:
        # Try different connection approaches
        print("Test 1: Basic connection")
        r = redis.Redis(
            host='localhost',
            port=6379,
            decode_responses=True,
            socket_connect_timeout=3
        )
        result = await r.ping()
        print(f"✅ Basic connection: {result}")
        await r.aclose()
        
    except Exception as e:
        print(f"❌ Basic connection failed: {e}")
    
    try:
        print("\nTest 2: Connection with socket path")
        r = redis.Redis(
            unix_socket_path='/var/run/redis/redis.sock',  # Try this if exists
            decode_responses=True
        )
        result = await r.ping()
        print(f"✅ Socket connection: {result}")
        await r.aclose()
    except Exception as e:
        print(f"❌ Socket connection failed: {e}")
    
    try:
        print("\nTest 3: Connection with explicit db")
        r = redis.from_url(
            'redis://localhost:6379/0',
            decode_responses=True,
            socket_connect_timeout=3
        )
        result = await r.ping()
        print(f"✅ URL connection: {result}")
        await r.close()
    except Exception as e:
        print(f"❌ URL connection failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_connection())