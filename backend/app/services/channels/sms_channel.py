"""
Fast2SMS integration (route "q" — Quick Transactional, no DLT registration needed).
API docs: https://docs.fast2sms.com — endpoint/payload verified against
https://www.fast2sms.com/free-sms-api-gateway (official sample as of 2026-08-22).

Numbers are cleaned to plain 10-digit Indian mobile format (via
app.services.sms_provider._to_fast2sms_number) before sending — Fast2SMS
rejects numbers with a "+91" prefix or spaces.
"""
import httpx
from app.core.config import settings
from app.services.sms_provider import _to_fast2sms_number


def send_sms(phone: str, body: str) -> dict:
    if not phone:
        return {"ok": False, "error": "NO_PHONE_ON_FILE"}
    try:
        resp = httpx.post(
            settings.SMS_GATEWAY_URL,
            json={"message": body[:160], "route": "q", "numbers": _to_fast2sms_number(phone), "flash": "0"},
            headers={
                "authorization": settings.SMS_GATEWAY_KEY,
                "accept": "*/*",
                "content-type": "application/json",
            },
            timeout=10,
        )
        data = resp.json()
        if resp.status_code >= 400 or data.get("return") is not True:
            return {"ok": False, "error": data.get("message") or f"SMS_GATEWAY_{resp.status_code}"}
        return {"ok": True, "ref": data.get("request_id")}
    except httpx.HTTPError as e:
        return {"ok": False, "error": str(e)}