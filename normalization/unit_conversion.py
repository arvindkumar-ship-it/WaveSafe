"""
Module 4 — Normalization Engine : Unit normalization (step 3)

All internal storage/computation uses SI-ish units consistent with the
Module 2C schema's numeric(8,3) columns:
    wave_height, swell_height  -> meters
    current_speed, wind_speed  -> meters/second
    rainfall                   -> millimeters
    visibility                 -> kilometers
    water_quality              -> index score 0-100 (higher = better), source-normalized
"""
from __future__ import annotations

from typing import Optional


def knots_to_mps(knots: Optional[float]) -> Optional[float]:
    if knots is None:
        return None
    return round(knots * 0.514444, 3)


def kmh_to_mps(kmh: Optional[float]) -> Optional[float]:
    if kmh is None:
        return None
    return round(kmh / 3.6, 3)


def feet_to_meters(feet: Optional[float]) -> Optional[float]:
    if feet is None:
        return None
    return round(feet * 0.3048, 3)


def inches_to_mm(inches: Optional[float]) -> Optional[float]:
    if inches is None:
        return None
    return round(inches * 25.4, 3)


def miles_to_km(miles: Optional[float]) -> Optional[float]:
    if miles is None:
        return None
    return round(miles * 1.60934, 3)


def clamp_water_quality_index(raw_value: Optional[float], source_scale_max: float = 100.0) -> Optional[float]:
    """
    Different sources may report water quality on different scales.
    Rescale to a fixed 0-100 internal index. source_scale_max lets a
    connector declare its native scale (e.g. some indices max at 10).
    """
    if raw_value is None:
        return None
    normalized = (raw_value / source_scale_max) * 100.0
    return round(max(0.0, min(100.0, normalized)), 3)
