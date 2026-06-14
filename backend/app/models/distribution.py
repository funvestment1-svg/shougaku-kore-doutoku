from pydantic import BaseModel
from typing import List
from datetime import datetime

class DistributionOption(BaseModel):
    option: str
    text: str
    count: int
    percentage: float
    color: str

class DistributionResponse(BaseModel):
    story_id: str
    title: str | None = None
    options: List[DistributionOption]
    total_responses: int
    last_updated: datetime | None = None

class AnswerStatistics(BaseModel):
    story_id: str
    option_a_count: int = 0
    option_b_count: int = 0
    option_c_count: int = 0
    option_d_count: int = 0
    total_responses: int = 0
