from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class QuizSessionCreate(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    story_id: UUID
    child_id: UUID


class QuizAnswerCreate(BaseModel):
    question_text: str
    selected_choice_id: Optional[UUID] = None
    selected_choice_text: Optional[str] = None


class QuizSessionComplete(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    chosen_choice_id: UUID
    time_spent_seconds: int
    reflection_text: Optional[str] = None


class QuizSessionResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID
    child_id: UUID
    story_id: Optional[UUID]
    points_earned: int
    time_spent_seconds: int
    is_completed: bool
    started_at: datetime
    completed_at: Optional[datetime]


class QuizCompleteResponse(BaseModel):
    """クイズ完了レスポンス — セッション情報 + 子どもの更新済みスタッツ"""

    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    # セッション情報
    session_id: UUID
    story_id: Optional[UUID]
    points_earned: int
    time_spent_seconds: int
    is_completed: bool
    completed_at: Optional[datetime]

    # 子どもの更新後スタッツ
    new_level: int
    new_total_points: int

    # 徳目スコア変化量 (正: 上昇, 負: 下降)
    score_deltas: dict
