import { useState } from "react";
import "./HelpSupport.css";

const FAQS = [
  {
    q: "How does the SOS feature work?",
    a: "When you trigger an SOS, WaveSafe immediately alerts your emergency contacts with your live GPS location. A distress signal is also sent to the nearest lifeguard station if one is registered in our system. The SOS stays active until you manually cancel it.",
  },
  {
    q: "How is beach safety data determined?",
    a: "Our safety verdicts (Safe, Caution, Danger) are calculated from live weather data, ocean wave heights, tide levels, wind speed, and official lifeguard reports. We combine these into a risk score updated every 30 minutes.",
  },
  {
    q: "Can I use WaveSafe without internet?",
    a: "Yes — enable Offline Mode in Settings. Beach data is cached on your device so you can view safety information even without a network connection. However, live SOS alerts and real-time updates require internet access.",
  },
  {
    q: "How do I add or change my emergency contacts?",
    a: "Go to Profile → Emergency Contact. You can add up to 3 contacts with their name, mobile number, and relation. These contacts will be notified instantly when an SOS is triggered.",
  },
  {
    q: "Is my location data private?",
    a: "Your location is only accessed during active trips or SOS events, and only shared with your designated emergency contacts. We do not sell or share your location with third parties. You can disable location sharing at any time in Settings.",
  },
  {
    q: "Why is a beach showing 'Caution' or 'Danger'?",
    a: "This means current conditions — such as high wave height, strong currents, poor visibility, or an active weather warning — make it risky to swim. Always respect the safety verdict and follow instructions from on-site lifeguards.",
  },
];

const CONTACT_METHODS = [
  {
    icon: "✉️",
    label: "Email Support",
    value: "support@wavesafe.in",
    href: "mailto:support@wavesafe.in",
    hint: "Response within 24 hours",
  },
  {
    icon: "💬",
    label: "WhatsApp",
    value: "+91 98765 43210",
    href: "https://wa.me/919876543210",
    hint: "Mon–Sat, 9 AM–6 PM IST",
  },
];

function FAQItem({ q, a }) {
  const [open, setOpen] = useState(false);
  return (
    <div className={`hs-faq-item ${open ? "hs-faq-item--open" : ""}`}>
      <button
        className="hs-faq-question"
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        type="button"
      >
        <span>{q}</span>
        <span className="hs-faq-chevron" aria-hidden="true">{open ? "▲" : "▼"}</span>
      </button>
      {open && <div className="hs-faq-answer">{a}</div>}
    </div>
  );
}

export default function HelpSupport() {
  const [feedbackSent, setFeedbackSent] = useState(false);
  const [feedback, setFeedback] = useState("");
  const [rating, setRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);

  const handleSendFeedback = () => {
    if (!feedback.trim() && rating === 0) return;
    setFeedbackSent(true);
    setFeedback("");
    setRating(0);
    setTimeout(() => setFeedbackSent(false), 4000);
  };

  return (
    <main className="hs-page">
      {/* Breadcrumb */}
      <nav className="profile-breadcrumb" aria-label="Breadcrumb">
        <a href="/" className="profile-breadcrumb-link">Home</a>
        <span className="profile-breadcrumb-separator" aria-hidden="true">|</span>
        <a href="/profile" className="profile-breadcrumb-link">Profile</a>
        <span className="profile-breadcrumb-separator" aria-hidden="true">|</span>
        <span className="profile-breadcrumb-current" aria-current="page">Help &amp; Support</span>
      </nav>

      <div className="hs-header">
        <h1 className="hs-title">Help &amp; Support</h1>
        <p className="hs-subtitle">Find answers, report issues, or reach our support team.</p>
      </div>

      <div className="hs-content">

        {/* Quick links */}
        <section className="hs-section">
          <h2 className="hs-section-title">Quick Links</h2>
          <div className="hs-quick-links">
            <a href="/sos" className="hs-quick-card hs-quick-card--red">
              <span className="hs-quick-icon" aria-hidden="true">🆘</span>
              <span>SOS / Emergency</span>
            </a>
            <a href="/beaches" className="hs-quick-card">
              <span className="hs-quick-icon" aria-hidden="true">🏖️</span>
              <span>Find a Beach</span>
            </a>
            <a href="/your-trips" className="hs-quick-card">
              <span className="hs-quick-icon" aria-hidden="true">🗺️</span>
              <span>My Trips</span>
            </a>
            <a href="/profile?tab=emergency" className="hs-quick-card">
              <span className="hs-quick-icon" aria-hidden="true">📞</span>
              <span>Emergency Contacts</span>
            </a>
          </div>
        </section>

        {/* FAQ */}
        <section className="hs-section">
          <h2 className="hs-section-title">Frequently Asked Questions</h2>
          <div className="hs-faq-list">
            {FAQS.map((faq, i) => (
              <FAQItem key={i} q={faq.q} a={faq.a} />
            ))}
          </div>
        </section>

        {/* Contact */}
        <section className="hs-section">
          <h2 className="hs-section-title">Contact Us</h2>
          <div className="hs-contact-list">
            {CONTACT_METHODS.map((m) => (
              <a key={m.label} href={m.href} className="hs-contact-card" target="_blank" rel="noreferrer">
                <span className="hs-contact-icon" aria-hidden="true">{m.icon}</span>
                <div className="hs-contact-info">
                  <span className="hs-contact-label">{m.label}</span>
                  <span className="hs-contact-value">{m.value}</span>
                  <span className="hs-contact-hint">{m.hint}</span>
                </div>
                <span className="hs-contact-arrow" aria-hidden="true">→</span>
              </a>
            ))}
          </div>
        </section>

        {/* Feedback */}
        <section className="hs-section">
          <h2 className="hs-section-title">Share Feedback</h2>
          <div className="hs-feedback-card">
            <p className="hs-feedback-prompt">How would you rate your WaveSafe experience?</p>
            <div className="hs-stars" role="group" aria-label="Star rating">
              {[1, 2, 3, 4, 5].map((n) => (
                <button
                  key={n}
                  className={`hs-star ${(hoverRating || rating) >= n ? "hs-star--filled" : ""}`}
                  onClick={() => setRating(n)}
                  onMouseEnter={() => setHoverRating(n)}
                  onMouseLeave={() => setHoverRating(0)}
                  aria-label={`${n} star${n > 1 ? "s" : ""}`}
                  type="button"
                >
                  ★
                </button>
              ))}
            </div>
            <textarea
              className="hs-feedback-input"
              placeholder="Tell us what you think — we read every message."
              value={feedback}
              onChange={(e) => setFeedback(e.target.value)}
              rows={4}
              maxLength={500}
              aria-label="Feedback message"
            />
            <div className="hs-feedback-footer">
              <span className="hs-char-count">{feedback.length}/500</span>
              <button
                className="hs-send-btn"
                onClick={handleSendFeedback}
                disabled={!feedback.trim() && rating === 0}
                type="button"
              >
                {feedbackSent ? "✓ Sent!" : "Send Feedback"}
              </button>
            </div>
          </div>
        </section>

        {/* App version */}
        <p className="hs-version">WaveSafe v1.0.0 · Made with 🌊 for India's coastline</p>
      </div>
    </main>
  );
}
