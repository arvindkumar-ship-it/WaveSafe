# """
# app/services/sms_provider.py
# Fast2SMS integration for OTP delivery. Uses the real Fast2SMS bulkV2 contract
# (same provider/contract as app/services/channels/sms_channel.py, fixed in an
# earlier session): POST with route=q, numbers as plain 10-digit (no +91), and
# an unprefixed `authorization` header (NOT "Bearer ...").
# """
# import re
# import httpx
# from app.core.config import settings


# def _to_fast2sms_number(phone: str) -> str:
#     """Fast2SMS expects plain 10-digit Indian mobile numbers, no +91 prefix."""
#     digits = re.sub(r"\D", "", phone)
#     if digits.startswith("91") and len(digits) == 12:
#         digits = digits[2:]
#     return digits


# def send_sms(phone: str, body: str) -> None:
#     if not settings.SMS_GATEWAY_URL:
#         print(f"[sms_provider] (no gateway configured) -> {phone}: {body}")
#         return

#     resp = httpx.post(
#         settings.SMS_GATEWAY_URL,
#         headers={"authorization": settings.SMS_GATEWAY_KEY},
#         json={
#             "message": body,
#             "route": "q",
#             "numbers": _to_fast2sms_number(phone),
#             "flash": 0,
#         },
#         timeout=10.0,
#     )
#     print(f"[fast2sms] status={resp.status_code} body={resp.text}")
#     # resp.raise_for_status()  # disabled: Fast2SMS account disabled in local dev






















"""
app/services/sms_provider.py
Fast2SMS Quick Transactional route (route=q). No DLT/website-verification
needed — works immediately. Cost: ~Rs. 5/SMS.

Fallback: if the Fast2SMS call fails for ANY reason (network error, wallet
empty, API error, DLT-related rejection, etc.), the OTP is printed to
stdout/Render logs instead of raising — so /otp/request never 500s and you
can still read the code from the logs during a demo. Remove the try/except
(let raise_for_status() propagate) once you want hard failures surfaced to
the caller instead of silently falling back.
"""
import re
import httpx
from app.core.config import settings


def _to_fast2sms_number(phone: str) -> str:
    digits = re.sub(r"\D", "", phone)
    if digits.startswith("91") and len(digits) == 12:
        digits = digits[2:]
    return digits


def send_otp_sms(phone: str, code: str) -> None:
    if not settings.SMS_GATEWAY_URL:
        print(f"[sms_provider] (no gateway configured) -> {phone}: OTP {code}")
        return

    try:
        resp = httpx.post(
            settings.SMS_GATEWAY_URL,
            headers={"authorization": settings.SMS_GATEWAY_KEY},
            json={
                "message": f"Your Coastal Safety verification code is {code}. Valid for 5 minutes.",
                "route": "q",
                "numbers": _to_fast2sms_number(phone),
                "flash": 0,
            },
            timeout=10.0,
        )
        print(f"[fast2sms-otp] status={resp.status_code} body={resp.text}")
        resp.raise_for_status()
    except Exception as exc:
        print(f"[fast2sms-otp] FAILED ({exc}) -> falling back to log: {phone}: OTP {code}")