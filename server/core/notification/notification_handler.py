import os
import requests
from pathlib import Path
from typing import Optional, Dict, Any
from google.oauth2 import service_account
from google.auth.transport.requests import Request
from core.utils.logger import get_logger

logger = get_logger(__name__)

class FirebaseNotificationService:
    """Reusable Firebase Cloud Messaging service"""
    
    _instance = None
    _credentials = None
    _project_id = "mula-becb6"
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialize()
        return cls._instance
    
    def _initialize(self):
        """Initialize the service with service account credentials"""
        self.service_account_path = self._get_service_account_path()
        if self.service_account_path:
            self._load_credentials()
    
    def _get_project_root(self) -> Path:
        """Get the project root directory"""
        # Get the current file's directory: /path/to/project/core/notification/
        current_file = Path(__file__).resolve()
        # Go up 3 levels to reach project root: core/notification -> core -> project root
        project_root = current_file.parent.parent.parent
        return project_root
    
    def _get_service_account_path(self) -> Optional[str]:
        """Get the correct path to the service account file using relative paths"""
        project_root = self._get_project_root()
        
        # Define possible relative paths from project root
        possible_paths = [
            project_root / "keys" / "mula-becb6-firebase-adminsdk-fbsvc-13fc28ccdc.json",
            project_root / "keys" / "firebase-service-account.json",
            project_root / "keys" / "service-account.json",
            project_root / "config" / "firebase-service-account.json",
            project_root / "service-account-key.json",
            Path("keys") / "mula-becb6-firebase-adminsdk-fbsvc-13fc28ccdc.json",
            Path("keys") / "firebase-service-account.json",
        ]
        
        for path in possible_paths:
            if path.exists():
                logger.info(f"Found service account file at: {path}")
                return str(path)
        
        # Also try environment variable
        env_path = os.environ.get('FIREBASE_SERVICE_ACCOUNT_PATH')
        if env_path and Path(env_path).exists():
            logger.info(f"Found service account file from env: {env_path}")
            return env_path
        
        logger.error("Service account file not found in any of the expected locations")
        logger.error(f"Searched in: {[str(p) for p in possible_paths]}")
        return None
    
    def _load_credentials(self):
        """Load service account credentials"""
        try:
            self._credentials = service_account.Credentials.from_service_account_file(
                self.service_account_path,
                scopes=["https://www.googleapis.com/auth/firebase.messaging"]
            )
            logger.info("✅ Firebase credentials loaded successfully")
        except Exception as e:
            logger.error(f"❌ Failed to load credentials: {e}")
            self._credentials = None
    
    def _get_access_token(self) -> Optional[str]:
        """Get a fresh access token"""
        if not self._credentials:
            logger.error("Credentials not available")
            return None
        
        try:
            self._credentials.refresh(Request())
            return self._credentials.token
        except Exception as e:
            logger.error(f"Failed to refresh access token: {e}")
            return None
    
    def send_notification(
        self,
        token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None,
        image_url: Optional[str] = None,
        click_action: Optional[str] = None
    ) -> Dict[str, Any]:
        """Send a push notification to a device"""
        if not self.service_account_path:
            logger.error("Cannot send notification: Service account file not found")
            return {"error": "Service account file not found"}
        
        access_token = self._get_access_token()
        if not access_token:
            logger.error("Cannot send notification: Failed to get access token")
            return {"error": "Failed to get access token"}
        
        url = f"https://fcm.googleapis.com/v1/projects/{self._project_id}/messages:send"
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        # Build message payload
        message = {
            "token": token,
            "notification": {
                "title": title,
                "body": body,
            }
        }
        
        if image_url:
            message["notification"]["image"] = image_url
        
        if data:
            message["data"] = data
        
        if click_action:
            message["android"] = {
                "notification": {
                    "click_action": click_action
                }
            }
            message["apns"] = {
                "payload": {
                    "aps": {
                        "category": click_action
                    }
                }
            }
        
        payload = {"message": message}
        
        try:
            response = requests.post(url, headers=headers, json=payload)
            
            if response.status_code == 200:
                logger.info(f"✅ Push notification sent successfully to {token[:20]}...")
                return response.json()
            else:
                logger.error(f"❌ Failed to send notification: {response.status_code} - {response.text}")
                return {"error": response.text, "status_code": response.status_code}
                
        except Exception as e:
            logger.error(f"❌ Error sending notification: {e}")
            return {"error": str(e)}
    
    def send_task_completed(self, token: str, task_id: str, task_name: str = "") -> Dict[str, Any]:
        """Send a task completed notification"""
        title = "✅ Task Completed"
        body = f"Your task '{task_name}' has been completed successfully!" if task_name else "Your task has been completed successfully!"
        
        return self.send_notification(
            token=token,
            title=title,
            body=body,
            data={
                "task_id": task_id,
                "type": "task_completed",
                "status": "completed"
            },
            click_action="FLUTTER_NOTIFICATION_CLICK"
        )
    
    def send_task_failed(self, token: str, task_id: str, error: str) -> Dict[str, Any]:
        """Send a task failed notification"""
        return self.send_notification(
            token=token,
            title="❌ Task Failed",
            body=f"Task failed: {error[:100]}",
            data={
                "task_id": task_id,
                "type": "task_failed",
                "error": error,
                "status": "failed"
            },
            click_action="FLUTTER_NOTIFICATION_CLICK"
        )
    
    def send_task_progress(self, token: str, task_id: str, progress: int, message: str) -> Dict[str, Any]:
        """Send a task progress update notification"""
        return self.send_notification(
            token=token,
            title=f"Task Progress: {progress}%",
            body=message,
            data={
                "task_id": task_id,
                "type": "task_progress",
                "progress": str(progress),
                "status": "processing"
            }
        )


# Singleton instance
notification_service = FirebaseNotificationService()


# Convenience functions
def send_push(token: str, title: str = "Task Completed ✅", body: str = "Your results are ready"):
    """Legacy function for backward compatibility"""
    return notification_service.send_notification(
        token=token,
        title=title,
        body=body
    )