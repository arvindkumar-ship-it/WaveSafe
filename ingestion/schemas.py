"""
Module 3 — Data Ingestion : Data contract

Every connector, regardless of source (INCOIS / SACHET / manual admin), must
emit records shaped exactly like RawIngestRecord. This is the contract defined
in the spec:
    source, source_id, type, severity, geometry, start_time, end_time,
    raw_json, parsed_fields, ingest_time
"""
from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field, field_validator


class SourceSystem(str, Enum):
    INCOIS = "incois"
    SACHET = "sachet"
    MANUAL_ADMIN = "manual_admin"


class RecordType(str, Enum):
    OCEAN_FORECAST = "ocean_forecast"     # wave/current/wind/tide/water-quality observation
    HAZARD_WARNING = "hazard_warning"      # tsunami/storm surge/cyclone/high wave warning (CAP)
    LOCAL_CLOSURE = "local_closure"        # manual admin no-swim / beach closure


class Severity(str, Enum):
    INFO = "info"
    MINOR = "minor"
    MODERATE = "moderate"
    SEVERE = "severe"
    EXTREME = "extreme"


class GeoJSONGeometry(BaseModel):
    """Minimal GeoJSON geometry envelope — validated further downstream by PostGIS."""
    type: str  # "Point" | "Polygon" | "MultiPolygon"
    coordinates: Any

    @field_validator("type")
    @classmethod
    def _valid_type(cls, v: str) -> str:
        allowed = {"Point", "Polygon", "MultiPolygon"}
        if v not in allowed:
            raise ValueError(f"geometry type must be one of {allowed}, got {v}")
        return v


class RawIngestRecord(BaseModel):
    """
    The unified contract every connector must produce (Module 3 spec,
    'Data contract' section). This is intentionally source-agnostic —
    normalization into the canonical schema happens in Module 4.
    """
    source: SourceSystem
    source_id: str                          # source's own alert/record id, for dedup
    type: RecordType
    severity: Optional[Severity] = None     # None allowed for pure ocean_forecast rows
    geometry: Optional[GeoJSONGeometry] = None
    start_time: Optional[datetime] = None   # valid_from / observation time
    end_time: Optional[datetime] = None     # valid_to (None = still active / not applicable)
    raw_json: dict[str, Any]                # untouched source payload, stored verbatim
    parsed_fields: dict[str, Any] = Field(default_factory=dict)  # source-specific extracted fields
    ingest_time: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    # confidence score (Module 3, step 9): 0.0-1.0, defaults to full trust for official sources
    source_confidence: float = 1.0

    @field_validator("start_time", "end_time", mode="before")
    @classmethod
    def _ensure_utc(cls, v):
        if v is None:
            return v
        if isinstance(v, str):
            v = datetime.fromisoformat(v.replace("Z", "+00:00"))
        if v.tzinfo is None:
            v = v.replace(tzinfo=timezone.utc)
        return v.astimezone(timezone.utc)

    def dedup_key(self) -> str:
        """source + alert_id + valid time window (Module 3, step 8)."""
        start = self.start_time.isoformat() if self.start_time else "none"
        end = self.end_time.isoformat() if self.end_time else "none"
        return f"{self.source.value}:{self.source_id}:{start}:{end}"


class IngestionRunResult(BaseModel):
    """Returned by every connector.fetch() call — used for latency/ops metrics."""
    source: SourceSystem
    records: list[RawIngestRecord]
    fetched_at: datetime
    duration_ms: float
    rejected_count: int = 0
    error: Optional[str] = None
