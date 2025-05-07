from sqlalchemy import Column, Integer, String, ForeignKey
from database import Base

class Sale(Base):
    __tablename__ = "sales"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, index=True)
    quantity = Column(Integer)
    buyer_id = Column(Integer)
