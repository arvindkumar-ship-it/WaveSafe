
import { useCallback, useState } from "react";
import { triggerSOS } from "../../services/sos";
import { getCurrentBeachContext, getCurrentTripContext, saveCurrentIncidentContext } from "../../utils/beachIdMap";
import "./SOS.css";

function getIncidentId(response) {
  return response?.incident_id ?? response?.incident?.incident_id ?? response?.data?.incident_id ?? null;
}

export default function SOS() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleTriggerSOS = useCallback(async () => {
    if (loading) return;

    setLoading(true);
    setError("");

    try {
      const beach = getCurrentBeachContext();
      const trip = getCurrentTripContext();
      const response = await triggerSOS({
        beachId: beach?.id || trip?.beach_id || null,
        activityType: trip?.activity_type || null,
        triggerType: "manual",
        incidentType: "general_emergency",
        severity: "critical",
      });
      const incidentId = getIncidentId(response);

      if (!incidentId) {
        throw new Error("SOS was triggered, but the response did not include an incident ID.");
      }

      saveCurrentIncidentContext({
        incident_id: incidentId,
        beach_id: beach?.id || trip?.beach_id || null,
        trip_id: trip?.trip_id || null,
        status: response?.status || null,
        safe_zone: response?.safe_zone || null,
        tracking_session_id: response?.tracking_session_id || null,
        created_at: new Date().toISOString(),
      });

      const params = new URLSearchParams({ incident_id: String(incidentId) });
      if (response?.tracking_session_id) params.set("tracking_session_id", response.tracking_session_id);
      window.location.assign(`/sos-request?${params.toString()}`);
    } catch (requestError) {
      setError(requestError.message || "Unable to trigger SOS. Please try again.");
    } finally {
      setLoading(false);
    }
  }, [loading]);

  return (
    <main
      className="sos-page"
    >
      <nav className="breadcrumb" aria-label="Breadcrumb">
        <a href="/" className="breadcrumb-home">Home</a>
        <span className="breadcrumb-separator" aria-hidden="true"> | </span>
        <a href="/sos" className="breadcrumb-sos breadcrumb-link" aria-current="page">SOS</a>
      </nav>

      <div className="sos-panel">
        <section className="sos-content" aria-labelledby="emergency-title">
          <h1 id="emergency-title">Emergency help needed?</h1>

          <button
            className="sos-button"
            type="button"
            aria-label="Activate SOS emergency assistance"
            onClick={handleTriggerSOS}
            disabled={loading}
          >
            <span>SOS</span>
          </button>

          <p className="sos-description">
            After pressing the SOS button we will <br />
            contact the nearest hospital , police stations <br />
            emergency gaurds to your current location
          </p>

          {error && <p className="sos-error" role="alert">{error}</p>}
        </section>
      </div>
    </main>
  );
}