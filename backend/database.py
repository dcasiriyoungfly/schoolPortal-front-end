"""
MongoDB connection using Motor (async driver).
Collections used:
  users, teachers, subjects, students, classes,
  marks, submissions, headmaster_report
"""
import os
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

load_dotenv()

MONGO_URL = os.getenv("MONGO_URL", "mongodb://localhost:27017")
DB_NAME   = os.getenv("DB_NAME",   "school_portal")

_client: AsyncIOMotorClient | None = None
_db:     AsyncIOMotorDatabase | None = None


async def connect_db() -> None:
    global _client, _db
    _client = AsyncIOMotorClient(MONGO_URL)
    _db = _client[DB_NAME]
    # Quick connectivity check
    await _client.admin.command("ping")
    print(f"[db] Connected to MongoDB: {MONGO_URL} / {DB_NAME}")


async def close_db() -> None:
    if _client:
        _client.close()
        print("[db] MongoDB connection closed.")


def get_db() -> AsyncIOMotorDatabase:
    """FastAPI dependency — returns the active database instance."""
    return _db
