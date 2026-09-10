import { useState } from "react";
import { getAuthSession } from "../../services/auth";
import "./Settings.css";

const STORAGE_KEY_PREFIX = "wavesafe.settings.";

function getStorageKey() {
  try {
    const session = getAuthSession();
    return session?.user_id ? `${STORAGE_KEY_PREFIX}${session.user_id}` : `${STORAGE_KEY_PREFIX}guest`;
  } catch {
    return `${STORAGE_KEY_PREFIX}guest`;
  }
}

const DEFAULT_SETTINGS = {
  notifications_sos: true,
  notifications_weather: true,
  notifications_trip: false,
  location_sharing: true,
  offline_mode: false,
  dark_mode: false,
  language: "en",
  units: "metric",
};

function loadSettings() {
  try {
    const raw = localStorage.getItem(getStorageKey());
    return raw ? { ...DEFAULT_SETTINGS, ...JSON.parse(raw) } : { ...DEFAULT_SETTINGS };
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
}

function saveSettings(settings) {
  try {
    localStorage.setItem(getStorageKey(), JSON.stringify(settings));
  } catch {}
}

function Toggle({ checked, onChange, id }) {
  return (
    <button
      id={id}
      role="switch"
      aria-checked={checked}
      className={`st-toggle ${checked ? "st-toggle--on" : ""}`}
      onClick={() => onChange(!checked)}
      type="button"
    >
      <span className="st-toggle-thumb" aria-hidden="true" />
    </button>
  );
}

function SettingsRow({ label, hint, children }) {
  return (
    <div className="st-row">
      <div className="st-row-text">
        <span className="st-row-label">{label}</span>
        {hint && <span className="st-row-hint">{hint}</span>}
      </div>
      <div className="st-row-control">{children}</div>
    </div>
  );
}

function SectionHeader({ icon, title }) {
  return (
    <div className="st-section-header">
      <span className="st-section-icon" aria-hidden="true">{icon}</span>
      <span className="st-section-title">{title}</span>
    </div>
  );
}

export default function Settings() {
  const [settings, setSettings] = useState(() => loadSettings());
  const [toast, setToast] = useState(false);

  const update = (key, value) => {
    const next = { ...settings, [key]: value };
    setSettings(next);
    saveSettings(next);
    setToast(true);
    setTimeout(() => setToast(false), 1800);
  };

  const handleReset = () => {
    setSettings({ ...DEFAULT_SETTINGS });
    saveSettings({ ...DEFAULT_SETTINGS });
    setToast(true);
    setTimeout(() => setToast(false), 1800);
  };

  return (
    <main className="st-page">
      {/* Breadcrumb */}
      <nav className="profile-breadcrumb" aria-label="Breadcrumb">
        <a href="/" className="profile-breadcrumb-link">Home</a>
        <span className="profile-breadcrumb-separator" aria-hidden="true">|</span>
        <a href="/profile" className="profile-breadcrumb-link">Profile</a>
        <span className="profile-breadcrumb-separator" aria-hidden="true">|</span>
        <span className="profile-breadcrumb-current" aria-current="page">Settings</span>
      </nav>

      <div className="st-header">
        <h1 className="st-title">Settings</h1>
        <p className="st-subtitle">Manage your WaveSafe preferences. Changes are saved instantly.</p>
      </div>

      <div className="st-content">

        {/* Notifications */}
        <section className="st-section">
          <SectionHeader icon="🔔" title="Notifications" />
          <SettingsRow label="SOS Alerts" hint="Get alerted when your contacts trigger an SOS.">
            <Toggle
              id="notif-sos"
              checked={settings.notifications_sos}
              onChange={(v) => update("notifications_sos", v)}
            />
          </SettingsRow>
          <SettingsRow label="Weather Warnings" hint="Receive alerts for unsafe beach conditions.">
            <Toggle
              id="notif-weather"
              checked={settings.notifications_weather}
              onChange={(v) => update("notifications_weather", v)}
            />
          </SettingsRow>
          <SettingsRow label="Trip Reminders" hint="Reminders about your upcoming beach trips.">
            <Toggle
              id="notif-trip"
              checked={settings.notifications_trip}
              onChange={(v) => update("notifications_trip", v)}
            />
          </SettingsRow>
        </section>

        {/* Privacy */}
        <section className="st-section">
          <SectionHeader icon="🔒" title="Privacy & Location" />
          <SettingsRow label="Live Location Sharing" hint="Share your location during active trips or SOS events.">
            <Toggle
              id="loc-sharing"
              checked={settings.location_sharing}
              onChange={(v) => update("location_sharing", v)}
            />
          </SettingsRow>
        </section>

        {/* Offline */}
        <section className="st-section">
          <SectionHeader icon="📶" title="Connectivity" />
          <SettingsRow label="Offline Mode" hint="Cache beach data for use without internet.">
            <Toggle
              id="offline"
              checked={settings.offline_mode}
              onChange={(v) => update("offline_mode", v)}
            />
          </SettingsRow>
        </section>

        {/* Appearance */}
        <section className="st-section">
          <SectionHeader icon="🎨" title="Appearance" />
          <SettingsRow label="Dark Mode" hint="Currently a preview; full dark theme coming soon.">
            <Toggle
              id="dark-mode"
              checked={settings.dark_mode}
              onChange={(v) => update("dark_mode", v)}
            />
          </SettingsRow>
        </section>

        {/* Preferences */}
        <section className="st-section">
          <SectionHeader icon="⚙️" title="Preferences" />
          <SettingsRow label="Language">
            <select
              className="st-select"
              value={settings.language}
              onChange={(e) => update("language", e.target.value)}
              aria-label="Language"
            >
              <option value="en">English</option>
              <option value="hi">हिन्दी</option>
              <option value="mr">मराठी</option>
              <option value="gu">ગુજરાતી</option>
              <option value="ta">தமிழ்</option>
              <option value="te">తెలుగు</option>
              <option value="kn">ಕನ್ನಡ</option>
              <option value="ml">മലയാളം</option>
            </select>
          </SettingsRow>
          <SettingsRow label="Units" hint="Used for wave height, temperature, and wind speed.">
            <select
              className="st-select"
              value={settings.units}
              onChange={(e) => update("units", e.target.value)}
              aria-label="Measurement units"
            >
              <option value="metric">Metric (m, °C, km/h)</option>
              <option value="imperial">Imperial (ft, °F, mph)</option>
            </select>
          </SettingsRow>
        </section>

        {/* Reset */}
        <div className="st-reset-area">
          <button className="st-reset-btn" onClick={handleReset} type="button">
            Reset to Defaults
          </button>
        </div>
      </div>

      {/* Toast */}
      {toast && (
        <div className="st-toast" role="status" aria-live="polite">
          ✓ Settings saved
        </div>
      )}
    </main>
  );
}
