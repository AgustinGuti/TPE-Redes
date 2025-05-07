from fastapi import FastAPI

app = FastAPI()

@app.get("/sales")
def get_sales():
    return [{"id": 1, "user_id": 1, "product_id": 2}]
