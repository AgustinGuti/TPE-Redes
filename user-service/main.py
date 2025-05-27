from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware

from database import get_db, engine, Base
from models import User
import hashlib
from schemas import UserCreateSchema
from schemas import UserLoginSchema

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"], 
)

@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)

@app.post("/users")
def register_user(user: UserCreateSchema, db: Session = Depends(get_db)):
    hashed_password = hashlib.md5(user.password.encode()).hexdigest()
    db_user = User(name=user.name, password=hashed_password, email=user.email, role="vendor" if user.is_vendor else "customer")
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.get("/users")
def get_users(db: Session = Depends(get_db)):
    users = [User(id=1, password="hashed", name="Alice", role="testrole", email="alice@example.com"),
              User(id=2, password="hashed", name="Bob", role="testrole", email="bob@example.com")]
    return users

@app.post("/users/login")
def login_user(user: UserLoginSchema, db: Session = Depends(get_db)):
    hashed_password = hashlib.md5(user.password.encode()).hexdigest()
    db_user = db.query(User).filter(User.email == user.email, User.password == hashed_password).first()
    if db_user:
        return {"access_token": "dummy_token", "role": db_user.role}  # TODO see JWT? Kong. Role will be in JWT
    else:
        raise HTTPException(status_code=400, detail="Invalid credentials")
