from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from database import get_db
from dependencies import get_current_user, require_admin_or_teacher, require_admin
from schemas import StudentResponse, StudentCreateRequest, StudentUpdateRequest, MarkResponse, mark_to_response

router = APIRouter()


def _doc_to_student(doc: dict) -> StudentResponse:
    return StudentResponse(id=doc["_id"], name=doc["name"], class_id=doc["class_id"])


@router.get("/", response_model=list[StudentResponse])
async def list_students(
    class_id: str | None = None,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    filt = {"class_id": class_id} if class_id else {}
    docs = await db["students"].find(filt).to_list(None)
    return [_doc_to_student(d) for d in docs]


@router.get("/{student_id}", response_model=StudentResponse)
async def get_student(
    student_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] == "student" and current_user.get("linked_id") != student_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    doc = await db["students"].find_one({"_id": student_id})
    if doc is None:
        raise HTTPException(status_code=404, detail="Student not found")
    return _doc_to_student(doc)


@router.put("/{student_id}", response_model=StudentResponse)
async def update_student(
    student_id: str,
    body: StudentUpdateRequest,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    result = await db["students"].update_one(
        {"_id": student_id}, {"$set": {"name": body.name}}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Student not found")
    doc = await db["students"].find_one({"_id": student_id})
    return _doc_to_student(doc)


@router.post("/", response_model=StudentResponse, status_code=201)
async def create_student(
    body: StudentCreateRequest,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    # Auto-generate student ID: lowest free C001, C002, ...
    existing = await db["students"].find(
        {"_id": {"$regex": "^C\\d+$"}}
    ).to_list(None)
    used = {int(s["_id"][1:]) for s in existing}
    n = 1
    while n in used:
        n += 1
    student_id = f"C{str(n).zfill(3)}"

    doc = {"_id": student_id, "name": body.name, "class_id": body.class_id}
    await db["students"].insert_one(doc)

    # Add student to the class
    await db["classes"].update_one(
        {"_id": body.class_id}, {"$addToSet": {"student_ids": student_id}}
    )
    return _doc_to_student(doc)


@router.delete("/{student_id}", status_code=204)
async def delete_student(
    student_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    student = await db["students"].find_one({"_id": student_id})
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")

    await db["marks"].delete_many({"student_id": student_id})
    await db["classes"].update_many(
        {"student_ids": student_id}, {"$pull": {"student_ids": student_id}}
    )
    await db["users"].delete_one({"linked_id": student_id})
    await db["students"].delete_one({"_id": student_id})


@router.get("/{student_id}/marks", response_model=list[MarkResponse])
async def get_student_marks(
    student_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] == "student" and current_user.get("linked_id") != student_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    docs = await db["marks"].find({"student_id": student_id}).to_list(None)
    return [mark_to_response(m) for m in docs]
