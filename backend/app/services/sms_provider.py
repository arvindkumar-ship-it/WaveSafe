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
Fast2SMS OTP-route integration for OTP delivery. Uses route="otp" (NOT "q") —
this is Fast2SMS's dedicated OTP route: no DLT registration needed, costs
~Rs. 0.35/SMS instead of Rs. 5.00/SMS on the Quick Transactional ("q") route.
Fixed delivery template on this route: "Your OTP: {#var#}" — only the numeric
code is sent via variables_values, custom message text is not supported here.
Same provider/contract style as app/services/channels/sms_channel.py: plain
10-digit numbers (no +91), unprefixed `authorization` header (NOT "Bearer ...").
"""
import re
import httpx
from app.core.config import settings


def _to_fast2sms_number(phone: str) -> str:
    """Fast2SMS expects plain 10-digit Indian mobile numbers, no +91 prefix."""
    digits = re.sub(r"\D", "", phone)
    if digits.startswith("91") and len(digits) == 12:
        digits = digits[2:]
    return digits


def send_otp_sms(phone: str, code: str) -> None:
    if not settings.SMS_GATEWAY_URL:
        print(f"[sms_provider] (no gateway configured) -> {phone}: OTP {code}")
        return

    resp = httpx.post(
        settings.SMS_GATEWAY_URL,
        headers={"authorization": settings.SMS_GATEWAY_KEY},
        json={
            "variables_values": code,
            "route": "otp",
            "numbers": _to_fast2sms_number(phone),
            "flash": 0,
        },
        timeout=10.0,
    )
    print(f"[fast2sms-otp] status={resp.status_code} body={resp.text}")
    resp.raise_for_status()