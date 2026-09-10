import { useState } from "react";
import "./SafeZones.css";

/* ── Hardcoded Safe Zone Data ── */
const SAFE_ZONES = [
  {
    id: "sz001",
    name: "Calangute Main Beach Zone",
    location: "Calangute, Goa",
    state: "goa",
    status: "active",
    capacity: 500,
    current_crowd: 210,
    lifeguards: 6,
    last_updated: "10 min ago",
    amenities: [
      { icon: "🦺", label: "Lifeguards" },
      { icon: "🚑", label: "First Aid" },
      { icon: "🚿", label: "Showers" },
      { icon: "🚻", label: "Restrooms" },
      { icon: "🅿️", label: "Parking" },
      { icon: "📡", label: "CCTV" },
    ],
    alert: null,
    coords: { lat: 15.5440, lng: 73.7528 },
  },
  {
    id: "sz002",
    name: "Baga Beach Safety Corridor",
    location: "Baga, Goa",
    state: "goa",
    status: "active",
    capacity: 400,
    current_crowd: 370,
    lifeguards: 4,
    last_updated: "5 min ago",
    amenities: [
      { icon: "🦺", label: "Lifeguards" },
      { icon: "🚑", label: "First Aid" },
      { icon: "⚠️", label: "Rip Flags" },
      { icon: "📡", label: "CCTV" },
    ],
    alert: "High footfall — swim only in marked zones.",
    coords: { lat: 15.5567, lng: 73.7511 },
  },
  {
    id: "sz003",
    name: "Kovalam Lighthouse Beach Zone",
    location: "Kovalam, Kerala",
    state: "kerala",
    status: "active",
    capacity: 350,
    current_crowd: 140,
    lifeguards: 5,
    last_updated: "15 min ago",
    amenities: [
      { icon: "🦺", label: "Lifeguards" },
      { icon: "🚑", label: "First Aid" },
      { icon: "🚿", label: "Showers" },
      { icon: "🚻", label: "Restrooms" },
      { icon: "🔦", label: "Lighting" },
    ],
    alert: null,
    coords: { lat: 8.3988, lng: 76.9787 },
  },
  {
    id: "sz004",
    name: "Marina Beach North Zone",
    location: "Chennai, Tamil Nadu",
    state: "tamilnadu",
    status: "active",
    capacity: 1000,
    current_crowd: 650,
    lifeguards: 12,
    last_updated: "8 min ago",
    amenities: [
      { icon: "🦺", label: "Lifeguards" },
      { icon: "🚑", label: "First Aid" },
      { icon: "🚒", label: "Fire Rescue" },
      { icon: "🚻", label: "Restrooms" },
      { icon: "🅿️", label: "Parking" },
      { icon: "📡", label: "CCTV" },
    ],
    alert: null,
    coords: { lat: 13.0500, lng: 80.2824 },
  },
  {
    id: "sz005",
    name: "Puri Beach Designated Swim Zone",
    location: "Puri, Odisha",
    state: "odisha",
    status: "limited",
    capacity: 300,
    current_crowd: 280,
    lifeguards: 3,
    last_updated: "20 min ago",
    amenities: [
      { icon: "🦺", label: "Lifeguards" },
      { icon: "🚑", label: "First Aid" },
      { icon: "⚠️", label: "Rip Flags" },
    ],
    alert: "Near capacity — entry may be restricted shortly.",
    coords: { lat: 19.7979, lng: 85.8245 },
  },
  {
    id: "sz006",
    name: "Juhu Beach Safety Zone",
    location: "Mumbai, Maharashtra",
    state: "maharashtra",
    status: "active",
    capacity: 600,
    current_crowd: 180,
    lifeguards: 8,
    last_updated: "3 min ago",
    amenities: [
      { icon: "🦺", label: "Lifeguards" },
      { icon: "🚑", label: "First Aid" },
      { icon: "🚿", label: "Showers" },
      { icon: "🚻", label: "Restrooms" },
      { icon: "🅿️", label: "Parking" },
    ],
    alert: null,
    coords: { lat: 19.0990, lng: 72.8261 },
  },
  {
    id: "sz007",
    name: "Radhanagar Beach Zone",
    location: "Havelock Island, Andaman",
    state: "andaman",
    status: "active",
    capacity: 200,
    current_crowd: 75,
    lifeguards: 4,
    last_updated: "12 min ago",
    amenities: [
      { icon: "🦺", label: "Lifeguards" },
      { icon: "🚑", label: "First Aid" },
      { icon: "🚿", label: "Showers" },
      { icon: "🐠", label: "Snorkel Zone" },
    ],
    alert: null,
    coords: { lat: 11.9810, lng: 92.9532 },
  },
  {
    id: "sz008",
    name: "Varkala Cliff Beach Zone",
    location: "Varkala, Kerala",
    state: "kerala",
    status: "limited",
    capacity: 150,
    current_crowd: 130,
    lifeguards: 2,
    last_updated: "18 min ago",
    amenities: [
      { icon: "🦺", label: "Lifeguards" },
      { icon: "🚑", label: "First Aid" },
      { icon: "⚠️", label: "Rip Flags" },
    ],
    alert: "Strong lateral currents reported — wade carefully.",
    coords: { lat: 8.7347, lng: 76.7153 },
  },
];

