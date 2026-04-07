import asyncio
import json
from fastapi import WebSocket, WebSocketDisconnect
from typing import Dict
from core.redis import get_redis
from core.utils import get_logger

logger = get_logger(__name__)

class ConnectionManager:
    """Manages WebSocket connections and Redis subscriptions"""
    
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.redis_client = None
        self.pubsub = None
        self.listen_task = None
    
    async def init_redis(self):
        """Initialize Redis connection"""
        try:
            self.redis_client = await get_redis()
            self.pubsub = self.redis_client.pubsub()
            logger.info("WebSocket manager Redis initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Redis: {e}")
    
    async def connect(self, websocket: WebSocket, client_id: str):
        """Accept WebSocket connection and subscribe to Redis channel"""
        await websocket.accept()
        self.active_connections[client_id] = websocket
        logger.info(f"Client {client_id} connected. Total: {len(self.active_connections)}")
        
        # Subscribe to Redis channel for this job
        if self.redis_client and self.pubsub:
            await self._subscribe_to_job(client_id)
        
        # Start Redis listener if not already running
        if not self.listen_task or self.listen_task.done():
            self.listen_task = asyncio.create_task(self._listen_to_redis())
    
    async def _subscribe_to_job(self, job_id: str):
        """Subscribe to Redis channel for a specific job"""
        try:
            channel = f"jobs:{job_id}"
            await self.pubsub.subscribe(channel)
            logger.info(f"Subscribed to {channel}")
        except Exception as e:
            logger.error(f"Failed to subscribe to jobs:{job_id}: {e}")
    
    def disconnect(self, client_id: str):
        """Remove client and unsubscribe from Redis channel"""
        if client_id in self.active_connections:
            del self.active_connections[client_id]
            logger.info(f"Client {client_id} disconnected. Total: {len(self.active_connections)}")
        
        # Unsubscribe from Redis channel
        if self.pubsub:
            asyncio.create_task(self.pubsub.unsubscribe(f"jobs:{client_id}"))
    
    async def _listen_to_redis(self):
        """Listen for Redis messages and forward to WebSocket clients"""
        try:
            logger.info("Redis listener started")
            
            async for message in self.pubsub.listen():
                logger.debug(f"Raw Redis message: {message}")
                
                if message['type'] == 'message':
                    try:
                        # Get channel name
                        channel = message['channel']
                        if isinstance(channel, bytes):
                            channel = channel.decode('utf-8')
                        
                        # Get message data
                        data = message['data']
                        if isinstance(data, bytes):
                            data = data.decode('utf-8')
                        
                        # Parse JSON
                        if isinstance(data, str):
                            data = json.loads(data)
                        
                        # Extract job_id from channel name (format: "jobs:{job_id}")
                        job_id = channel.split(':')[1]
                        
                        logger.info(f"📨 Redis message on {channel} for job {job_id}: {data.get('progress', '?')}%")
                        
                        # Forward to WebSocket client if connected
                        if job_id in self.active_connections:
                            try:
                                await self.active_connections[job_id].send_text(
                                    json.dumps(data)
                                )
                                logger.info(f"✅ Forwarded to WebSocket client {job_id}")
                            except Exception as e:
                                logger.error(f"Failed to send to {job_id}: {e}")
                        else:
                            logger.warning(f"No active WebSocket for job: {job_id}")
                            
                    except json.JSONDecodeError as e:
                        logger.error(f"Failed to parse JSON: {e}")
                    except Exception as e:
                        logger.error(f"Error processing Redis message: {e}")
                            
        except asyncio.CancelledError:
            logger.info("Redis listener cancelled")
        except Exception as e:
            logger.error(f"Redis listener error: {e}")

# Global instance
manager = ConnectionManager()

async def init_websocket_manager():
    await manager.init_redis()