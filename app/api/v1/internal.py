"""Module 25 — internal endpoints. Never exposed to end users; guarded by shared-secret header,
not user JWT. Assumes app.core.security.verify_internal_key exists (Header check)."""
from fastapi import APIRouter, Depends, Body
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.security import verify_internal_key
from app.schemas.internal import (
    IngestResponse, RiskRecomputeRequest, RiskRecomputeResponse, EscalateRequest, EscalateResponse,
)
from app.services import internal_service as svc

router = APIRouter(prefix="/internal", tags=["internal"], dependencies=[Depends(verify_internal_key)])


@router.post("/ingest/incois", response_model=IngestResponse)
def ingest_incois(raw: dict = Body(...), db: Session = Depends(get_db)):
    count = svc.handle_incois(db, raw)
    return IngestResponse(status="ingested", records_ingested=count)


@router.post("/ingest/sachet", response_model=IngestResponse)
def ingest_sachet(raw: dict = Body(...), db: Session = Depends(get_db)):
    count = svc.handle_sachet(db, raw)
    return IngestResponse(status="ingested", records_ingested=count)


@router.post("/recompute/risk", response_model=RiskRecomputeResponse)
def recompute_risk(payload: RiskRecomputeRequest, db: Session = Depends(get_db)):
    count = svc.handle_recompute(db, payload.beach_id)
    return RiskRecomputeResponse(status="recomputed", beaches_recomputed=count)


#@router.post("/router/escalate", response_model=EscalateResponse)
# def router_escalate(payload: EscalateRequest, db: Session = Depends(get_db)):
#     next_targets = svc.handle_escalate(db, payload.incident_id, payload.reason, payload.attempt)
#     return EscalateResponse(incident_id=payload.incident_id, status="escalated", next_targets=next_targets)
