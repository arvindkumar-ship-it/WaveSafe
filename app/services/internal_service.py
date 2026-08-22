# # import uuid
# # from typing import Any, Dict, Optional

# # from sqlalchemy.orm import Session

# # from app.core.audit import log_audit_event
# # from app.services.ingestion_service import poll_incois, poll_sachet
# # from risk_engine.engine import compute_and_store_risk
# # from app.models.geospatial import Beach

# # # ⚠️ handle_escalate below still uses the OLD escalate_incident import — DO NOT remove
# # # this yet, it will be rewritten once dispatch_state_machine.py content is shared.
# # from app.services.escalation_service import escalate as escalate_incident


# # def handle_incois(db: Session, raw: Dict[str, Any]) -> int:
# #     count = poll_incois(db)
# #     log_audit_event(db, event_type="ingest.incois", entity_type="hazard_source", entity_id=None,
# #                      actor_type="worker", actor_id=None, payload={"records": count})
# #     db.commit()
# #     return count


# # def handle_sachet(db: Session, raw: Dict[str, Any]) -> int:
# #     count = poll_sachet(db)
# #     log_audit_event(db, event_type="ingest.sachet", entity_type="hazard_source", entity_id=None,
# #                      actor_type="worker", actor_id=None, payload={"records": count})
# #     db.commit()
# #     return count


# # def handle_recompute(db: Session, beach_id: Optional[uuid.UUID]) -> int:
# #     # ⚠️ ADAPTED — real risk_engine works per beach+activity, not "all beaches" in one call.
# #     # If beach_id given, recompute all activities for that one beach; else all active beaches.
# #     ACTIVITY_TYPES = ["swimming", "surfing", "boating"]
# #     beaches = [db.query(Beach).get(beach_id)] if beach_id else db.query(Beach).filter(Beach.active == True).all()
# #     count = 0
# #     for beach in beaches:
# #         if not beach:
# #             continue
# #         for activity in ACTIVITY_TYPES:
# #             result = compute_and_store_risk(str(beach.id), activity)
# #             if result:
# #                 count += 1
# #     log_audit_event(db, event_type="risk.recomputed", entity_type="beach", entity_id=beach_id,
# #                      actor_type="worker", actor_id=None, payload={"beaches_recomputed": count})
# #     db.commit()
# #     return count


# # def handle_escalate(db: Session, incident_id: uuid.UUID, reason: str, attempt: int) -> list[str]:
# #     # ⚠️ STILL BROKEN — old escalate() function doesn't exist in real escalation_service.py.
# #     # Waiting on dispatch_state_machine.py content to rewrite this properly.
# #     next_targets = escalate_incident(db, incident_id, reason, attempt)
# #     log_audit_event(db, event_type="escalation.timeout", entity_type="incident_report", entity_id=incident_id,
# #                      actor_type="worker", actor_id=None, payload={"reason": reason, "attempt": attempt})
# #     db.commit()
# #     return next_targets


# """Thin wrappers only.

# REWRITTEN against real code:
# - app.services.ingestion_service.poll_incois(db) / poll_sachet(db)   (real names, no `raw` param)
# - risk_engine.engine.compute_and_store_risk(beach_id, activity_type)  (per-beach-per-activity,
#   not a single "recompute everything" call)
# - Escalation is now state-machine-driven (see handle_escalate below), not a standalone
#   escalate() function — that function never existed in the real escalation_service.py.
# """
# import uuid
# from typing import Any, Dict, Optional

# from sqlalchemy.orm import Session

# from app.core.audit import log_audit_event
# from app.services.ingestion_service import poll_incois, poll_sachet
# from risk_engine.engine import compute_and_store_risk
# from app.models.geospatial import Beach

# ACTIVITY_TYPES = ["swimming", "surfing", "boating"]  # ⚠️ ASSUMPTION, verify against real set


# def handle_incois(db: Session, raw: Dict[str, Any]) -> int:
#     count = poll_incois(db)
#     log_audit_event(db, event_type="ingest.incois", entity_type="hazard_source", entity_id=None,
#                      actor_type="worker", actor_id=None, payload={"records": count})
#     db.commit()
#     return count


# def handle_sachet(db: Session, raw: Dict[str, Any]) -> int:
#     count = poll_sachet(db)
#     log_audit_event(db, event_type="ingest.sachet", entity_type="hazard_source", entity_id=None,
#                      actor_type="worker", actor_id=None, payload={"records": count})
#     db.commit()
#     return count


