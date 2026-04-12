from sqlalchemy import select, update, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timedelta
from typing import List, Optional
from core.store import PriceAlert, PriceHistory
from core.schemas.price_tracking_schemas import CreatePriceAlertSchema
from core.utils.logger import get_logger

logger = get_logger(__name__)

class PriceTrackingQueries:
    def __init__(self, db: AsyncSession):
        self.__session = db
    
    async def create_alert(self, alert_data: CreatePriceAlertSchema) -> PriceAlert:
        """Create a new price alert"""
        logger.info(f"Creating price alert for {alert_data.product_name} at ₦{alert_data.target_price}")
        
        alert = PriceAlert(
            email=alert_data.email,
            product_name=alert_data.product_name,
            target_price=alert_data.target_price,
            status="active",
            notification_sent=False
        )
        self.__session.add(alert)
        await self.__session.commit()
        await self.__session.refresh(alert)
        
        logger.info(f"✅ Price alert created with ID: {alert.id}")
        return alert
    
    async def get_active_alert_by_product(self, email: str, product_name: str) -> Optional[PriceAlert]:
        """Check if an active alert already exists for this product and email"""
        result = await self.__session.execute(
            select(PriceAlert).where(
                and_(
                    PriceAlert.email == email,
                    PriceAlert.product_name.ilike(f"%{product_name}%"),
                    PriceAlert.status == "active",
                    PriceAlert.notification_sent == False
                )
            )
        )
        return result.scalar_one_or_none()
    
    async def get_active_alerts(self) -> List[PriceAlert]:
        """Get all active price alerts that haven't been notified"""
        result = await self.__session.execute(
            select(PriceAlert).where(
                and_(
                    PriceAlert.status == "active",
                    PriceAlert.notification_sent == False
                )
            )
        )
        return result.scalars().all()
    
    async def get_alerts_by_email(self, email: str) -> List[PriceAlert]:
        """Get all alerts for a specific email"""
        result = await self.__session.execute(
            select(PriceAlert).where(PriceAlert.email == email)
        )
        return result.scalars().all()
    
    async def get_alerts_due_for_check(self) -> List[PriceAlert]:
        """Get alerts that are due for check (next_check_at <= now or never checked)"""
        now = datetime.utcnow()
        result = await self.__session.execute(
            select(PriceAlert).where(
                and_(
                    PriceAlert.status == "active",
                    PriceAlert.notification_sent == False,
                    or_(
                        PriceAlert.next_check_at <= now,
                        PriceAlert.next_check_at.is_(None)
                    )
                )
            )
        )
        return result.scalars().all()
    
    async def update_alert_prices(
        self, 
        alert_id: int, 
        best_price: float, 
        best_platform: str,
        best_url: str,
        all_prices: List[dict]
    ):
        """Update alert with current best prices"""
        logger.info(f"Updating alert {alert_id} with best price: ₦{best_price}")
        
        await self.__session.execute(
            update(PriceAlert)
            .where(PriceAlert.id == alert_id)
            .values(
                current_best_price=best_price,
                current_best_platform=best_platform,
                current_best_url=best_url,
                last_checked=datetime.utcnow()
            )
        )
        
        for price_data in all_prices:
            history = PriceHistory(
                alert_id=alert_id,
                platform=price_data['platform'],
                price=price_data['price'],
                product_url=price_data.get('url', ''),
                product_name=price_data.get('product_name', '')
            )
            self.__session.add(history)
        
        await self.__session.commit()
        logger.info(f"✅ Updated alert {alert_id} with price history")

    async def update_alert_check_schedule(self, alert_id: int, hours: int = 24, minutes: int = 0, seconds: int = 0):
        """Update the alert's next check schedule"""
        next_check = datetime.utcnow() + timedelta(hours=hours, minutes=minutes, seconds=seconds)
        await self.__session.execute(
            update(PriceAlert)
            .where(PriceAlert.id == alert_id)
            .values(
                last_checked_at=datetime.utcnow(),
                next_check_at=next_check,
                updated_at=datetime.utcnow()
            )
        )
        await self.__session.commit()
        logger.info(f"📅 Alert {alert_id} scheduled for next check at {next_check}")
        
    async def mark_alert_triggered(self, alert_id: int):
        """Mark alert as triggered and notification sent"""
        await self.__session.execute(
            update(PriceAlert)
            .where(PriceAlert.id == alert_id)
            .values(
                status="triggered",
                notification_sent=True,
                updated_at=datetime.utcnow()
            )
        )
        await self.__session.commit()
        logger.info(f"✅ Alert {alert_id} marked as triggered")
    
    async def cancel_alert(self, alert_id: int) -> bool:
        """Cancel a price alert"""
        logger.info(f"Cancelling alert {alert_id}")
        
        result = await self.__session.execute(
            update(PriceAlert)
            .where(PriceAlert.id == alert_id)
            .values(status="cancelled", updated_at=datetime.utcnow())
        )
        await self.__session.commit()
        
        return result.rowcount > 0
    
    async def get_alert_by_id(self, alert_id: int) -> Optional[PriceAlert]:
        """Get alert by ID"""
        result = await self.__session.execute(
            select(PriceAlert).where(PriceAlert.id == alert_id)
        )
        return result.scalar_one_or_none()
    
    async def update_alert_target_price(self, alert_id: int, new_target_price: float):
        """Update an alert's target price"""
        await self.__session.execute(
            update(PriceAlert)
            .where(PriceAlert.id == alert_id)
            .values(
                target_price=new_target_price,
                updated_at=datetime.utcnow()
            )
        )
        await self.__session.commit()
        logger.info(f"Updated alert {alert_id} target price to ₦{new_target_price:,.0f}")