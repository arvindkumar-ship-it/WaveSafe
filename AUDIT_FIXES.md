# Risk-score evidence boundaries

Repair branch: `fix/internship-audit-20261010`. Changes are scoped to audit findings; no deployment or live provider action is included.

## Changed

Hard overrides no longer return infinite values that break JSON serialization. Score explanations explicitly mark the value as an uncalibrated heuristic and not validated for operational use.

## Verification

`pytest -q tests/test_risk_contract.py`

Commands are entry points, not a claim that every live integration was executed. See the repair bundle for actual results.

## Setup and remaining evidence

Weights/thresholds were not retuned without data. No independently labelled disaster-risk corpus, operational calibration or validated rescue outcome is established. Offline scoring tests cover serialization and known mathematical boundaries, not disaster response. Orca is a related extension, not an independent deployed product.
