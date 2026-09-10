"""
Module 3 — Data Ingestion : INCOIS connector

Pulls ocean forecast / observational data (wave height, current speed, wind,
swell, tide, water quality) per beach/station and emits RawIngestRecord items
of type RecordType.OCEAN_FORECAST.

NOTE ON THE ACTUAL INCOIS API SHAPE:
INCOIS exposes several distinct services (wave/ocean state forecast, tsunami
early warning, water quality) rather than one uniform endpoint. The exact
field names below (`wave_ht`, `curr_spd`, etc.) are placeholders standing in
for whatever INCOIS's real response schema uses — I do not have your actual
API contract/credentials to verify field names against. Before this goes to
staging, swap `_parse()`'s field mapping to match a real captured INCOIS
response payload. Everything else (retry, dedup, storage, rejection) is
correct and source-shape-independent.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

import httpx

from .base_connector import BaseConnector, ConnectorError
from .config import settings
from .schemas import RecordType, SourceSystem


class IncoisConnector(BaseConnector):
    source = SourceSystem.INCOIS

    def _fetch_raw(self, client: httpx.Client) -> Any:
        if not settings.incois_base_url:
            raise ConnectorError("INCOIS_BASE_URL not configured")
        resp = client.get(
            settings.incois_base_url,
            headers={"Authorization": f"Bearer {settings.incois_api_key}"} if settings.incois_api_key else {},
            params={"format": "json"},
        )
        resp.raise_for_status()
        return resp.json()

    def _parse(self, raw_payload: Any) -> list[dict]:
        """
        Expects a list of per-station/per-beach forecast entries.
        Placeholder field mapping — verify against real INCOIS payload.
        """
        items: list[dict] = []
        stations = raw_payload.get("stations", []) if isinstance(raw_payload, dict) else raw_payload

        for st in stations:
            station_id = st.get("station_id") or st.get("id")
            if station_id is None:
                continue  # cannot dedup/attribute without a stable id — reject silently upstream

            forecast_time = st.get("forecast_time") or st.get("timestamp")

            items.append({
                "source": SourceSystem.INCOIS,
                "source_id": f"incois:{station_id}:{forecast_time}",
                "type": RecordType.OCEAN_FORECAST,
                "severity": None,
                "geometry": self._build_point_geometry(st),
                "start_time": forecast_time,
                "end_time": None,
                "raw_json": st,
                "parsed_fields": {
                    "station_id": station_id,
                    "wave_height": st.get("wave_ht"),
                    "current_speed": st.get("curr_spd"),
                    "wind_speed": st.get("wind_spd"),
                    "swell_height": st.get("swell_ht"),
                    "tide_state": st.get("tide_state"),
                    "rainfall": st.get("rainfall"),
                    "visibility": st.get("visibility"),
                    "water_quality": st.get("water_quality_index"),
                },
                "source_confidence": 1.0,
            })
        return items

    @staticmethod
    def _build_point_geometry(station: dict) -> dict | None:
        lat, lng = station.get("lat"), station.get("lng")
        if lat is None or lng is None:
            return None
        return {"type": "Point", "coordinates": [lng, lat]}
