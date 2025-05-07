from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware
import schemas
from database import get_db, engine, Base
from models import Sale

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

@app.post("/sales", response_model=schemas.SaleOut)
def create_sale(sale: schemas.SaleCreate, db: Session = Depends(get_db)):
    db_sale = Sale(**sale.dict())
    db.add(db_sale)
    db.commit()
    db.refresh(db_sale)
    return db_sale
