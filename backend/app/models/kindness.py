from pydantic import BaseModel
from typing import List
from datetime import datetime

class KindnessRecord(BaseModel):
    record_id: str
    description: str
    person_involved: str | None = None
    context: str | None = None
    recorded_at: datetime

class KindnessRecordResponse(BaseModel):
    recorded: bool
    progress: str
    is_mission_complete: bool
    reward_points: int

class KindnessFinding(BaseModel):
    description: str
    person: str | None = None

class KindnessMap(BaseModel):
    month: str
    total_findings: int
    by_category: dict[str, List[KindnessFinding]]
    message: str

class KindnessMission(BaseModel):
    mission_id: str
    target_count: int = 3
    completed_count: int = 0
    is_completed: bool = False
    created_at: datetime
