from datetime import datetime
from typing import Optional, Dict, Any
from uuid import UUID
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class MonthlyReportResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID
    child_id: UUID
    year: int
    month: int
    stories_completed: int
    total_study_minutes: int
    total_points_earned: int

    # 徳目スコア
    kindness_score: float
    honesty_score: float
    responsibility_score: float
    courage_score: float
    respect_score: float
    cooperation_score: float

    # AIコメント
    highlight_comment: Optional[str]
    growth_comment: Optional[str]
    advice_comment: Optional[str]
    parent_message: Optional[str]

    theme_breakdown: Optional[Dict[str, Any]]
    generated_at: datetime