# def handle_recompute(db: Session, beach_id: Optional[uuid.UUID]) -> int:
#     beaches = [db.query(Beach).get(beach_id)] if beach_id else db.query(Beach).filter(Beach.active == True).all()
#     count = 0
#     for beach in beaches:
#         if not beach:
#             continue
#         for activity in ACTIVITY_TYPES:
#             result = compute_and_store_risk(str(beach.id), activity)
#             if result:
#                 count += 1
#     log_audit_event(db, event_type="risk.recomputed", entity_type="beach", entity_id=beach_id,
#                      actor_type="worker", actor_id=None, payload={"beaches_recomputed": count})
#     db.commit()
#     return count


# def handle_escalate(db: Session, incident_id: uuid.UUID, reason: str, attempt: int) -> list[str]:
#     # Real escalation is normally automatic (escalation_worker polls ack_timers and drives
#     # DispatchStateMachine on timeout). This is a manual-trigger path for an internal/ops route,
#     # implemented as an audited operator override via force_manual_transition.
#     from app.core.dispatch_states import IncidentState
#     from app.services.dispatch_state_machine import force_manual_transition

#     to_state = IncidentState.ESCALATED if attempt <= 1 else IncidentState.FALLBACK_112
#     force_manual_transition(db, incident_id, to_state, operator_id=uuid.uuid4(), reason=reason)
#     log_audit_event(db, event_type="escalation.timeout", entity_type="incident_report", entity_id=incident_id,
#                      actor_type="worker", actor_id=None, payload={"reason": reason, "attempt": attempt})
#     db.commit()
#     return [to_state.value]























"""Thin wrappers only.

REWRITTEN — poll_incois/poll_sachet never existed. Real ingestion_service.py exposes
build_connectors() (returns [IncoisConnector, SachetConnector]) + run_connector(connector,
redis_client) -> IngestionRunResult(records=[...], error=...). Wired accordingly below.
"""
import uuid
from typing import Any, Dict, Optional

from sqlalchemy.orm import Session

from app.core.audit import log_audit_event
from app.redis_client import redis_client
from app.services.ingestion_service import build_connectors, run_connector
from risk_engine.engine import compute_and_store_risk
from app.models.geospatial import Beach

ACTIVITY_TYPES = ["swimming", "surfing", "boating"]  # ⚠️ ASSUMPTION, verify against real set


def _run_source(source_name: str) -> int:
    """Returns records ACTUALLY persisted this run (real before/after DB
    count delta) â€” not len(result.records), which is just "fetched", and
    was silently wrong whenever dedup skipped, normalize rejected, or
    persist failed for any record."""
    from sqlalchemy import func
    from app.models import HazardAlert
    from app.core.db import get_session

    connectors = {c.source.value: c for c in build_connectors()}
    connector = connectors.get(source_name)
    if not connector:
        return 0

    with get_session() as session:
        before = session.query(func.count(HazardAlert.id)).filter(
            HazardAlert.source_system == source_name
        ).scalar()

    run_connector(connector, redis_client)

    with get_session() as session:
        after = session.query(func.count(HazardAlert.id)).filter(
            HazardAlert.source_system == source_name
        ).scalar()

    return after - before


def handle_incois(db: Session, raw: Dict[str, Any]) -> int:
    count = _run_source("incois")
    log_audit_event(db, event_type="ingest.incois", entity_type="hazard_source", entity_id=None,
                     actor_type="worker", actor_id=None, payload={"records": count})
    db.commit()
    return count


def handle_sachet(db: Session, raw: Dict[str, Any]) -> int:
    count = _run_source("sachet")
    log_audit_event(db, event_type="ingest.sachet", entity_type="hazard_source", entity_id=None,
                     actor_type="worker", actor_id=None, payload={"records": count})
    db.commit()
    return count


def handle_recompute(db: Session, beach_id: Optional[uuid.UUID]) -> int:
    beaches = [db.query(Beach).get(beach_id)] if beach_id else db.query(Beach).filter(Beach.active == True).all()
    count = 0
    for beach in beaches:
        if not beach:
            continue
        for activity in ACTIVITY_TYPES:
            if compute_and_store_risk(str(beach.id), activity):
                count += 1
    log_audit_event(db, event_type="risk.recomputed", entity_type="beach", entity_id=beach_id,
                     actor_type="worker", actor_id=None, payload={"beaches_recomputed": count})
    db.commit()
    return count


def handle_escalate(db: Session, incident_id: uuid.UUID, reason: str, attempt: int) -> list[str]:
    from app.core.dispatch_states import IncidentState
    from app.services.dispatch_state_machine import force_manual_transition
    to_state = IncidentState.ESCALATED if attempt <= 1 else IncidentState.FALLBACK_112
    force_manual_transition(db, incident_id, to_state, operator_id=uuid.uuid4(), reason=reason)
    log_audit_event(db, event_type="escalation.timeout", entity_type="incident_report", entity_id=incident_id,
                     actor_type="worker", actor_id=None, payload={"reason": reason, "attempt": attempt})
    db.commit()
    return [to_state.value]