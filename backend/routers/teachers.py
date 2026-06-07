import time
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from typing import Optional

from auth import hash_password
from database import get_db
from dependencies import require_admin_or_teacher, require_admin
from schemas import (
    TeacherResponse, TeacherPassRateResponse, TeacherCreateRequest,
    TeacherCreateResponse, TeacherUpdateClassesRequest,
    TeacherUpdateSubjectsRequest, mark_to_response,
)

router = APIRouter()


def _doc_to_teacher(doc: dict) -> TeacherResponse:
    return TeacherResponse(
        id=doc["_id"],
        name=doc["name"],
        subject_ids=doc.get("subject_ids", []),
        class_ids=doc.get("class_ids", []),
    )


async def compute_pass_rate(teacher_id: str, db: AsyncIOMotorDatabase) -> Optional[float]:
    """Returns pass rate (0-100) or None if no marks submitted."""
    teacher = await db["teachers"].find_one({"_id": teacher_id})
    if not teacher:
        return None

    subject_ids = teacher.get("subject_ids", [])
    class_ids = teacher.get("class_ids", [])

    marks = await db["marks"].find({
        "subject_id": {"$in": subject_ids},
        "class_id":   {"$in": class_ids},
    }).to_list(None)

    if not marks:
        return None

    passing = 0
    for m in marks:
        config = await db["mark_configs"].find_one(
            {"subject_id": m["subject_id"], "class_id": m["class_id"]}
        )
        if mark_to_response(m, config).is_passing:
            passing += 1

    return round((passing / len(marks)) * 100, 1)


@router.get("/", response_model=list[TeacherResponse])
async def list_teachers(
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    docs = await db["teachers"].find({}).to_list(None)
    return [_doc_to_teacher(d) for d in docs]


@router.get("/{teacher_id}", response_model=TeacherResponse)
async def get_teacher(
    teacher_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    doc = await db["teachers"].find_one({"_id": teacher_id})
    if doc is None:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return _doc_to_teacher(doc)


@router.get("/{teacher_id}/pass-rate", response_model=TeacherPassRateResponse)
async def get_teacher_pass_rate(
    teacher_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    doc = await db["teachers"].find_one({"_id": teacher_id})
    if doc is None:
        raise HTTPException(status_code=404, detail="Teacher not found")

    sub = await db["submissions"].find_one({"_id": teacher_id})
    pass_rate = await compute_pass_rate(teacher_id, db)

    return TeacherPassRateResponse(
        teacher_id=teacher_id,
        teacher_name=doc["name"],
        pass_rate=pass_rate,
        submitted=sub is not None,
    )


@router.post("/", response_model=TeacherCreateResponse, status_code=201)
async def create_teacher(
    body: TeacherCreateRequest,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    ts = int(time.time() * 1000)
    teacher_id = f"t_{ts}"

    # Auto-generate teacher login ID (S001, S002, ...)
    existing = await db["users"].find(
        {"_id": {"$regex": "^S\\d+$"}}
    ).to_list(None)
    used = {int(u["_id"][1:]) for u in existing}
    n = 1
    while n in used:
        n += 1
    user_id = f"S{str(n).zfill(3)}"

    # Create subjects
    subject_ids: list[str] = []
    if body.subject_names:
        subjects_docs = []
        for i, name in enumerate(body.subject_names):
            sub_id = f"sub_{ts}_{i}"
            subjects_docs.append({"_id": sub_id, "name": name, "teacher_id": teacher_id})
            subject_ids.append(sub_id)
        await db["subjects"].insert_many(subjects_docs)

    # Create teacher document
    await db["teachers"].insert_one({
        "_id": teacher_id,
        "name": body.name,
        "subject_ids": subject_ids,
        "class_ids": body.class_ids,
    })

    # Add teacher to each assigned class
    for class_id in body.class_ids:
        await db["classes"].update_one(
            {"_id": class_id},
            {"$addToSet": {"teacher_ids": teacher_id}},
        )

    # Create login account
    await db["users"].insert_one({
        "_id": user_id,
        "name": body.name,
        "role": "teacher",
        "hashed_password": hash_password(body.password),
        "linked_id": teacher_id,
    })

    teacher_doc = {
        "_id": teacher_id,
        "name": body.name,
        "subject_ids": subject_ids,
        "class_ids": body.class_ids,
    }
    return TeacherCreateResponse(teacher=_doc_to_teacher(teacher_doc), user_id=user_id)


@router.delete("/{teacher_id}", status_code=204)
async def delete_teacher(
    teacher_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    teacher = await db["teachers"].find_one({"_id": teacher_id})
    if teacher is None:
        raise HTTPException(status_code=404, detail="Teacher not found")

    subject_ids = teacher.get("subject_ids", [])

    if subject_ids:
        await db["subjects"].delete_many({"_id": {"$in": subject_ids}})
        await db["marks"].delete_many({"subject_id": {"$in": subject_ids}})

    await db["classes"].update_many(
        {"teacher_ids": teacher_id},
        {"$pull": {"teacher_ids": teacher_id}},
    )
    await db["submissions"].delete_one({"_id": teacher_id})
    await db["users"].delete_one({"linked_id": teacher_id})
    await db["teachers"].delete_one({"_id": teacher_id})


@router.put("/{teacher_id}/classes", response_model=TeacherResponse)
async def update_teacher_classes(
    teacher_id: str,
    body: TeacherUpdateClassesRequest,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    teacher = await db["teachers"].find_one({"_id": teacher_id})
    if teacher is None:
        raise HTTPException(status_code=404, detail="Teacher not found")

    old_ids = set(teacher.get("class_ids", []))
    new_ids = set(body.class_ids)

    for cid in old_ids - new_ids:
        await db["classes"].update_one({"_id": cid}, {"$pull": {"teacher_ids": teacher_id}})
    for cid in new_ids - old_ids:
        await db["classes"].update_one({"_id": cid}, {"$addToSet": {"teacher_ids": teacher_id}})

    await db["teachers"].update_one({"_id": teacher_id}, {"$set": {"class_ids": body.class_ids}})
    doc = await db["teachers"].find_one({"_id": teacher_id})
    return _doc_to_teacher(doc)


@router.put("/{teacher_id}/subjects", response_model=TeacherResponse)
async def update_teacher_subjects(
    teacher_id: str,
    body: TeacherUpdateSubjectsRequest,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    teacher = await db["teachers"].find_one({"_id": teacher_id})
    if teacher is None:
        raise HTTPException(status_code=404, detail="Teacher not found")

    await db["teachers"].update_one(
        {"_id": teacher_id}, {"$set": {"subject_ids": body.subject_ids}}
    )
    # Update each subject's teacher_id
    await db["subjects"].update_many(
        {"_id": {"$in": body.subject_ids}}, {"$set": {"teacher_id": teacher_id}}
    )
    doc = await db["teachers"].find_one({"_id": teacher_id})
    return _doc_to_teacher(doc)
