from pydantic import BaseModel

class UserCreateSchema(BaseModel):
    name: str
    password: str
    email: str
    is_vendor: bool = False

class UserLoginSchema(BaseModel):
    email: str
    password: str
