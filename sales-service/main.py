from fastapi import FastAPI, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware
import schemas
from database import get_db, engine, Base
from models import Sale
import jwt
import requests

SECRET_KEY = "your_secret_key"  # Change this to a strong secret in production
ALGORITHM = "HS256"
PRODUCT_SERVICE_URL = "http://product-service:8001"  # URL of the product service

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"], 
)

def get_current_user_payload(authorization: str = Header(...)):
    try:
        token = authorization.split(" ")[1]
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except Exception as e:
        print(f"Error decoding token: {e}")
        raise HTTPException(status_code=401, detail="Invalid or missing token")

@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)

@app.post("/sales", response_model=schemas.SaleOut)
def create_sale(
    sale: schemas.SaleCreate,
    db: Session = Depends(get_db),
    payload: dict = Depends(get_current_user_payload),
    authorization: str = Header(...)
):
    # Validate quantity
    if sale.quantity <= 0:
        raise HTTPException(status_code=400, detail="Quantity must be greater than zero")
    
    # Check with product service if product exists and has enough stock
    try:       
        response = requests.get(f"{PRODUCT_SERVICE_URL}/products/{sale.product_id}")

        if response.status_code != 200:
            raise HTTPException(status_code=503, detail="Product service unavailable")

        product = response.json()

        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
            
        if product["stock"] < sale.quantity:
            raise HTTPException(status_code=400, detail="Not enough stock available")
        
   
        response = requests.put(
            f"{PRODUCT_SERVICE_URL}/internal/products/{sale.product_id}/purchase",
            json={"quantity": sale.quantity}
        )

        if response.status_code != 200:
            raise HTTPException(status_code=503, detail="Product service unavailable")
        
        # Create the sale
        db_sale = Sale(**sale.dict(), buyer_id=payload["user_id"])
        db.add(db_sale)
        db.commit()
        db.refresh(db_sale)
    

        return db_sale

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error checking product: {str(e)}")