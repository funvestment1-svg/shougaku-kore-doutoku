from pydantic import BaseModel, EmailStr, ConfigDict
from pydantic.alias_generators import to_camel


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str


class FirebaseLoginRequest(BaseModel):
    firebase_token: str  # Firebase IDトークン


class TokenResponse(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    access_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds
