import { useState, useEffect } from "react";
import { getAuthSession } from "../../services/auth";
import { HARD_CODED_BEACHES } from "../../data/hardcodedBeaches";
import "./SavedBeaches.css";

const STORAGE_KEY_PREFIX = "wavesafe.saved_beaches.";

function getStorageKey() {
  try {
    const session = getAuthSession();
    return session?.user_id ? `${STORAGE_KEY_PREFIX}${session.user_id}` : `${STORAGE_KEY_PREFIX}guest`;
  } catch {
    return `${STORAGE_KEY_PREFIX}guest`;
  }
}

function loadSavedIds() {
  try {
    const raw = localStorage.getItem(getStorageKey());
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function removeSavedId(id) {
  try {
    const ids = loadSavedIds().filter((i) => i !== id);
    localStorage.setItem(getStorageKey(), JSON.stringify(ids));
  } catch {}
}

const VERDICT_LABEL = { safe: "Safe", caution: "Caution", danger: "Danger" };
const VERDICT_COLOR = { safe: "#1A9E5C", caution: "#E07B00", danger: "#D33" };

function VerdictBadge({ verdict }) {
  const label = VERDICT_LABEL[verdict] || verdict;
  const color = VERDICT_COLOR[verdict] || "#555";
  return (
    <span className="sb-badge" style={{ "--badge-color": color }}>
      <span className="sb-badge-dot" aria-hidden="true" />
      {label}
    </span>
  );
}

export default function SavedBeaches() {
  const [savedIds, setSavedIds] = useState(() => loadSavedIds());
  const [toast, setToast] = useState(null);

  const savedBeaches = HARD_CODED_BEACHES.filter((b) => savedIds.includes(b.id));

  const showToast = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(null), 2500);
  };

  const handleRemove = (id, name) => {
    removeSavedId(id);
    setSavedIds((prev) => prev.filter((i) => i !== id));
    showToast(`"${name}" removed from saved beaches.`);
  };

  const handleViewDetails = (id) => {
    window.location.href = `/beach-details?id=${id}`;
  };

  return (
    <main className="sb-page">
      {/* Breadcrumb */}
      <nav className="profile-breadcrumb" aria-label="Breadcrumb">
        <a href="/" className="profile-breadcrumb-link">Home</a>
        <span className="profile-breadcrumb-separator" aria-hidden="true">|</span>
        <a href="/profile" className="profile-breadcrumb-link">Profile</a>
        <span className="profile-breadcrumb-separator" aria-hidden="true">|</span>
        <span className="profile-breadcrumb-current" aria-current="page">Saved Beaches</span>
      </nav>

      <div className="sb-header">
        <h1 className="sb-title">Saved Beaches</h1>
        <p className="sb-subtitle">
          {savedBeaches.length > 0
            ? `You have ${savedBeaches.length} saved beach${savedBeaches.length > 1 ? "es" : ""}.`
            : "Beaches you bookmark will appear here."}
        </p>
      </div>

      {savedBeaches.length === 0 ? (
        <div className="sb-empty">
          <div className="sb-empty-icon" aria-hidden="true">
            <img src="/assets/Group 20.svg" alt="" width="56" height="42" style={{ opacity: 0.45 }} />
          </div>
          <p className="sb-empty-text">No saved beaches yet</p>
          <p className="sb-empty-hint">
            Browse beaches and tap the bookmark icon to save them here for quick access.
          </p>
          <a href="/beaches" className="sb-explore-btn">Explore Beaches</a>
        </div>
      ) : (
        <section className="sb-grid" aria-label="Saved beaches list">
          {savedBeaches.map((beach) => (
            <article key={beach.id} className="sb-card">
              <div className="sb-card-top">
                <div className="sb-card-info">
                  <h2 className="sb-card-name">{beach.name}</h2>
                  <p className="sb-card-location">
                    {beach.district}, {beach.state}
                  </p>
                </div>
                <VerdictBadge verdict={beach.current_verdict} />
              </div>

              <div className="sb-card-stats">
                <div className="sb-stat">
                  <span className="sb-stat-icon" aria-hidden="true">🌊</span>
                  <span className="sb-stat-val">{beach.ocean.wave_height}</span>
                  <span className="sb-stat-label">Waves</span>
                </div>
                <div className="sb-stat">
                  <span className="sb-stat-icon" aria-hidden="true">🌡️</span>
                  <span className="sb-stat-val">{beach.weather.temperature}°C</span>
                  <span className="sb-stat-label">Temp</span>
                </div>
                <div className="sb-stat">
                  <span className="sb-stat-icon" aria-hidden="true">🦺</span>
                  <span className="sb-stat-val">{beach.has_lifeguard ? "Yes" : "No"}</span>
                  <span className="sb-stat-label">Lifeguard</span>
                </div>
                <div className="sb-stat">
                  <span className="sb-stat-icon" aria-hidden="true">⭐</span>
                  <span className="sb-stat-val">{beach.rating}</span>
                  <span className="sb-stat-label">Rating</span>
                </div>
              </div>

              <div className="sb-card-actions">
                <button
                  className="sb-btn sb-btn--primary"
                  onClick={() => handleViewDetails(beach.id)}
                >
                  View Details
                </button>
                <button
                  className="sb-btn sb-btn--remove"
                  onClick={() => handleRemove(beach.id, beach.name)}
                  aria-label={`Remove ${beach.name} from saved`}
                >
                  Remove
                </button>
              </div>
            </article>
          ))}
        </section>
      )}

      {toast && (
        <div className="sb-toast" role="status" aria-live="polite">
          {toast}
        </div>
      )}
    </main>
  );
}
