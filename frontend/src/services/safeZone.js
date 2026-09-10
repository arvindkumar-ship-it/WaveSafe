import { apiFetch } from "../utils/apiClient";
import { getAuthSession } from "./auth";

export const computeGuidance = (payload) => {
  const userId = getAuthSession()?.user_id || null;
  return apiFetch("/safezone/guidance", {
    method: "POST",
    body: JSON.stringify({ user_id: userId, ...payload }),
  });
};
export const recompute = (guidanceId, payload) => apiFetch(`/safezone/guidance/${encodeURIComponent(guidanceId)}/recompute`, { method: "POST", body: JSON.stringify(payload) });
export const getActive = (incidentReportId) => {
  const q = incidentReportId ? `?incident_report_id=${encodeURIComponent(incidentReportId)}` : "";
  return apiFetch(`/safezone/guidance/active${q}`);
};
export const shareGuidance = (guidanceId) => apiFetch(`/safezone/guidance/${encodeURIComponent(guidanceId)}/share`, { method: "POST" });