from pydantic import BaseModel

class ProductCreate(BaseModel):
    name: str
    price: float
    description: str
    stock: int

class ProductRead(ProductCreate):
    id: int

    class Config:
        from_attributes = True

class PurchaseRequest(BaseModel):
    quantity: int

    class Config:
        schema_extra = {
            "example": {
                "quantity": 1
            }
        }