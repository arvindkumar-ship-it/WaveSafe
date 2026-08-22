import uuid
from typing import Any, Dict, Optional, List
from pydantic import BaseModel


class IngestResponse(BaseModel):
    status: str
    records_ingested: int


class RiskRecomputeRequest(BaseModel):
    beach_id: Optional[uuid.UUID] = None  # None = recompute all active beaches


class RiskRecomputeResponse(BaseModel):
    status: str
    beaches_recomputed: int


class EscalateRequest(BaseModel):
    incident_id: uuid.UUID
    reason: str
    attempt: int


class EscalateResponse(BaseModel):
    incident_id: uuid.UUID
    status: str
    next_targets: List[str]
