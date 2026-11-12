from fastapi import FastAPI

app = FastAPI(title="NASC API")


@app.get("/health")
async def health():
    return {"status": "ok"}
