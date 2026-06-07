import time
from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase

from database import get_db
from dependencies import require_admin_or_teacher, require_admin
from schemas import ClassGroupResponse, ClassCreateRequest

router = APIRouter()


def _doc_to_class(doc: dict) -> ClassGroupResponse:
    return ClassGroupResponse(
        id=doc["_id"],
        name=doc["name"],
        student_ids=doc.get("student_ids", []),
        teacher_ids=doc.get("teacher_ids", []),
    )


@router.get("/", response_model=list[ClassGroupResponse])
async def list_classes(
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    docs = await db["classes"].find({}).to_list(None)
    return [_doc_to_class(d) for d in docs]


@router.get("/{class_id}", response_model=ClassGroupResponse)
async def get_class(
    class_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    doc = await db["classes"].find_one({"_id": class_id})
    if doc is None:
        raise HTTPException(status_code=404, detail="Class not found")
    return _doc_to_class(doc)


@router.post("/", response_model=ClassGroupResponse, status_code=201)
async def create_class(
    body: ClassCreateRequest,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    class_id = f"c_{int(time.time() * 1000)}"
    doc = {"_id": class_id, "name": body.name, "student_ids": [], "teacher_ids": []}
    await db["classes"].insert_one(doc)
    return _doc_to_class(doc)


@router.delete("/{class_id}", status_code=204)
async def delete_class(
    class_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    cls = await db["classes"].find_one({"_id": class_id})
    if cls is None:
        raise HTTPException(status_code=404, detail="Class not found")

    student_ids = cls.get("student_ids", [])

    # Remove marks for students in this class
    if student_ids:
        await db["marks"].delete_many({"student_id": {"$in": student_ids}})
        await db["students"].delete_many({"_id": {"$in": student_ids}})
        await db["users"].delete_many({"linked_id": {"$in": student_ids}})

    # Remove class from teachers
    await db["teachers"].update_many(
        {"class_ids": class_id}, {"$pull": {"class_ids": class_id}}
    )
    await db["classes"].delete_one({"_id": class_id})
