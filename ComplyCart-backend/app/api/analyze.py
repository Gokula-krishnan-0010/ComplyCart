from fastapi import APIRouter, Depends, Query, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List

from app.db import get_db
from app.models.models import AnalysisRecord
from app.services.analysis_service import analyze_product_url
from app.services.scraper_service import ScrapeBlockedError, ScrapeTimeoutError
from app.services.field_extraction_service import ExtractionError

router = APIRouter(prefix="/api/v1", tags=["analysis"])
router_root = APIRouter(tags=["analysis_root"])


class AnalyzeUrlRequest(BaseModel):
    url: str
    force_refresh: bool = False


@router.post("/analyze/url")
@router_root.post("/analyze/url", include_in_schema=False)
async def analyze_url(request: AnalyzeUrlRequest, db: Session = Depends(get_db)):
    try:
        result = await analyze_product_url(db, request.url, request.force_refresh)
    except ScrapeBlockedError as e:
        return JSONResponse(
            status_code=403,
            content={"error_code": "SCRAPE_BLOCKED", "detail": str(e)}
        )
    except ScrapeTimeoutError as e:
        return JSONResponse(
            status_code=504,
            content={"error_code": "SCRAPE_TIMEOUT", "detail": str(e)}
        )
    except ExtractionError as e:
        return JSONResponse(
            status_code=500,
            content={"error_code": "EXTRACTION_FAILED", "detail": str(e)}
        )

    # Re-map fields array to match Flutter widget expectations: {name, is_found, note, extracted_value}
    fields_mapped = []
    for f in result.get("fields", []):
        fields_mapped.append({
            "name": f.get("field_name"),
            "is_found": f.get("is_found"),
            "extracted_value": f.get("extracted_value"),
            "note": f.get("violated_clause")
        })

    return {
        "product_name": result.get("product_name"),
        "compliance_score": result.get("compliance_score"),
        "score": result.get("compliance_score"),
        "status": result.get("status"),
        "cached": result.get("cached", False),
        "extraction_method": result.get("extraction_method"),
        "fields": fields_mapped
    }


@router.get("/analyses")
@router_root.get("/analyses", include_in_schema=False)
def list_analyses(limit: int = Query(10, ge=1), db: Session = Depends(get_db)):
    records = (
        db.query(AnalysisRecord)
        .order_by(AnalysisRecord.timestamp.desc())
        .limit(limit)
        .all()
    )
    return [
        {
            "id": rec.id,
            "product_name": rec.product_name,
            "compliance_score": rec.compliance_score,
            "status": rec.status,
            "timestamp": rec.timestamp.isoformat() if rec.timestamp else None,
            "normalized_url": rec.normalized_url or rec.url
        }
        for rec in records
    ]


@router.get("/analyses/stats")
@router_root.get("/analyses/stats", include_in_schema=False)
def get_stats(db: Session = Depends(get_db)):
    all_records = db.query(AnalysisRecord.status).all()
    total = len(all_records)
    compliant = sum(1 for (status,) in all_records if status and status.lower() == "compliant")
    non_compliant = sum(1 for (status,) in all_records if status and "non" in status.lower())

    return {
        "total": total,
        "compliant": compliant,
        "non_compliant": non_compliant
    }


@router.get("/analyses/{id}")
@router_root.get("/analyses/{id}", include_in_schema=False)
def get_analysis_detail(id: int, db: Session = Depends(get_db)):
    record = db.query(AnalysisRecord).filter(AnalysisRecord.id == id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Analysis record not found")
        
    fields_mapped = []
    for f in (record.fields_evaluation or []):
        fields_mapped.append({
            "name": f.get("field_name") or f.get("name"),
            "is_found": f.get("is_found"),
            "extracted_value": f.get("extracted_value"),
            "note": f.get("violated_clause") or f.get("note")
        })
        
    return {
        "id": record.id,
        "product_name": record.product_name,
        "url": record.url,
        "compliance_score": record.compliance_score,
        "score": record.compliance_score,
        "status": record.status,
        "extraction_method": record.extraction_method,
        "scraped_via": record.scraped_via,
        "timestamp": record.timestamp.isoformat() if record.timestamp else None,
        "fields": fields_mapped
    }
