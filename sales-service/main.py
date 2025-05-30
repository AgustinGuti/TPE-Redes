from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware
import schemas
from database import get_db, engine, Base
from models import Sale
import jwt
from fastapi import Header

SECRET_KEY = "your_secret_key"  # Change this to a strong secret in production
ALGORITHM = "HS256"


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"], 
)

def get_current_user_role(authorization: str = Header(...)):
    try:
        token = authorization.split(" ")[1]
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload["role"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or missing token")


@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)

@app.post("/sales", response_model=schemas.SaleOut)
def create_sale(
    sale: schemas.SaleCreate,
    db: Session = Depends(get_db),
    role: str = Depends(get_current_user_role)
):
    # Optionally, check role here (e.g., only "customer" can buy)
    db_sale = Sale(**sale.dict())
    db.add(db_sale)
    db.commit()
    db.refresh(db_sale)
    return db_sale
