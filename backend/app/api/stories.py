from uuid import UUID
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.db.database import get_db
from app.models.story import Story
from app.schemas.story import StoryResponse, StoryDetailResponse

router = APIRouter()


@router.get("", response_model=List[StoryResponse], response_model_by_alias=True)
async def list_stories(
    theme: Optional[str] = Query(None, description="徳目テーマでフィルタ"),
    grade: Optional[int] = Query(None, ge=3, le=4, description="学年でフィルタ"),
    is_premium: Optional[bool] = Query(None),
    week: Optional[int] = Query(None, description="週番号"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    """ストーリー一覧取得"""
    query = select(Story).where(Story.is_published == True)

    if theme:
        query = query.where(Story.theme == theme)
    if grade:
        query = query.where(Story.grade_min <= grade, Story.grade_max >= grade)
    if is_premium is not None:
        query = query.where(Story.is_premium == is_premium)
    if week is not None:
        query = query.where(Story.week_number == week)

    query = query.order_by(Story.created_at.desc()).offset(offset).limit(limit)
    result = await db.execute(query)
    stories = result.scalars().all()
    return [StoryResponse.model_validate(s) for s in stories]


@router.get("/weekly/{week_number}", response_model=List[StoryResponse], response_model_by_alias=True)
async def get_weekly_stories(
    week_number: int,
    db: AsyncSession = Depends(get_db),
):
    """週次テーマストーリー取得"""
    result = await db.execute(
        select(Story)
        .where(Story.week_number == week_number, Story.is_published == True)
        .order_by(Story.difficulty)
    )
    stories = result.scalars().all()
    return [StoryResponse.model_validate(s) for s in stories]


@router.get("/{story_id}", response_model=StoryDetailResponse, response_model_by_alias=True)
async def get_story(
    story_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """ストーリー詳細取得（選択肢含む）"""
    result = await db.execute(
        select(Story)
        .options(selectinload(Story.choices))
        .where(Story.id == story_id, Story.is_published == True)
    )
    story = result.scalar_one_or_none()
    if not story:
        raise HTTPException(status_code=404, detail="ストーリーが見つかりません")
    return StoryDetailResponse.model_validate(story)
