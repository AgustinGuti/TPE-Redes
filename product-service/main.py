from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware

from typing import List

from database import get_db, engine, Base
from models import Product
from schemas import ProductCreate, ProductRead
import jwt

SECRET_KEY = "your_secret_key"  # Use the same key as your user service
ALGORITHM = "HS256"

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

def get_current_user_role(authorization: str = Header(...)):
try:
    token = authorization.split(" ")[1]
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    return payload["role"]
except Exception:
    raise HTTPException(status_code=401, detail="Invalid or missing token")


@app.get("/products", response_model=List[ProductRead])
def get_products(db: Session = Depends(get_db)):
    return db.query(Product).all()

@app.post("/products", response_model=ProductRead)
def create_product(product: ProductCreate, db: Session = Depends(get_db), role: str = Depends(get_current_user_role)):
    if role != "vendor":
        raise HTTPException(status_code=403, detail="Only vendors can create products")
    db_product = Product(**product.dict())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product
