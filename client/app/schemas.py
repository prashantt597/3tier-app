from pydantic import BaseModel, constr, validator
from datetime import datetime

class UserBase(BaseModel):
    username: constr(min_length=3, max_length=50)

    @validator("username")
    def username_alphanumeric(cls, v):
        if not v.replace("_", "").isalnum():
            raise ValueError("Username must be alphanumeric or include underscores")
        return v

class UserCreate(UserBase):
    password: constr(min_length=8, max_length=128)

    @validator("password")
    def password_complexity(cls, v):
        if not (any(c.isupper() for c in v) and
                any(c.islower() for c in v) and
                any(c.isdigit() for c in v) and
                any(c in "!@#$%^&*()-_=+" for c in v)):
            raise ValueError("Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character")
        return v

class User(UserBase):
    id: int
    created_at: datetime
    updated_at: datetime | None

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str