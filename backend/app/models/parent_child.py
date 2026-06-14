from pydantic import BaseModel
from typing import List
from datetime import datetime

class ParentChildComparison(BaseModel):
    story_id: str
    story_title: str
    child_choice_letter: str
    child_choice_text: str
    parent_choice_letter: str
    parent_choice_text: str
    guidance: str
    answered_at: datetime

class ParentAnswerResponse(BaseModel):
    parent_choice: str
    child_choice: str | None = None
    is_both_answered: bool
    guidance: str | None = None
