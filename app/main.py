"""
app/main.py

Router wiring verified against the ACTUAL router objects in every copied file (not assumed
from the original planning doc â€” several prefixes there were wrong; see notes inline).

Key corrections made after inspecting real code:
  1. Most routers (trips, incidents, emergency_share, notifications, admin, offline_sync,
     beach, internal, internal_dispatch) already bake "/v1" or "/internal" into their OWN
     `APIRouter(prefix=...)` call. Adding prefix="/v1" again at include_router() here would
     double it to "/v1/v1/...". These are mounted with NO extra prefix.
  2. safezone.py and tracking.py do NOT self-prefix with /v1 (only "/safezone", "/tracking")
     â€” these genuinely need prefix="/v1" added here.
  3. hospital_router.py and authority_router.py have fully absolute paths hardcoded into
     their route decorators (e.g. "/internal/hospital-router/dispatch" and
     "/hospital-router/routes/{id}/ack") with NO router-level prefix at all. They must be
     mounted with prefix="" (root) or their paths break.
  4. incidents.py exports TWO routers (sos_router, incidents_router), not one `router`.
  5. admin.py (Module 20-26 version) exports TWO routers in one file: `admin_router`
     (CRUD, superseded by Module 17's richer version per B11) and `auth_router` (OTP,
     genuinely new, always needed). Only `auth_router` is imported here.
  6. audit.py self-prefixes at "/v1/admin/analytics" â€” mounted with no extra prefix.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import authority_router, hospital_router, safezone, tracking, health
from app.api.v1 import (
    offline_sync, admin, audit, beach, trips, incidents,
    emergency_share, notifications, internal, auth_router as auth_router_module,
)
from app.api import internal_dispatch

app = FastAPI(title="WaveSafe â€” Coastal Tourism Safety Platform")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Self-prefixed routers: mount as-is, no extra prefix ---
app.include_router(beach.router)                        # already "/v1"
app.include_router(trips.router)                         # already "/v1/trips"
app.include_router(incidents.sos_router)                 # already "/v1/sos"
app.include_router(incidents.incidents_router)            # already "/v1/incidents"
app.include_router(emergency_share.router)                # already "/v1/emergency/share"
app.include_router(notifications.router)                  # already "/v1/notifications"
app.include_router(offline_sync.router)                   # already "/v1/sync"
app.include_router(admin.router)                          # Module 17 version â€” already "/v1/admin"
app.include_router(auth_router_module.auth_router)         # extracted OTP router â€” "/v1/auth" (B11)
app.include_router(audit.router)                          # already "/v1/admin/analytics"
app.include_router(internal.router)                       # already "/internal", verify_internal_key baked in
app.include_router(internal_dispatch.router)               # already "/internal/router"

# --- Routers needing "/v1" added (they don't self-prefix with it) ---
app.include_router(safezone.router, prefix="/v1")          # "/safezone" -> "/v1/safezone"
app.include_router(tracking.router, prefix="/v1")           # "/tracking" -> "/v1/tracking"

# --- Routers with fully absolute hardcoded paths: mount at root, no prefix at all ---
app.include_router(authority_router.router)                 # "/internal/authority-router/..." + "/authority-router/..."
app.include_router(hospital_router.router)                   # "/internal/hospital-router/..." + "/hospital-router/..."

# --- Health check, no prefix (routes are "/healthz", "/readyz") ---
app.include_router(health.router)