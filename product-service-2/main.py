from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware

from typing import List

from database import get_db, engine, Base
from models import Product
from schemas import ProductCreate, ProductRead, PurchaseRequest
import jwt
from fastapi import Header, HTTPException

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

def get_current_user_payload(authorization: str = Header(...)):
    try:
        token = authorization.split(" ")[1]
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except Exception as e:
        print(f"Error decoding token: {e}")
        raise HTTPException(status_code=401, detail="Invalid or missing token")

@app.get("/products/{product_id}", response_model=ProductRead)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@app.put("/internal/products/{product_id}/purchase", response_model=ProductRead)
def update_product_stock(product_id: int, purchase: PurchaseRequest, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    product.stock -= purchase.quantity
    db.commit()
    db.refresh(product)
    return product

@app.get("/products", response_model=List[ProductRead])
def get_products(db: Session = Depends(get_db)):
    return [
        ProductRead(id=1, name="Product 1 V2", description="Description 1", price=100, stock=10),
        ProductRead(id=2, name="Product 2 V2", description="Description 2", price=200, stock=20),
    ]

@app.post("/products", response_model=ProductRead)
def create_product(product: ProductCreate, db: Session = Depends(get_db), payload: dict = Depends(get_current_user_payload)):
    print(f"Creating product with payload: {payload}")
    if payload["role"] != "vendor":
        raise HTTPException(status_code=403, detail="Only vendors can create products")

    db_product = Product(**product.dict(), vendor_id = payload["user_id"])

    if db_product.stock < 0:
        raise HTTPException(status_code=400, detail="Stock cannot be negative")
    if db_product.price < 0:
        raise HTTPException(status_code=400, detail="Price cannot be negative")
    if not db_product.name or not db_product.description:
        raise HTTPException(status_code=400, detail="Name and description are required")
    if db.query(Product).filter(Product.name == db_product.name, Product.vendor_id == db_product.vendor_id).first():
        raise HTTPException(status_code=400, detail="Product with this name already exists for this vendor")
    if not db_product.vendor_id:
        raise HTTPException(status_code=400, detail="Vendor ID is required")

    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product
