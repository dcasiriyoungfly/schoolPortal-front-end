from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase
from datetime import datetime, timezone
import uuid

from database import get_db
from dependencies import require_admin
from schemas import ApplicationSubmitRequest, ApplicationResponse

router = APIRouter()


def _doc_to_response(doc: dict) -> ApplicationResponse:
    return ApplicationResponse(
        id=doc["_id"],
        full_name=doc["full_name"],
        email=doc["email"],
        phone=doc["phone"],
        form_applying_for=doc["form_applying_for"],
        previous_school=doc["previous_school"],
        reason_for_leaving=doc["reason_for_leaving"],
        results_file_name=doc.get("results_file_name"),
        submitted_at=doc["submitted_at"],
        is_reviewed=doc.get("is_reviewed", False),
    )


@router.post("/", response_model=ApplicationResponse, status_code=201)
async def submit_application(
    body: ApplicationSubmitRequest,
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    doc = {
        "_id": str(uuid.uuid4()),
        "full_name": body.full_name,
        "email": body.email,
        "phone": body.phone,
        "form_applying_for": body.form_applying_for,
        "previous_school": body.previous_school,
        "reason_for_leaving": body.reason_for_leaving,
        "results_file_name": body.results_file_name,
        "submitted_at": datetime.now(timezone.utc),
        "is_reviewed": False,
    }
    await db["applications"].insert_one(doc)
    return _doc_to_response(doc)


@router.get("/", response_model=list[ApplicationResponse])
async def list_applications(
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    docs = await db["applications"].find({}).sort("submitted_at", -1).to_list(None)
    return [_doc_to_response(d) for d in docs]


@router.put("/{application_id}/review", response_model=ApplicationResponse)
async def review_application(
    application_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    result = await db["applications"].find_one_and_update(
        {"_id": application_id},
        {"$set": {"is_reviewed": True}},
        return_document=True,
    )
    if result is None:
        raise HTTPException(status_code=404, detail="Application not found")
    return _doc_to_response(result)


@router.delete("/{application_id}", status_code=204)
async def delete_application(
    application_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    _user=Depends(require_admin),
):
    result = await db["applications"].delete_one({"_id": application_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Application not found")
