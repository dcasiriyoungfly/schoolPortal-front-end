from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from database import get_db
from auth import verify_password, create_access_token
from dependencies import get_current_user
from schemas import LoginRequest, TokenResponse

router = APIRouter()


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncIOMotorDatabase = Depends(get_db)):
    doc = await db["users"].find_one({"_id": body.user_id})
    if doc is None or not verify_password(body.password, doc["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user ID or password",
        )
    token = create_access_token(doc["_id"], doc["role"])
    return TokenResponse(
        access_token=token,
        user_id=doc["_id"],
        name=doc["name"],
        role=doc["role"],
        linked_id=doc.get("linked_id"),
    )


@router.get("/me", response_model=TokenResponse)
async def me(current_user: dict = Depends(get_current_user)):
    token = create_access_token(current_user["id"], current_user["role"])
    return TokenResponse(
        access_token=token,
        user_id=current_user["id"],
        name=current_user["name"],
        role=current_user["role"],
        linked_id=current_user.get("linked_id"),
    )
