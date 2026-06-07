from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


# ── Helpers ───────────────────────────────────────────────────────────────────

def calc_grade(final: float) -> str:
    if final >= 80: return "A"
    if final >= 70: return "B"
    if final >= 60: return "C"
    if final >= 50: return "D"
    return "F"


def calc_percentage_from_entries(entries: list, components: list) -> float:
    if not components:
        return 0.0
    total_max = sum(float(c.get("max_mark", 0)) for c in components)
    if total_max <= 0:
        return 0.0
    comp_map = {c["id"]: float(c.get("max_mark", 0)) for c in components}
    total_marks = sum(
        min(float(e.get("mark", 0)), comp_map.get(e.get("component_id", ""), 0))
        for e in entries
        if e.get("component_id") in comp_map
    )
    return round((total_marks / total_max) * 100, 2)


def mark_to_response(m: dict, config: dict | None = None) -> "MarkResponse":
    config = config or {}
    term_entries = m.get("term_entries", [])
    exam_entries = m.get("exam_entries", [])
    term_comps   = config.get("term_components", [])
    exam_comps   = config.get("exam_components", [])

    term_pct = calc_percentage_from_entries(term_entries, term_comps)
    exam_pct = calc_percentage_from_entries(exam_entries, exam_comps)
    final    = round(term_pct * 0.4 + exam_pct * 0.6, 2)

    return MarkResponse(
        student_id=m["student_id"],
        subject_id=m["subject_id"],
        class_id=m["class_id"],
        term_entries=[MarkEntryItem(component_id=e["component_id"], mark=e["mark"]) for e in term_entries],
        exam_entries=[MarkEntryItem(component_id=e["component_id"], mark=e["mark"]) for e in exam_entries],
        term_percentage=term_pct,
        exam_percentage=exam_pct,
        final_mark=final,
        grade=calc_grade(final),
        is_passing=final >= 50,
    )


# ── Auth ──────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    user_id: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    name: str
    role: str
    linked_id: Optional[str] = None


# ── Teacher ───────────────────────────────────────────────────────────────────

class TeacherResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    subject_ids: list[str] = []
    class_ids: list[str] = []


class TeacherCreateRequest(BaseModel):
    name: str
    password: str
    subject_names: list[str] = []
    class_ids: list[str] = []


class TeacherCreateResponse(BaseModel):
    teacher: TeacherResponse
    user_id: str


class TeacherUpdateClassesRequest(BaseModel):
    class_ids: list[str]


class TeacherUpdateSubjectsRequest(BaseModel):
    subject_ids: list[str]


class TeacherPassRateResponse(BaseModel):
    teacher_id: str
    teacher_name: str
    pass_rate: Optional[float]
    submitted: bool


# ── Subject ───────────────────────────────────────────────────────────────────

class SubjectResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    teacher_id: str


# ── Student ───────────────────────────────────────────────────────────────────

class StudentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    class_id: str


class StudentCreateRequest(BaseModel):
    name: str
    class_id: str


class StudentUpdateRequest(BaseModel):
    name: str


# ── ClassGroup ────────────────────────────────────────────────────────────────

class ClassGroupResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    student_ids: list[str] = []
    teacher_ids: list[str] = []


class ClassCreateRequest(BaseModel):
    name: str


# ── Mark Config ───────────────────────────────────────────────────────────────

class MarkComponent(BaseModel):
    id: str
    name: str
    max_mark: float


class MarkConfigResponse(BaseModel):
    subject_id: str
    class_id: str
    term_components: list[MarkComponent] = []
    exam_components: list[MarkComponent] = []


class MarkConfigUpdateRequest(BaseModel):
    term_components: list[MarkComponent]
    exam_components: list[MarkComponent]


# ── Mark ──────────────────────────────────────────────────────────────────────

class MarkEntryItem(BaseModel):
    component_id: str
    mark: float


class MarkUpsertRequest(BaseModel):
    student_id: str
    subject_id: str
    class_id: str
    term_entries: list[MarkEntryItem] = []
    exam_entries: list[MarkEntryItem] = []


class MarkResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    student_id: str
    subject_id: str
    class_id: str
    term_entries: list[MarkEntryItem] = []
    exam_entries: list[MarkEntryItem] = []
    term_percentage: float = 0.0
    exam_percentage: float = 0.0
    final_mark: float = 0.0
    grade: str = "F"
    is_passing: bool = False


# ── Admin analytics ───────────────────────────────────────────────────────────

class SubmissionStatusItem(BaseModel):
    teacher_id: str
    teacher_name: str
    submitted: bool
    submitted_at: Optional[datetime] = None


class AnalyticsResponse(BaseModel):
    teacher_pass_rates: list[TeacherPassRateResponse]
    highest_performer: Optional[TeacherPassRateResponse] = None
    average_pass_rate: Optional[float] = None
    submitted_count: int
    total_teachers: int


# ── Headmaster report ─────────────────────────────────────────────────────────

class HeadmasterReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    comment: str
    signature: str


class HeadmasterReportUpdateRequest(BaseModel):
    comment: str
    signature: str


# ── Student Application ───────────────────────────────────────────────────────

class ApplicationSubmitRequest(BaseModel):
    full_name: str
    email: str
    phone: str
    form_applying_for: str
    previous_school: str
    reason_for_leaving: str
    results_file_name: Optional[str] = None


class ApplicationResponse(BaseModel):
    id: str
    full_name: str
    email: str
    phone: str
    form_applying_for: str
    previous_school: str
    reason_for_leaving: str
    results_file_name: Optional[str] = None
    submitted_at: datetime
    is_reviewed: bool


# ── Class report (for print/preview) ─────────────────────────────────────────

class StudentMarkEntry(BaseModel):
    subject_id: str
    subject_name: str
    term_percentage: Optional[float] = None
    exam_percentage: Optional[float] = None
    final_mark: Optional[float] = None
    grade: Optional[str] = None
    is_passing: Optional[bool] = None


class StudentReportRow(BaseModel):
    student: StudentResponse
    marks_by_subject: dict[str, StudentMarkEntry]
    average: Optional[float]
    overall_grade: Optional[str]


class ClassReportResponse(BaseModel):
    class_group: ClassGroupResponse
    subjects: list[SubjectResponse]
    students: list[StudentReportRow]
    pass_rate: Optional[float]
    headmaster_comment: str
    headmaster_signature: str
