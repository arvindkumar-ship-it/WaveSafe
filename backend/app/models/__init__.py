"""Module 2 — models/__init__.py : the file your screenshot was validating
against the live DB. Aggregates all tables (2A-2D) under one Base/metadata
so Alembic autogenerate and `Base.metadata.create_all()` both see everything.

Bug #2 FIX APPLIED: otp.py, tracking.py, safezone.py, emergency_share.py were never
imported here, and (before the app/core/db.py fix) belonged to a separate
declarative_base() registry anyway. Both problems are now fixed — app/core/db.py
re-exports the same Base as app/models/base.py, and the 4 files are aggregated below.
"""
from .base import Base
from .core import User, UserDevice, EmergencyContact
from .geospatial import Beach, SafeZone, Jurisdiction, Hospital, RescuePost
from .forecast_risk import (
    BeachActivityProfile, BeachForecast, HazardAlert, BeachRiskScore,
    TripPlan, TripRiskSnapshot,
)
from .incident import (
    IncidentReport, IncidentRoute, IncidentStatusHistory, NotificationQueue,
    AuditEvent, UserContact, OfflineSyncQueue,
)
from .otp import OTPCode
from .tracking import LiveTrackingSession, LocationPing
from .safezone import SafeZoneGuidance
from .emergency_share import EmergencyShareSession, EmergencyShareTarget

__all__ = [
    "Base",
    "User", "UserDevice", "EmergencyContact",
    "Beach", "SafeZone", "Jurisdiction", "Hospital", "RescuePost",
    "BeachActivityProfile", "BeachForecast", "HazardAlert", "BeachRiskScore",
    "TripPlan", "TripRiskSnapshot",
    "IncidentReport", "IncidentStatusHistory", "IncidentRoute", "NotificationQueue",
    "AuditEvent", "UserContact", "OfflineSyncQueue",
    "OTPCode",
    "LiveTrackingSession", "LocationPing",
    "SafeZoneGuidance",
    "EmergencyShareSession", "EmergencyShareTarget",
]