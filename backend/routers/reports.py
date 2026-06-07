from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase

from database import get_db
from dependencies import require_admin, require_admin_or_teacher
from schemas import (
    HeadmasterReportResponse, HeadmasterReportUpdateRequest,
    ClassReportResponse, ClassGroupResponse, SubjectResponse,
    StudentResponse, StudentReportRow, StudentMarkEntry,
    calc_grade, calc_percentage_from_entries,
)

router = APIRouter()


@router.get("/headmaster", response_model=HeadmasterReportResponse)
async def get_headmaster_report(
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    doc = await db["headmaster_report"].find_one({"_id": "singleton"})
    if doc is None:
        raise HTTPException(status_code=404, detail="Report config not found")
    return HeadmasterReportResponse(comment=doc["comment"], signature=doc["signature"])


@router.put("/headmaster", response_model=HeadmasterReportResponse)
async def update_headmaster_report(
    body: HeadmasterReportUpdateRequest,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    await db["headmaster_report"].update_one(
        {"_id": "singleton"},
        {"$set": {"comment": body.comment, "signature": body.signature}},
    )
    doc = await db["headmaster_report"].find_one({"_id": "singleton"})
    return HeadmasterReportResponse(comment=doc["comment"], signature=doc["signature"])


@router.get("/class/{class_id}", response_model=ClassReportResponse)
async def get_class_report(
    class_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin_or_teacher),
):
    cg = await db["classes"].find_one({"_id": class_id})
    if cg is None:
        raise HTTPException(status_code=404, detail="Class not found")

    student_ids = cg.get("student_ids", [])
    teacher_ids = cg.get("teacher_ids", [])

    subjects_docs = await db["subjects"].find(
        {"teacher_id": {"$in": teacher_ids}}
    ).to_list(None)
    subject_ids = [s["_id"] for s in subjects_docs]

    marks_docs = await db["marks"].find({
        "class_id":   class_id,
        "student_id": {"$in": student_ids},
        "subject_id": {"$in": subject_ids},
    }).to_list(None)
    mark_index = {(m["student_id"], m["subject_id"]): m for m in marks_docs}

    # Fetch all configs for subjects in this class
    configs = {}
    for sid in subject_ids:
        c = await db["mark_configs"].find_one({"subject_id": sid, "class_id": class_id})
        configs[sid] = c

    students_docs = await db["students"].find(
        {"_id": {"$in": student_ids}}
    ).to_list(None)

    student_rows: list[StudentReportRow] = []
    passing_count = 0
    total_mark_count = 0

    for student in students_docs:
        marks_by_subject: dict[str, StudentMarkEntry] = {}
        student_finals: list[float] = []

        for subject in subjects_docs:
            mark = mark_index.get((student["_id"], subject["_id"]))
            config = configs.get(subject["_id"])
            if mark and config:
                term_pct = calc_percentage_from_entries(
                    mark.get("term_entries", []),
                    config.get("term_components", []),
                )
                exam_pct = calc_percentage_from_entries(
                    mark.get("exam_entries", []),
                    config.get("exam_components", []),
                )
                final    = round(term_pct * 0.4 + exam_pct * 0.6, 2)
                grade    = calc_grade(final)
                is_pass  = final >= 50
                entry = StudentMarkEntry(
                    subject_id=subject["_id"],
                    subject_name=subject["name"],
                    term_percentage=term_pct,
                    exam_percentage=exam_pct,
                    final_mark=final,
                    grade=grade,
                    is_passing=is_pass,
                )
                student_finals.append(final)
                if is_pass:
                    passing_count += 1
                total_mark_count += 1
            else:
                entry = StudentMarkEntry(
                    subject_id=subject["_id"],
                    subject_name=subject["name"],
                )
            marks_by_subject[subject["_id"]] = entry

        avg = round(sum(student_finals) / len(student_finals), 1) if student_finals else None
        student_rows.append(StudentReportRow(
            student=StudentResponse(
                id=student["_id"],
                name=student["name"],
                class_id=student["class_id"],
            ),
            marks_by_subject=marks_by_subject,
            average=avg,
            overall_grade=calc_grade(avg) if avg is not None else None,
        ))

    pass_rate = (
        round((passing_count / total_mark_count) * 100, 1)
        if total_mark_count > 0 else None
    )

    hm = await db["headmaster_report"].find_one({"_id": "singleton"})

    return ClassReportResponse(
        class_group=ClassGroupResponse(
            id=cg["_id"],
            name=cg["name"],
            student_ids=student_ids,
            teacher_ids=teacher_ids,
        ),
        subjects=[
            SubjectResponse(id=s["_id"], name=s["name"], teacher_id=s["teacher_id"])
            for s in subjects_docs
        ],
        students=student_rows,
        pass_rate=pass_rate,
        headmaster_comment=hm["comment"] if hm else "",
        headmaster_signature=hm["signature"] if hm else "",
    )
