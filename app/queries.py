from app.database import execute


async def buscar_dados():
    rows = await execute("SELECT * FROM registers LIMIT 500")
    return rows
