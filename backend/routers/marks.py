from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase

from database import get_db
from dependencies import require_admin_or_teacher
from schemas import MarkUpsertRequest, MarkResponse, mark_to_response

router = APIRouter()


async def _get_configs_for_marks(marks_docs: list, db) -> dict:
    keys = {(m["subject_id"], m["class_id"]) for m in marks_docs}
    configs = {}
    for (sid, cid) in keys:
        c = await db["mark_configs"].find_one({"subject_id": sid, "class_id": cid})
        configs[(sid, cid)] = c
    return configs


@router.get("/", response_model=list[MarkResponse])
async def list_marks(
    student_id: str | None = None,
    subject_id: str | None = None,
    class_id: str | None = None,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    filt = {}
    if student_id:
        filt["student_id"] = student_id
    if subject_id:
        filt["subject_id"] = subject_id
    if class_id:
        filt["class_id"] = class_id
    docs = await db["marks"].find(filt).to_list(None)
    configs = await _get_configs_for_marks(docs, db)
    return [mark_to_response(m, configs.get((m["subject_id"], m["class_id"]))) for m in docs]


@router.post("/", response_model=MarkResponse)
async def upsert_mark(
    body: MarkUpsertRequest,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    if not await db["students"].find_one({"_id": body.student_id}):
        raise HTTPException(status_code=404, detail="Student not found")
    if not await db["subjects"].find_one({"_id": body.subject_id}):
        raise HTTPException(status_code=404, detail="Subject not found")
    if not await db["classes"].find_one({"_id": body.class_id}):
        raise HTTPException(status_code=404, detail="Class not found")

    filt = {
        "student_id": body.student_id,
        "subject_id": body.subject_id,
        "class_id":   body.class_id,
    }
    update = {"$set": {
        "term_entries": [e.model_dump() for e in body.term_entries],
        "exam_entries": [e.model_dump() for e in body.exam_entries],
    }}
    await db["marks"].update_one(filt, update, upsert=True)

    doc    = await db["marks"].find_one(filt)
    config = await db["mark_configs"].find_one({"subject_id": body.subject_id, "class_id": body.class_id})
    return mark_to_response(doc, config)
