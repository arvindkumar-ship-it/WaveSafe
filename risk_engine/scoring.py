"""Module 5 — Risk Engine: scoring formula (steps 4-7)."""
from __future__ import annotations
import math
from dataclasses import dataclass, field
from typing import Optional

from .features import FEATURE_KEYS, robust_zscore

HARD_OVERRIDE_ALERT_TYPES = {
    "tsunami_warning", "storm_surge_warning", "evacuation_order",
    "beach_closure", "coast_guard_closure",
}

# Default per-feature weights w_i — override via beach_activity_profiles.risk_weights
DEFAULT_WEIGHTS = {
    "wave_height": 0.30, "current_speed": 0.28, "wind_speed": 0.12,
    "swell_height": 0.15, "water_quality": -0.08,  # better water quality lowers risk
    "rainfall": 0.05, "tide_risk": 0.10, "coverage_gap": 0.15,
}

# Pairwise interaction weights w_ij — physically meaningful combos only
DEFAULT_INTERACTIONS = {
    ("wave_height", "wind_speed"): 0.08,      # wind-driven chop compounds wave danger
    ("current_speed", "wave_height"): 0.10,   # rip current + surf = compounding
    ("swell_height", "wind_speed"): 0.05,
}

LAMBDA_TREND = 0.12       # deteriorating trend penalty
LAMBDA_TIDE = 0.08        # adverse tide-change penalty
LAMBDA_COVERAGE = 0.10    # lifeguard coverage loss penalty


def logistic(x: float) -> float:
    try:
        return 1.0 / (1.0 + math.exp(-x))
    except OverflowError:
        return 0.0 if x < 0 else 1.0


@dataclass
class ScoreExplanation:
    z_scores: dict[str, float] = field(default_factory=dict)
    weighted_terms: dict[str, float] = field(default_factory=dict)
    interaction_terms: dict[str, float] = field(default_factory=dict)
    trend_term: float = 0.0
    tide_term: float = 0.0
    coverage_term: float = 0.0
    hard_override: bool = False
    hard_override_reason: Optional[str] = None
    raw_score_pre_sigmoid: float = 0.0

    def to_dict(self) -> dict:
        return {
            "z_scores": self.z_scores,
            "weighted_terms": self.weighted_terms,
            "interaction_terms": self.interaction_terms,
            "trend_term": self.trend_term,
            "tide_term": self.tide_term,
            "coverage_term": self.coverage_term,
            "hard_override": self.hard_override,
            "hard_override_reason": self.hard_override_reason,
            "raw_score_pre_sigmoid": self.raw_score_pre_sigmoid,
        }


def check_hard_override(active_alert_types: list[str]) -> Optional[str]:
    for a in active_alert_types:
        if a in HARD_OVERRIDE_ALERT_TYPES:
            return a
    return None


def compute_risk(
    features: dict[str, Optional[float]],
    medians_iqrs: dict[str, tuple[float, float]],
    active_alert_types: list[str],
    delta_trend: float = 0.0,
    delta_tide: float = 0.0,
    delta_coverage: float = 0.0,
    weights: Optional[dict[str, float]] = None,
    interactions: Optional[dict[tuple[str, str], float]] = None,
) -> tuple[float, str, ScoreExplanation]:
    """
    R = sigmoid( sum(w_i * z_i) + sum(w_ij * z_i * z_j)
                 + lambda1*trend + lambda2*tide + lambda3*coverage )
    Hard override -> R = 1 immediately, bypassing the formula (step 4 must run first).
    """
    expl = ScoreExplanation()

    override_type = check_hard_override(active_alert_types)
    if override_type:
        expl.hard_override = True
        expl.hard_override_reason = override_type
        expl.raw_score_pre_sigmoid = float("inf")
        return 1.0, "unsafe", expl

    w = weights or DEFAULT_WEIGHTS
    inter = interactions or DEFAULT_INTERACTIONS

    z = {k: robust_zscore(features.get(k), *medians_iqrs.get(k, (0.0, 1.0))) for k in FEATURE_KEYS}
    expl.z_scores = z

    linear_sum = 0.0
    for k, weight in w.items():
        term = weight * z.get(k, 0.0)
        expl.weighted_terms[k] = term
        linear_sum += term

    interaction_sum = 0.0
    for (a, b), weight in inter.items():
        term = weight * z.get(a, 0.0) * z.get(b, 0.0)
        expl.interaction_terms[f"{a}*{b}"] = term
        interaction_sum += term

    trend_term = LAMBDA_TREND * delta_trend
    tide_term = LAMBDA_TIDE * delta_tide
    coverage_term = LAMBDA_COVERAGE * delta_coverage
    expl.trend_term, expl.tide_term, expl.coverage_term = trend_term, tide_term, coverage_term

    raw = linear_sum + interaction_sum + trend_term + tide_term + coverage_term
    expl.raw_score_pre_sigmoid = raw

    r = logistic(raw)
    verdict = "safe" if r < 0.33 else ("caution" if r < 0.66 else "unsafe")
    return r, verdict, expl
