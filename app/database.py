import os
import asyncio
from dotenv import load_dotenv

load_dotenv()

DB_ENGINE = os.getenv("DB_ENGINE", "mariadb")

_pool = None


async def get_pool():
    global _pool
    if _pool is None:
        _pool = await _create_pool()
    return _pool


async def _create_pool():
    if DB_ENGINE == "postgresql":
        import asyncpg
        return await asyncpg.create_pool(
            host=os.getenv("POSTGRES_HOST", "localhost"),
            port=int(os.getenv("POSTGRES_PORT", 5432)),
            user=os.getenv("POSTGRES_USER", "postgres"),
            password=os.getenv("POSTGRES_PASSWORD", "postgres"),
            database=os.getenv("POSTGRES_DATABASE", "estudo"),
            min_size=int(os.getenv("DB_POOL_MIN", 5)),
            max_size=int(os.getenv("DB_POOL_MAX", 20)),
        )

    if DB_ENGINE == "mariadb":
        import aiomysql
        return await aiomysql.create_pool(
            host=os.getenv("MARIADB_HOST", "localhost"),
            port=int(os.getenv("MARIADB_PORT", 3306)),
            user=os.getenv("MARIADB_USER", "root"),
            password=os.getenv("MARIADB_PASSWORD", "root"),
            db=os.getenv("MARIADB_DATABASE", "estudo"),
            minsize=int(os.getenv("DB_POOL_MIN", 5)),
            maxsize=int(os.getenv("DB_POOL_MAX", 20)),
            autocommit=True,
        )

    raise ValueError(f"DB_ENGINE invalido: {DB_ENGINE}. Use 'mariadb' ou 'postgresql'.")


async def execute(query: str, *params):
    pool = await get_pool()

    if DB_ENGINE == "postgresql":
        async with pool.acquire() as conn:
            rows = await conn.fetch(query, *params)
            return [dict(r) for r in rows]

    if DB_ENGINE == "mariadb":
        async with pool.acquire() as conn:
            async with conn.cursor() as cur:
                await cur.execute(query, params)
                rows = await cur.fetchall()
                if not rows:
                    return []
                colunas = [desc[0] for desc in cur.description]
                return [dict(zip(colunas, row)) for row in rows]

    raise ValueError(f"DB_ENGINE invalido: {DB_ENGINE}")


def ph(n=1):
    return "$1" if DB_ENGINE == "postgresql" else "%s"


def phs(count):
    if DB_ENGINE == "postgresql":
        return ", ".join(f"${i+1}" for i in range(count))
    return ", ".join(["%s"] * count)


async def close():
    global _pool
    if _pool:
        _pool.close()
        await _pool.wait_closed()
        _pool = None
