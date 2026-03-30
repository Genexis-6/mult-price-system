# app/websocket/manager.py
import asyncio
import json
from fastapi import WebSocket
from typing import Dict
import logging

from core.redis import get_redis
from core.utils import get_logger

logger = get_logger(__name__)

class ConnectionManager:
    """Manages WebSocket connections and Redis subscriptions"""
    
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.pubsub = None
        self.listen_task = None
    
    async def init_redis(self):
        """Initialize Redis connection"""
        self.redis_client = await get_redis()
        self.pubsub = self.redis_client.pubsub()
        logger.info("WebSocket manager Redis initialized")
    
    async def close_redis(self):
        """Close Redis connection"""
        if self.pubsub:
            await self.pubsub.close()
        logger.info("WebSocket manager Redis closed")
    
    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket
        logger.info(f"Client {client_id} connected. Total: {len(self.active_connections)}")
        
        # Start Redis listener if not already running
        if not self.listen_task:
            self.listen_task = asyncio.create_task(self._listen_to_redis())
    
    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]
            logger.info(f"Client {client_id} disconnected. Total: {len(self.active_connections)}")
        
        # Stop Redis listener if no more connections
        if len(self.active_connections) == 0 and self.listen_task:
            self.listen_task.cancel()
            self.listen_task = None
    
    async def _listen_to_redis(self):
        """Listen for Redis messages and forward to WebSocket clients"""
        try:
            await self.pubsub.subscribe("jobs:*")
            logger.info("Redis listener started")
            
            async for message in self.pubsub.listen():
                if message['type'] == 'message':
                    channel = message['channel']
                    data = json.loads(message['data'])
                    job_id = channel.split(':')[1]
                    
                    if job_id in self.active_connections:
                        try:
                            await self.active_connections[job_id].send_text(
                                json.dumps(data)
                            )
                            logger.debug(f"Forwarded to {job_id}: {data['status']}")
                        except Exception as e:
                            logger.error(f"Failed to send to {job_id}: {e}")
                            
        except asyncio.CancelledError:
            logger.info("Redis listener cancelled")
        except Exception as e:
            logger.error(f"Redis listener error: {e}")
    
    async def publish_update(self, job_id: str, update: dict):
        """Publish update to Redis channel"""
        redis_client = await get_redis()
        await redis_client.publish(
            f"jobs:{job_id}",
            json.dumps(update)
        )

# Global instance
manager = ConnectionManager()