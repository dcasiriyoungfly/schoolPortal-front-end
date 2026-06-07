from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase
from datetime import datetime, timezone

from database import get_db
from dependencies import require_admin, require_admin_or_teacher
from schemas import AnalyticsResponse, SubmissionStatusItem, TeacherPassRateResponse
from routers.teachers import compute_pass_rate

router = APIRouter()


@router.get("/submission-status", response_model=list[SubmissionStatusItem])
async def submission_status(
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    teachers = await db["teachers"].find({}).to_list(None)
    result = []
    for t in teachers:
        sub = await db["submissions"].find_one({"_id": t["_id"]})
        result.append(SubmissionStatusItem(
            teacher_id=t["_id"],
            teacher_name=t["name"],
            submitted=sub is not None,
            submitted_at=sub["submitted_at"] if sub else None,
        ))
    return result


@router.post("/submission/{teacher_id}", response_model=SubmissionStatusItem)
async def mark_submitted(
    teacher_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    teacher = await db["teachers"].find_one({"_id": teacher_id})
    if teacher is None:
        raise HTTPException(status_code=404, detail="Teacher not found")

    now = datetime.now(timezone.utc)
    await db["submissions"].update_one(
        {"_id": teacher_id},
        {"$setOnInsert": {"_id": teacher_id, "submitted_at": now}},
        upsert=True,
    )
    sub = await db["submissions"].find_one({"_id": teacher_id})

    return SubmissionStatusItem(
        teacher_id=teacher_id,
        teacher_name=teacher["name"],
        submitted=True,
        submitted_at=sub["submitted_at"],
    )


@router.get("/analytics", response_model=AnalyticsResponse)
async def analytics(
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    teachers = await db["teachers"].find({}).to_list(None)
    items: list[TeacherPassRateResponse] = []

    for t in teachers:
        sub = await db["submissions"].find_one({"_id": t["_id"]})
        pass_rate = await compute_pass_rate(t["_id"], db)
        items.append(TeacherPassRateResponse(
            teacher_id=t["_id"],
            teacher_name=t["name"],
            pass_rate=pass_rate,
            submitted=sub is not None,
        ))

    submitted_items = [i for i in items if i.pass_rate is not None]
    highest = max(submitted_items, key=lambda i: i.pass_rate, default=None)
    avg = (
        round(sum(i.pass_rate for i in submitted_items) / len(submitted_items), 1)
        if submitted_items else None
    )

    return AnalyticsResponse(
        teacher_pass_rates=items,
        highest_performer=highest,
        average_pass_rate=avg,
        submitted_count=len(submitted_items),
        total_teachers=len(teachers),
    )
