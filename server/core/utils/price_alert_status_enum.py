import enum


class PriceAlertStatus(enum.Enum):
    ACTIVE = "active"
    TRIGGERED = "triggered"
    EXPIRED = "expired"
    CANCELLED = "cancelled"