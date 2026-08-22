"""
Module 4 — Normalization Engine : Canonical schema

Exact fields from the spec's "Canonical schema" section:
    alert type, severity, area geometry, validity window, confidence,
    affected activity types, hard override flag, evacuation flag

Plus a parallel canonical shape for ocean_forecast records (wave/current/
wind/tide/water-quality), since Module 3 ingests both hazard warnings and
raw ocean observations and both need one clean internal model before the
Risk Engine (Module 5) touches them.
"""
from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field


class CanonicalAlertType(str, Enum):
    TSUNAMI_WARNING = "tsunami_warning"
    STORM_SURGE_WARNING = "storm_surge_warning"
    CYCLONE_WARNING = "cyclone_warning"
    HIGH_WAVE_WARNING = "high_wave_warning"
    EVACUATION_ORDER = "evacuation_order"
    BEACH_CLOSURE = "beach_closure"
    COAST_GUARD_CLOSURE = "coast_guard_closure"
    OTHER = "other"


# Event types that must force hard_override_flag = True (mirrors Module 5's
# hard-override list and Module 3's sachet_connector._HARD_OVERRIDE_EVENT_TYPES —
# kept as one source of truth here since normalization is where the flag is set).
HARD_OVERRIDE_ALERT_TYPES = {
    CanonicalAlertType.TSUNAMI_WARNING,
    CanonicalAlertType.STORM_SURGE_WARNING,
    CanonicalAlertType.EVACUATION_ORDER,
    CanonicalAlertType.BEACH_CLOSURE,
    CanonicalAlertType.COAST_GUARD_CLOSURE,
}

EVACUATION_ALERT_TYPES = {
    CanonicalAlertType.EVACUATION_ORDER,
    CanonicalAlertType.TSUNAMI_WARNING,
}

ALL_ACTIVITY_TYPES = {"swimming", "surfing", "boating", "beach_walk", "family_outing"}


class CanonicalHazardEvent(BaseModel):
    """Maps 1:1 onto Module 2D's `hazard_alerts` table."""
    source_system: str
    source_alert_id: str
    alert_type: CanonicalAlertType
    severity: str
    title: Optional[str] = None
    description: Optional[str] = None
    geometry: Optional[dict[str, Any]] = None       # GeoJSON, written to hazard_alerts.geom
    issued_at: datetime
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    eta_minutes: Optional[int] = None
    hard_override_flag: bool = False
    evacuation_flag: bool = False
    affected_activity_types: list[str] = Field(default_factory=lambda: sorted(ALL_ACTIVITY_TYPES))
    confidence: float = 1.0
    uncertainty_flags: list[str] = Field(default_factory=list)  # which fields were inferred/missing
    raw_payload: dict[str, Any] = Field(default_factory=dict)


class CanonicalForecastEvent(BaseModel):
    """Maps 1:1 onto Module 2C's `beach_forecasts` table."""
    beach_id: Optional[str] = None  # resolved by nearest-station matching before persistence
    station_source_id: str
    forecast_time: datetime
    wave_height: Optional[float] = None
    current_speed: Optional[float] = None
    wind_speed: Optional[float] = None
    swell_height: Optional[float] = None
    tide_state: Optional[str] = None
    rainfall: Optional[float] = None
    visibility: Optional[float] = None
    water_quality: Optional[float] = None
    source: str = "incois"
    confidence: float = 1.0
    uncertainty_flags: list[str] = Field(default_factory=list)
    raw_payload: dict[str, Any] = Field(default_factory=dict)
