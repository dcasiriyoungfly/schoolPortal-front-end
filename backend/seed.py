"""
Seed MongoDB with initial data.
Idempotent — skips if data already exists.
"""
from motor.motor_asyncio import AsyncIOMotorDatabase

from auth import hash_password


async def seed_database(db: AsyncIOMotorDatabase) -> None:
    # Idempotency — skip if any users already exist
    if await db["users"].find_one({}):
        print("[seed] Data already present — skipping seed.")
        return

    # ── Admin user ─────────────────────────────────────────────────────────────
    await db["users"].insert_one({
        "_id": "5829A",
        "name": "Administrator",
        "role": "admin",
        "hashed_password": hash_password("admin123"),
        "linked_id": None,
    })

    print("[seed] MongoDB seeded successfully.")
