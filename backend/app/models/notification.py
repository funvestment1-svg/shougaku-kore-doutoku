import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.base import Base


class Notification(Base):
    """プッシュ通知ログ"""
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(200), nullable=False)
    body = Column(Text, nullable=False)
    notification_type = Column(String(50), nullable=False)  # daily_reminder / report_ready / achievement
    is_sent = Column(Boolean, default=False)
    is_read = Column(Boolean, default=False)
    sent_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="notifications")
