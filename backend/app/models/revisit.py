from pydantic import BaseModel
from typing import List
from datetime import datetime

class RevisitStory(BaseModel):
    revisit_id: str
    story_id: str
    title: str
    original_answer: str
    preview: str

class RevisitResult(BaseModel):
    original_choice: str
    current_choice: str
    is_changed: bool
    message: str
