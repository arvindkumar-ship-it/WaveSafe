import { useState, useMemo } from "react";
import { getAuthSession } from "../../services/auth";
import "./EmergencyContact.css";

const STORAGE_KEY_PREFIX = "wavesafe.emergency.";

function getStorageKey() {
  try {
    const session = getAuthSession();
    return session?.user_id ? `${STORAGE_KEY_PREFIX}${session.user_id}` : `${STORAGE_KEY_PREFIX}guest`;
  } catch {
    return `${STORAGE_KEY_PREFIX}guest`;
  }
}

function loadContacts() {
  try {
    const raw = localStorage.getItem(getStorageKey());
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveContacts(contacts) {
  try {
    localStorage.setItem(getStorageKey(), JSON.stringify(contacts));
  } catch {}
}

const RELATION_OPTIONS = ["Parent", "Spouse", "Sibling", "Friend", "Guardian", "Other"];

export default function EmergencyContact() {
  const [contacts, setContacts] = useState(() => loadContacts());
  const [showForm, setShowForm] = useState(false);
  const [editIndex, setEditIndex] = useState(null);
  const [form, setForm] = useState({ name: "", phone: "", relation: "" });
  const [errors, setErrors] = useState({});
  const [toast, setToast] = useState(null);

  const showToast = (msg, type = "success") => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 2800);
  };

  const validate = () => {
    const e = {};
    if (!form.name.trim()) e.name = "Name is required";
    if (!form.phone.trim()) e.phone = "Phone number is required";
    else if (!/^[6-9]\d{9}$/.test(form.phone.trim())) e.phone = "Enter a valid 10-digit Indian mobile number";
    if (!form.relation) e.relation = "Please select a relation";
    return e;
  };

  const handleOpenAdd = () => {
    setForm({ name: "", phone: "", relation: "" });
    setErrors({});
    setEditIndex(null);
    setShowForm(true);
  };

  const handleEdit = (idx) => {
    setForm({ ...contacts[idx] });
    setErrors({});
    setEditIndex(idx);
    setShowForm(true);
  };

  const handleDelete = (idx) => {
    const updated = contacts.filter((_, i) => i !== idx);
    setContacts(updated);
    saveContacts(updated);
    showToast("Contact removed.");
  };

  const handleSave = () => {
    const e = validate();
    if (Object.keys(e).length) { setErrors(e); return; }
    let updated;
    if (editIndex !== null) {
      updated = contacts.map((c, i) => (i === editIndex ? { ...form } : c));
      showToast("Contact updated!");
    } else {
      if (contacts.length >= 3) { showToast("Maximum 3 emergency contacts allowed.", "error"); return; }
      updated = [...contacts, { ...form }];
      showToast("Contact added!");
    }
    setContacts(updated);
    saveContacts(updated);
    setShowForm(false);
  };

  const handleChange = (field, value) => {
    setForm((f) => ({ ...f, [field]: value }));
    if (errors[field]) setErrors((e) => ({ ...e, [field]: undefined }));
  };

  return (
    <main className="ec-page">
      {/* Breadcrumb */}
      <nav className="profile-breadcrumb" aria-label="Breadcrumb">
        <a href="/" className="profile-breadcrumb-link">Home</a>
        <span className="profile-breadcrumb-separator" aria-hidden="true">|</span>
        <a href="/profile" className="profile-breadcrumb-link">Profile</a>
        <span className="profile-breadcrumb-separator" aria-hidden="true">|</span>
        <span className="profile-breadcrumb-current" aria-current="page">Emergency Contact</span>
      </nav>

      <div className="ec-header">
        <h1 className="ec-title">Emergency Contacts</h1>
        <p className="ec-subtitle">
          These contacts will be notified during an SOS alert. You can add up to 3.
        </p>
      </div>

      {/* Contact Cards */}
      <section className="ec-list" aria-label="Saved emergency contacts">
        {contacts.length === 0 ? (
          <div className="ec-empty">
            <div className="ec-empty-icon" aria-hidden="true">
              <svg width="56" height="56" viewBox="0 0 35 38" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M17.5 4.354a9.12 9.12 0 0 1 5.744 2.225 8.88 8.88 0 0 1 3.086 5.097 8.844 8.844 0 0 1-.92 5.45 8.983 8.983 0 0 1-3.911 3.753 9.1 9.1 0 0 1-5.263.785 9.045 9.045 0 0 1-4.745-2.426 8.867 8.867 0 0 1-2.512-4.684 8.835 8.835 0 0 1 .538-5.193 8.957 8.957 0 0 1 3.26-3.983A9.115 9.115 0 0 1 17.5 4.354Z" stroke="#0D7385" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M17.5 21.69c7.526 0 13.459 5.44 13.459 8.15V33.646H4.042V29.84C4.042 27.13 9.974 21.69 17.5 21.69Z" stroke="#0D7385" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
            <p className="ec-empty-text">No emergency contacts added yet.</p>
            <p className="ec-empty-hint">Add someone who should be alerted when you trigger an SOS.</p>
          </div>
        ) : (
          contacts.map((c, i) => (
            <div key={i} className="ec-card">
              <div className="ec-card-avatar" aria-hidden="true">
                {c.name.trim().charAt(0).toUpperCase()}
              </div>
              <div className="ec-card-info">
                <div className="ec-card-name">{c.name}</div>
                <div className="ec-card-meta">
                  <span className="ec-relation-badge">{c.relation}</span>
                  <span className="ec-card-phone">{c.phone}</span>
                </div>
              </div>
              <div className="ec-card-actions">
                <button className="ec-btn-icon ec-btn-edit" onClick={() => handleEdit(i)} aria-label={`Edit ${c.name}`} title="Edit">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
                <button className="ec-btn-icon ec-btn-delete" onClick={() => handleDelete(i)} aria-label={`Remove ${c.name}`} title="Remove">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
                </button>
              </div>
            </div>
          ))
        )}
      </section>

      {/* Add Button */}
      {contacts.length < 3 && !showForm && (
        <button className="ec-add-btn" onClick={handleOpenAdd}>
          <span className="ec-add-plus" aria-hidden="true">+</span> Add Emergency Contact
        </button>
      )}

      {/* Form Modal */}
      {showForm && (
        <div className="ec-modal-overlay" role="dialog" aria-modal="true" aria-label="Emergency contact form">
          <div className="ec-modal">
            <h2 className="ec-modal-title">{editIndex !== null ? "Edit Contact" : "Add Emergency Contact"}</h2>

            <div className="ec-field">
              <label className="ec-label" htmlFor="ec-name">Full Name</label>
              <input
                id="ec-name"
                className={`ec-input ${errors.name ? "ec-input--error" : ""}`}
                type="text"
                placeholder="e.g. Ramesh Sharma"
                value={form.name}
                onChange={(e) => handleChange("name", e.target.value)}
                maxLength={60}
              />
              {errors.name && <span className="ec-error">{errors.name}</span>}
            </div>

            <div className="ec-field">
              <label className="ec-label" htmlFor="ec-phone">Mobile Number</label>
              <input
                id="ec-phone"
                className={`ec-input ${errors.phone ? "ec-input--error" : ""}`}
                type="tel"
                placeholder="10-digit mobile number"
                value={form.phone}
                onChange={(e) => handleChange("phone", e.target.value.replace(/\D/g, "").slice(0, 10))}
                inputMode="numeric"
              />
              {errors.phone && <span className="ec-error">{errors.phone}</span>}
            </div>

            <div className="ec-field">
              <label className="ec-label" htmlFor="ec-relation">Relation</label>
              <select
                id="ec-relation"
                className={`ec-input ec-select ${errors.relation ? "ec-input--error" : ""}`}
                value={form.relation}
                onChange={(e) => handleChange("relation", e.target.value)}
              >
                <option value="">Select relation…</option>
                {RELATION_OPTIONS.map((r) => (
                  <option key={r} value={r}>{r}</option>
                ))}
              </select>
              {errors.relation && <span className="ec-error">{errors.relation}</span>}
            </div>

            <div className="ec-modal-actions">
              <button className="ec-btn-cancel" onClick={() => setShowForm(false)}>Cancel</button>
              <button className="ec-btn-save" onClick={handleSave}>
                {editIndex !== null ? "Save Changes" : "Add Contact"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast */}
      {toast && (
        <div className={`ec-toast ec-toast--${toast.type}`} role="status" aria-live="polite">
          {toast.msg}
        </div>
      )}
    </main>
  );
}