const STATE_FILTERS = [
  { value: "all",          label: "All Zones" },
  { value: "goa",         label: "Goa" },
  { value: "kerala",      label: "Kerala" },
  { value: "maharashtra", label: "Maharashtra" },
  { value: "tamilnadu",   label: "Tamil Nadu" },
  { value: "odisha",      label: "Odisha" },
  { value: "andaman",     label: "Andaman" },
];

const STATUS_META = {
  active:  { label: "Active",   color: "#1A9E5C" },
  limited: { label: "Limited",  color: "#E07B00" },
  closed:  { label: "Closed",   color: "#D33" },
};

function StatusBadge({ status }) {
  const meta = STATUS_META[status] || { label: status, color: "#555" };
  return (
    <span className="sz-status-badge" style={{ "--sz-badge-color": meta.color }}>
      <span className="sz-status-dot" aria-hidden="true" />
      {meta.label}
    </span>
  );
}

function CrowdBar({ current, capacity }) {
  const pct = Math.min(100, Math.round((current / capacity) * 100));
  const color = pct >= 90 ? "#D33" : pct >= 70 ? "#E07B00" : "#1A9E5C";
  return (
    <div style={{ width: "100%" }}>
      <div style={{ display: "flex", justifyContent: "space-between", fontSize: 11, color: "#888", marginBottom: 4 }}>
        <span>Crowd level</span>
        <span style={{ fontWeight: 600, color }}>{pct}%</span>
      </div>
      <div style={{ height: 6, background: "#E0EAEB", borderRadius: 4, overflow: "hidden" }}>
        <div style={{ height: "100%", width: `${pct}%`, background: color, borderRadius: 4, transition: "width 0.4s" }} />
      </div>
    </div>
  );
}

