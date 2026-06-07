from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import get_pool, close as db_close
from app import queries


@asynccontextmanager
async def lifespan(app: FastAPI):
    await get_pool()
    yield
    await db_close()


app = FastAPI(lifespan=lifespan)


@app.get("/dados")
async def dados():
    rows = await queries.buscar_dados()
    return {"total": len(rows), "dados": rows}


@app.get("/dados-data")
async def dados_data():
    rows = await queries.buscar_por_data()
    return {"total": len(rows), "dados": rows}


@app.get("/dados-disposicao")
async def dados_disposicao():
    rows = await queries.buscar_por_disposicao()
    return {"total": len(rows), "dados": rows}


@app.get("/dados-texto")
async def dados_texto():
    rows = await queries.buscar_texto()
    return {"total": len(rows), "dados": rows}


@app.get("/dados-agregado")
async def dados_agregado():
    rows = await queries.buscar_agregado()
    return {"total": len(rows), "dados": rows}


@app.get("/dados-ordenado")
async def dados_ordenado():
    rows = await queries.buscar_ordenado()
    return {"total": len(rows), "dados": rows}


@app.get("/dados-src")
async def dados_src():
    rows = await queries.buscar_src_dst()
    return {"total": len(rows), "dados": rows}


@app.get("/dados-contagem")
async def dados_contagem():
    rows = await queries.contar_registros()
    return rows


@app.post("/dados-inserir")
async def dados_inserir():
    rows = await queries.inserir_registro()
    return {"status": "ok"}


@app.get("/health")
async def health():
    return {"status": "ok"}
