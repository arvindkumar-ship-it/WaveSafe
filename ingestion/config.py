# """
# Module 3 — Data Ingestion : Configuration

# ASSUMPTION (stated explicitly, verify against your repo):
# - Stack = Python 3.11+, SQLAlchemy 2.x + GeoAlchemy2, matching the models/__init__.py
#   work already done in Module 2. If your actual stack differs (async SQLAlchemy,
#   Django, etc.), tell me and I'll re-target this module — nothing here is final
#   until you confirm it against the real repo.
# - Object storage for raw payloads defaults to local filesystem in dev and is
#   swappable for S3-compatible storage in prod via RAW_STORAGE_BACKEND.
# """
# import os
# from dataclasses import dataclass, field


# @dataclass(frozen=True)
# class SourceConfig:
#     name: str                      # e.g. "incois", "sachet", "manual_admin"
#     poll_interval_seconds: int
#     timeout_seconds: int
#     max_retries: int
#     backoff_base_seconds: float
#     enabled: bool = True


# @dataclass(frozen=True)
# class IngestionSettings:
#     # --- Source endpoints (env-driven, never hardcode secrets/URLs in code) ---
#     incois_base_url: str = os.getenv("INCOIS_BASE_URL", "")
#     incois_api_key: str = os.getenv("INCOIS_API_KEY", "")

#     sachet_cap_feed_url: str = os.getenv("SACHET_CAP_FEED_URL", "")
#     sachet_api_key: str = os.getenv("SACHET_API_KEY", "")

#     # --- Object storage for raw payloads (Module 3, step 6) ---
#     raw_storage_backend: str = os.getenv("RAW_STORAGE_BACKEND", "local")  # "local" | "s3"
#     raw_storage_local_path: str = os.getenv("RAW_STORAGE_LOCAL_PATH", "/var/data/raw_ingest")
#     raw_storage_s3_bucket: str = os.getenv("RAW_STORAGE_S3_BUCKET", "")
#     raw_storage_s3_prefix: str = os.getenv("RAW_STORAGE_S3_PREFIX", "raw-ingest")

#     # --- Ops alerting (step 14: alert ops team if source breaks) ---
#     ops_alert_webhook_url: str = os.getenv("OPS_ALERT_WEBHOOK_URL", "")
#     ops_alert_min_consecutive_failures: int = int(os.getenv("OPS_ALERT_MIN_FAILURES", "3"))

#     sources: dict = field(default_factory=lambda: {
#         "incois": SourceConfig(
#             name="incois",
#             poll_interval_seconds=int(os.getenv("INCOIS_POLL_SECONDS", "900")),   # 15 min
#             timeout_seconds=20,
#             max_retries=4,
#             backoff_base_seconds=2.0,
#         ),
#         "sachet": SourceConfig(
#             name="sachet",
#             poll_interval_seconds=int(os.getenv("SACHET_POLL_SECONDS", "120")),   # 2 min — CAP alerts are urgent
#             timeout_seconds=15,
#             max_retries=5,
#             backoff_base_seconds=1.5,
#         ),
#         "manual_admin": SourceConfig(
#             name="manual_admin",
#             poll_interval_seconds=0,   # event-driven, not polled — admin submits directly
#             timeout_seconds=5,
#             max_retries=1,
#             backoff_base_seconds=0.0,
#         ),
#     })


# settings = IngestionSettings()










"""
Module 3 — Data Ingestion : Configuration

ASSUMPTION (stated explicitly, verify against your repo):
- Stack = Python 3.11+, SQLAlchemy 2.x + GeoAlchemy2, matching the models/__init__.py
  work already done in Module 2. If your actual stack differs (async SQLAlchemy,
  Django, etc.), tell me and I'll re-target this module — nothing here is final
  until you confirm it against the real repo.
- Object storage for raw payloads defaults to local filesystem in dev and is
  swappable for S3-compatible storage in prod via RAW_STORAGE_BACKEND.
"""
import os
from pathlib import Path
from dotenv import load_dotenv

_ENV_PATH = Path(__file__).resolve().parents[1] / ".env"
load_dotenv(dotenv_path=_ENV_PATH, override=False)

from dataclasses import dataclass, field
from dataclasses import dataclass, field


@dataclass(frozen=True)
class SourceConfig:
    name: str                      # e.g. "incois", "sachet", "manual_admin"
    poll_interval_seconds: int
    timeout_seconds: int
    max_retries: int
    backoff_base_seconds: float
    enabled: bool = True


@dataclass(frozen=True)
class IngestionSettings:
    # --- Source endpoints (env-driven, never hardcode secrets/URLs in code) ---
    # NOTE: using field(default_factory=...) instead of a bare os.getenv(...) default.
    # Dataclass defaults are evaluated ONCE at class-definition/import time, not at
    # instantiation time — so a bare os.getenv() here would freeze in whatever the
    # env var was at import time (often before load_dotenv() has run elsewhere),
    # permanently ignoring the real .env value. default_factory defers evaluation
    # to IngestionSettings() instantiation time, after .env has been loaded.
    incois_base_url: str = field(default_factory=lambda: os.getenv("INCOIS_BASE_URL", ""))
    incois_api_key: str = field(default_factory=lambda: os.getenv("INCOIS_API_KEY", ""))

    sachet_cap_feed_url: str = field(default_factory=lambda: os.getenv("SACHET_CAP_FEED_URL", ""))
    sachet_api_key: str = field(default_factory=lambda: os.getenv("SACHET_API_KEY", ""))

    # --- Object storage for raw payloads (Module 3, step 6) ---
    raw_storage_backend: str = field(default_factory=lambda: os.getenv("RAW_STORAGE_BACKEND", "local"))  # "local" | "s3"
    raw_storage_local_path: str = field(default_factory=lambda: os.getenv("RAW_STORAGE_LOCAL_PATH", "/var/data/raw_ingest"))
    raw_storage_s3_bucket: str = field(default_factory=lambda: os.getenv("RAW_STORAGE_S3_BUCKET", ""))
    raw_storage_s3_prefix: str = field(default_factory=lambda: os.getenv("RAW_STORAGE_S3_PREFIX", "raw-ingest"))

    # --- Ops alerting (step 14: alert ops team if source breaks) ---
    ops_alert_webhook_url: str = field(default_factory=lambda: os.getenv("OPS_ALERT_WEBHOOK_URL", ""))
    ops_alert_min_consecutive_failures: int = field(default_factory=lambda: int(os.getenv("OPS_ALERT_MIN_FAILURES", "3")))

    sources: dict = field(default_factory=lambda: {
        "incois": SourceConfig(
            name="incois",
            poll_interval_seconds=int(os.getenv("INCOIS_POLL_SECONDS", "900")),   # 15 min
            timeout_seconds=20,
            max_retries=4,
            backoff_base_seconds=2.0,
        ),
        "sachet": SourceConfig(
            name="sachet",
            poll_interval_seconds=int(os.getenv("SACHET_POLL_SECONDS", "120")),   # 2 min — CAP alerts are urgent
            timeout_seconds=15,
            max_retries=5,
            backoff_base_seconds=1.5,
        ),
        "manual_admin": SourceConfig(
            name="manual_admin",
            poll_interval_seconds=0,   # event-driven, not polled — admin submits directly
            timeout_seconds=5,
            max_retries=1,
            backoff_base_seconds=0.0,
        ),
    })


settings = IngestionSettings()