export default function SafeZones() {
  const [activeFilter, setActiveFilter] = useState("all");
  const [toast, setToast] = useState(null);

  const showToast = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(null), 2500);
  };

  const filtered = activeFilter === "all"
    ? SAFE_ZONES
    : SAFE_ZONES.filter((z) => z.state === activeFilter);

  const activeCount  = SAFE_ZONES.filter((z) => z.status === "active").length;
  const limitedCount = SAFE_ZONES.filter((z) => z.status === "limited").length;
  const totalLifeguards = SAFE_ZONES.reduce((sum, z) => sum + z.lifeguards, 0);

  const handleViewOnMap = (zone) => {
    const url = `/explore-map?lat=${zone.coords.lat}&lng=${zone.coords.lng}&zone=${zone.id}`;
    window.location.assign(url);
  };

  const handleDirections = (zone) => {
    const url = `https://www.google.com/maps/dir/?api=1&destination=${zone.coords.lat},${zone.coords.lng}`;
    window.open(url, "_blank", "noopener,noreferrer");
    showToast(`Opening directions to ${zone.name}`);
  };

  return (
    <main className="sz-page">
      {/* Breadcrumb */}
      <nav className="profile-breadcrumb" aria-label="Breadcrumb">
        <a href="/" className="profile-breadcrumb-link">Home</a>
        <span className="profile-breadcrumb-separator" aria-hidden="true">|</span>
        <span className="profile-breadcrumb-current" aria-current="page">Safe Zones</span>
      </nav>

      {/* Header */}
      <div className="sz-header">
        <h1 className="sz-title">Safe Zones</h1>
        <p className="sz-subtitle">
          Government-designated swimming zones with lifeguard coverage across India's coastline.
          Always swim within marked areas.
        </p>
      </div>

      {/* Summary strip */}
      <div className="sz-summary-strip" aria-label="Safe zone statistics">
        <div className="sz-summary-card">
          <span className="sz-summary-label">Active Zones</span>
          <span className="sz-summary-val" style={{ color: "#1A9E5C" }}>{activeCount}</span>
          <span className="sz-summary-hint">Open for swimming</span>
        </div>
        <div className="sz-summary-card">
          <span className="sz-summary-label">Limited Access</span>
          <span className="sz-summary-val" style={{ color: "#E07B00" }}>{limitedCount}</span>
          <span className="sz-summary-hint">Near capacity or advisory</span>
        </div>
        <div className="sz-summary-card">
          <span className="sz-summary-label">Lifeguards On Duty</span>
          <span className="sz-summary-val">{totalLifeguards}</span>
          <span className="sz-summary-hint">Across all zones</span>
        </div>
      </div>

      {/* Filter bar */}
      <div className="sz-filter-bar" role="group" aria-label="Filter by state">
        {STATE_FILTERS.map((f) => (
          <button
            key={f.value}
            className={`sz-filter-btn ${activeFilter === f.value ? "sz-filter-btn--active" : ""}`}
            onClick={() => setActiveFilter(f.value)}
            type="button"
            aria-pressed={activeFilter === f.value}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Cards */}
      {filtered.length === 0 ? (
        <div className="sz-empty">
          <div className="sz-empty-icon" aria-hidden="true">🏖️</div>
          <p className="sz-empty-text">No safe zones found</p>
          <p className="sz-empty-hint">Try a different state filter.</p>
        </div>
      ) : (
        <section className="sz-grid" aria-label="Safe zones list">
          {filtered.map((zone) => (
            <article key={zone.id} className="sz-card">
              {/* Top */}
              <div className="sz-card-top">
                <div>
                  <div className="sz-card-name">{zone.name}</div>
                  <div className="sz-card-location">📍 {zone.location}</div>
                </div>
                <StatusBadge status={zone.status} />
              </div>

              {/* Alert */}
              {zone.alert && (
                <div className="sz-alert" role="alert">
                  <span className="sz-alert-icon" aria-hidden="true">⚠️</span>
                  <p className="sz-alert-text">{zone.alert}</p>
                </div>
              )}

              {/* Info chips */}
              <div className="sz-info-row">
                <div className="sz-info-chip">
                  <span className="sz-info-chip-icon" aria-hidden="true">🦺</span>
                  <div className="sz-info-chip-text">
                    <span className="sz-info-chip-val">{zone.lifeguards}</span>
                    <span className="sz-info-chip-label">Lifeguards</span>
                  </div>
                </div>
                <div className="sz-info-chip">
                  <span className="sz-info-chip-icon" aria-hidden="true">👥</span>
                  <div className="sz-info-chip-text">
                    <span className="sz-info-chip-val">{zone.current_crowd} / {zone.capacity}</span>
                    <span className="sz-info-chip-label">Capacity</span>
                  </div>
                </div>
                <div className="sz-info-chip">
                  <span className="sz-info-chip-icon" aria-hidden="true">🕐</span>
                  <div className="sz-info-chip-text">
                    <span className="sz-info-chip-val">{zone.last_updated}</span>
                    <span className="sz-info-chip-label">Updated</span>
                  </div>
                </div>
              </div>

              {/* Crowd bar */}
              <CrowdBar current={zone.current_crowd} capacity={zone.capacity} />

              {/* Amenities */}
              <div className="sz-amenities" aria-label="Available amenities">
                {zone.amenities.map((a) => (
                  <span key={a.label} className="sz-amenity">
                    <span className="sz-amenity-icon" aria-hidden="true">{a.icon}</span>
                    {a.label}
                  </span>
                ))}
              </div>

              {/* Actions */}
              <div className="sz-card-footer">
                <button
                  className="sz-btn sz-btn--primary"
                  onClick={() => handleViewOnMap(zone)}
                  type="button"
                >
                  View on Map
                </button>
                <button
                  className="sz-btn sz-btn--outline"
                  onClick={() => handleDirections(zone)}
                  type="button"
                >
                  Directions
                </button>
              </div>
            </article>
          ))}
        </section>
      )}

      {/* Map CTA */}
      <div className="sz-map-cta">
        <div className="sz-map-cta-text">
          <div className="sz-map-cta-heading">Explore all zones on the interactive map</div>
          <div className="sz-map-cta-sub">Zoom in to find the nearest safe zone at any beach.</div>
        </div>
        <a href="/explore-map" className="sz-map-cta-btn">
          Open Map →
        </a>
      </div>

      {/* Toast */}
      {toast && (
        <div className="sz-toast" role="status" aria-live="polite">
          {toast}
        </div>
      )}
    </main>
  );
}
