import random
import uuid
from app.database import execute, ph, phs


async def buscar_dados():
    return await execute("SELECT * FROM registers LIMIT 500")


async def buscar_por_data():
    return await execute(
        "SELECT * FROM registers "
        "WHERE calldate BETWEEN '2024-08-01' AND '2025-06-01' "
        "ORDER BY calldate DESC LIMIT 500"
    )


async def buscar_por_disposicao():
    return await execute(
        "SELECT * FROM registers "
        "WHERE disposition = 'ANSWERED' "
        "ORDER BY calldate DESC LIMIT 500"
    )


async def buscar_texto():
    return await execute(
        f"SELECT * FROM registers "
        f"WHERE lastdata LIKE {ph(1)} LIMIT 100",
        "%gateway%",
    )


async def buscar_agregado():
    return await execute(
        "SELECT disposition, COUNT(*) as total, "
        "AVG(duration) as avg_duration, "
        "SUM(billsec) as total_billsec "
        "FROM registers GROUP BY disposition "
        "ORDER BY total DESC"
    )


async def buscar_ordenado():
    return await execute(
        "SELECT * FROM registers "
        "ORDER BY duration DESC LIMIT 500"
    )


async def buscar_src_dst():
    return await execute(
        "SELECT src, COUNT(*) as calls, "
        "SUM(billsec) as total_seconds "
        "FROM registers "
        "WHERE src != '' AND duration > 10 "
        "GROUP BY src ORDER BY calls DESC LIMIT 50"
    )


async def contar_registros():
    result = await execute("SELECT COUNT(*) as total FROM registers")
    return result


async def inserir_registro():
    uid = uuid.uuid4().hex[:32]
    src = str(random.randint(1000, 9999))
    dst = str(random.randint(10000000, 99999999))
    dur = random.randint(1, 3600)
    bil = random.randint(0, dur)
    disp = random.choice(["ANSWERED", "NO ANSWER", "BUSY", "FAILED"])
    seq = random.randint(1, 999999)
    placeholders = phs(8)
    return await execute(
        f"INSERT INTO registers "
        f"(calldate, answer, src, dst, duration, billsec, disposition, uniqueid, linkedid, sequence) "
        f"VALUES (NOW(), NOW(), {placeholders})",
        src, dst, dur, bil, disp, uid, uid, seq,
    )
