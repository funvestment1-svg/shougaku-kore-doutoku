from uuid import UUID
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel
from datetime import datetime
from app.db.database import get_db
from app.models.progress import Progress
from app.models.child import Child
from app.security import get_current_user_id

router = APIRouter()


class ProgressResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID
    child_id: UUID
    story_id: UUID | None = None
    action: str
    points_delta: int = 0
    recorded_at: datetime


@router.get("/{child_id}", response_model=List[ProgressResponse], response_model_by_alias=True)
async def get_child_progress(
    child_id: UUID,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
    limit: int = 100,
):
    """子どもの進捗履歴を取得（最新順）"""
    # 子供の所有者確認
    child_result = await db.execute(
        select(Child).where(Child.id == child_id, Child.parent_id == UUID(user_id))
    )
    if not child_result.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="権限がありません")

    result = await db.execute(
        select(Progress)
        .where(Progress.child_id == child_id)
        .order_by(Progress.recorded_at.desc())
        .limit(limit)
    )
    records = result.scalars().all()
    return [ProgressResponse.model_validate(r) for r in records]
