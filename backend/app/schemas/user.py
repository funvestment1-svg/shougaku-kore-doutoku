from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, EmailStr, ConfigDict
from pydantic.alias_generators import to_camel


class UserCreate(BaseModel):
    email: EmailStr
    name: str
    password: str


class UserUpdate(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    name: Optional[str] = None
    fcm_token: Optional[str] = None


class UserResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID
    email: str
    name: str
    is_active: bool
    created_at: datetime
