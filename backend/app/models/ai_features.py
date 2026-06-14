from pydantic import BaseModel
from typing import List

class ReasonAnalysis(BaseModel):
    user_id: str
    month: str
    headline: str
    observations: List[str]
    improvement_level: str
    parent_message: str

class CreationFeedback(BaseModel):
    user_id: str
    month: str
    creation_count: int
    headline: str
    observations: List[str]
    parent_tip: str
