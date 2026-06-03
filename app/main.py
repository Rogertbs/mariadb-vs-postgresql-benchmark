from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import get_pool, close as db_close
from app.queries import buscar_dados


@asynccontextmanager
async def lifespan(app: FastAPI):
    await get_pool()
    yield
    await db_close()


app = FastAPI(lifespan=lifespan)


@app.get("/dados")
async def dados():
    rows = await buscar_dados()
    return {"total": len(rows), "dados": rows}


@app.get("/health")
async def health():
    return {"status": "ok"}
