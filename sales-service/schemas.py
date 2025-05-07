from pydantic import BaseModel

class SaleCreate(BaseModel):
    product_id: int
    quantity: int
    buyer_id: int

class SaleOut(SaleCreate):
    id: int

    class Config:
        from_attributes = True
