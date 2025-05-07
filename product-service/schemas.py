from pydantic import BaseModel

class ProductCreate(BaseModel):
    name: str
    vendor_id: int
    price: float
    description: str
    stock: int

class ProductRead(ProductCreate):
    id: int

    class Config:
        from_attributes = True
