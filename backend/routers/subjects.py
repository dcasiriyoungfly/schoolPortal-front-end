from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase

from database import get_db
from dependencies import get_current_user
from schemas import SubjectResponse

router = APIRouter()


def _doc_to_subject(doc: dict) -> SubjectResponse:
    return SubjectResponse(id=doc["_id"], name=doc["name"], teacher_id=doc["teacher_id"])


@router.get("/", response_model=list[SubjectResponse])
async def list_subjects(
    teacher_id: str | None = None,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(get_current_user),
):
    filt = {"teacher_id": teacher_id} if teacher_id else {}
    docs = await db["subjects"].find(filt).to_list(None)
    return [_doc_to_subject(d) for d in docs]


@router.get("/{subject_id}", response_model=SubjectResponse)
async def get_subject(
    subject_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(get_current_user),
):
    doc = await db["subjects"].find_one({"_id": subject_id})
    if doc is None:
        raise HTTPException(status_code=404, detail="Subject not found")
    return _doc_to_subject(doc)
