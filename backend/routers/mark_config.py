from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from database import get_db
from dependencies import require_admin_or_teacher
from schemas import MarkConfigResponse, MarkConfigUpdateRequest, MarkComponent

router = APIRouter()


@router.get("/{subject_id}/{class_id}", response_model=MarkConfigResponse)
async def get_mark_config(
    subject_id: str,
    class_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    doc = await db["mark_configs"].find_one({"subject_id": subject_id, "class_id": class_id})
    if doc is None:
        return MarkConfigResponse(subject_id=subject_id, class_id=class_id)
    return MarkConfigResponse(
        subject_id=doc["subject_id"],
        class_id=doc["class_id"],
        term_components=[MarkComponent(**c) for c in doc.get("term_components", [])],
        exam_components=[MarkComponent(**c) for c in doc.get("exam_components", [])],
    )


@router.put("/{subject_id}/{class_id}", response_model=MarkConfigResponse)
async def update_mark_config(
    subject_id: str,
    class_id: str,
    body: MarkConfigUpdateRequest,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    await db["mark_configs"].update_one(
        {"subject_id": subject_id, "class_id": class_id},
        {"$set": {
            "subject_id": subject_id,
            "class_id": class_id,
            "term_components": [c.model_dump() for c in body.term_components],
            "exam_components": [c.model_dump() for c in body.exam_components],
        }},
        upsert=True,
    )
    return MarkConfigResponse(
        subject_id=subject_id,
        class_id=class_id,
        term_components=body.term_components,
        exam_components=body.exam_components,
    )
