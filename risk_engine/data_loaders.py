"""Module 5 — Risk Engine: data loaders (steps 1-3).
ASSUMPTION (same as Module 3/4): ORM classes from app.models, session from
app.db.get_session — swap imports if your names differ."""
from __future__ import annotations
from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy import select

from app.core.db import get_session  # ASSUMPTION
from app.models import (  # ASSUMPTION
    Beach, BeachActivityProfile, BeachForecast, HazardAlert,
)

from .features import FeatureWindow, coverage_gap, tide_state_to_risk

TREND_WINDOW_HOURS = 24
HISTORY_DAYS_FOR_IQR = 30


def load_beach(session, beach_id: str) -> Optional[Beach]:
    return session.get(Beach, beach_id)


def load_activity_profile(session, beach_id: str, activity_type: str) -> Optional[BeachActivityProfile]:
    stmt = select(BeachActivityProfile).where(
        BeachActivityProfile.beach_id == beach_id,
        BeachActivityProfile.activity_type == activity_type,
        BeachActivityProfile.active.is_(True),
    )
    return session.execute(stmt).scalar_one_or_none()


def load_latest_forecast(session, beach_id: str) -> Optional[BeachForecast]:
    stmt = (
        select(BeachForecast)
        .where(BeachForecast.beach_id == beach_id)
        .order_by(BeachForecast.forecast_time.desc())
        .limit(1)
    )
    return session.execute(stmt).scalar_one_or_none()


def load_trend_forecast(session, beach_id: str, hours_ago: int) -> Optional[BeachForecast]:
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours_ago)
    stmt = (
        select(BeachForecast)
        .where(BeachForecast.beach_id == beach_id, BeachForecast.forecast_time <= cutoff)
        .order_by(BeachForecast.forecast_time.desc())
        .limit(1)
    )
    return session.execute(stmt).scalar_one_or_none()


def load_active_hazard_alerts(session, beach_id: str) -> list[HazardAlert]:
    """Alerts whose geometry intersects the beach and are currently valid."""
    from geoalchemy2.functions import ST_Intersects
    now = datetime.now(timezone.utc)
    stmt = (
        select(HazardAlert, Beach.geom)
        .join(Beach, Beach.id == beach_id)
        .where(
            HazardAlert.status == "active",
            HazardAlert.valid_from <= now,
            (HazardAlert.valid_to.is_(None)) | (HazardAlert.valid_to >= now),
            ST_Intersects(HazardAlert.geom, Beach.geom),
        )
    )
    rows = session.execute(stmt).all()
    return [r[0] for r in rows]


def build_feature_window(session, beach_id: str) -> FeatureWindow:
    """Trailing history for robust median/IQR normalization."""
    cutoff = datetime.now(timezone.utc) - timedelta(days=HISTORY_DAYS_FOR_IQR)
    stmt = (
        select(BeachForecast)
        .where(BeachForecast.beach_id == beach_id, BeachForecast.forecast_time >= cutoff)
    )
    fw = FeatureWindow()
    for row in session.execute(stmt).scalars():
        fw.add({
            "wave_height": row.wave_height,
            "current_speed": row.current_speed,
            "wind_speed": row.wind_speed,
            "swell_height": row.swell_height,
            "water_quality": row.water_quality,
            "rainfall": row.rainfall,
            "tide_risk": tide_state_to_risk(row.tide_state),
            "coverage_gap": 0.0,  # coverage isn't forecast-driven; excluded from history stats
        })
    return fw


def extract_current_features(forecast: BeachForecast, beach: Beach, now: Optional[datetime] = None) -> dict:
    now = now or datetime.now(timezone.utc)
    return {
        "wave_height": forecast.wave_height,
        "current_speed": forecast.current_speed,
        "wind_speed": forecast.wind_speed,
        "swell_height": forecast.swell_height,
        "water_quality": forecast.water_quality,
        "rainfall": forecast.rainfall,
        "tide_risk": tide_state_to_risk(forecast.tide_state),
        "coverage_gap": coverage_gap(beach.has_lifeguard, now.hour),
    }
