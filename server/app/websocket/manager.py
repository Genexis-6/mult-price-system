import asyncio
import json
from fastapi import WebSocket
from typing import Dict
from core.redis import get_redis
from core.utils import get_logger

logger = get_logger(__name__)

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.redis_client = None
        self.pubsub = None
        self.listen_task = None
    
    async def init_redis(self):
        try:
            self.redis_client = await get_redis()
            self.pubsub = self.redis_client.pubsub()
            logger.info("WebSocket manager Redis initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Redis: {e}")
    
    async def connect(self, websocket: WebSocket, client_id: str, channel_type: str = "jobs"):
        """Connect client and subscribe to appropriate channel"""
        await websocket.accept()
        self.active_connections[client_id] = websocket
        logger.info(f"Client {client_id} connected (type: {channel_type}). Total: {len(self.active_connections)}")
        
        if self.redis_client and self.pubsub:
            await self._subscribe_to_channel(client_id, channel_type)
        
        if not self.listen_task or self.listen_task.done():
            self.listen_task = asyncio.create_task(self._listen_to_redis())
    
    async def _subscribe_to_channel(self, client_id: str, channel_type: str):
        """Subscribe to appropriate channel based on type"""
        try:
            if channel_type == "jobs":
                channel = f"jobs:{client_id}"
            elif channel_type == "price_alerts":
                channel = f"price_alerts:{client_id}"
            else:
                channel = f"jobs:{client_id}"
            
            await self.pubsub.subscribe(channel)
            logger.info(f"Subscribed to {channel}")
        except Exception as e:
            logger.error(f"Failed to subscribe to channel for {client_id}: {e}")
    
    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]
            logger.info(f"Client {client_id} disconnected. Total: {len(self.active_connections)}")
        
        if self.pubsub:
            asyncio.create_task(self.pubsub.unsubscribe(f"jobs:{client_id}"))
            asyncio.create_task(self.pubsub.unsubscribe(f"price_alerts:{client_id}"))
        
        if len(self.active_connections) == 0 and self.listen_task:
            self.listen_task.cancel()
            self.listen_task = None
    
    async def _listen_to_redis(self):
        try:
            logger.info("Redis listener started")
            async for message in self.pubsub.listen():
                if message['type'] == 'message':
                    try:
                        channel = message['channel']
                        if isinstance(channel, bytes):
                            channel = channel.decode('utf-8')
                        
                        data = message['data']
                        if isinstance(data, bytes):
                            data = data.decode('utf-8')
                        
                        if isinstance(data, str):
                            data = json.loads(data)
                        
                        # Extract client_id from channel (format: "type:client_id")
                        parts = channel.split(':')
                        if len(parts) >= 2:
                            client_id = parts[1]
                            
                            if client_id in self.active_connections:
                                try:
                                    await self.active_connections[client_id].send_text(
                                        json.dumps(data)
                                    )
                                    logger.debug(f"Forwarded to {client_id}: {data.get('type', 'unknown')}")
                                except Exception as e:
                                    logger.error(f"Failed to send to {client_id}: {e}")
                        else:
                            logger.warning(f"Invalid channel format: {channel}")
                                
                    except Exception as e:
                        logger.error(f"Error processing Redis message: {e}")
                            
        except asyncio.CancelledError:
            logger.info("Redis listener cancelled")
        except Exception as e:
            logger.error(f"Redis listener error: {e}")

manager = ConnectionManager()

async def init_websocket_manager():
    await manager.init_redis()