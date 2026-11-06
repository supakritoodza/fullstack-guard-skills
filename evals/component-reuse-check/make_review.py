#!/usr/bin/env python3
"""Add a Settings page that rebuilds nine things the project already has.

Usage: make_review.py <react-app|django-app> <project-dir>
The review eval commits this on a branch and asks for a review.
"""
import sys
from pathlib import Path

REACT = {
    "src/components/ToggleSwitch.tsx": '''export function ToggleSwitch({ on, set }: { on: boolean; set: (v: boolean) => void }) {
  return <input type="checkbox" checked={on} onChange={(e) => set(e.target.checked)} />;
}
''',
    "src/pages/SettingsPage.tsx": '''import { useState } from "react";
import { ToggleSwitch } from "../components/ToggleSwitch";

export function SettingsPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [notify, setNotify] = useState(true);
  const [saved, setSaved] = useState(false);
  const [asking, setAsking] = useState(false);
  return (
    <div style={{ display: "flex" }}>
      <aside style={{ width: 200 }}><a href="/">Dashboard</a><a href="/orders">Orders</a></aside>
      <main style={{ padding: 24 }}>
        <h1 style={{ fontSize: 24 }}>Settings</h1>
        {saved && <div style={{ color: "#0a0" }}>Saved</div>}
        <label>Name <input value={name} onChange={(e) => setName(e.target.value)} /></label>
        <label>Email <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} /></label>
        <ToggleSwitch on={notify} set={setNotify} /> Email notifications
        <button style={{ background: "#3366cc", color: "#fff" }} onClick={() => setSaved(true)}>
          <svg viewBox="0 0 24 24" width="16"><path d="M5 3h11l3 3v15H5z" /></svg> Save
        </button>
        <button style={{ background: "#cc3333", color: "#fff" }} onClick={() => setAsking(true)}>
          <svg viewBox="0 0 24 24" width="16"><path d="M6 7h12l-1 14H7z" /></svg> Delete account
        </button>
        {asking && (
          <div style={{ position: "fixed", background: "#fff" }}>
            <p>Delete your account?</p>
            <button onClick={() => setAsking(false)}>Cancel</button>
            <button onClick={() => setAsking(false)}>Delete</button>
          </div>
        )}
      </main>
    </div>
  );
}
''',
}

DJANGO = {
    "templates/partials/settings_toggle.html": '<input type="checkbox" name="{{ name }}"> {{ label }}\n',
    "templates/pages/settings.html": '''<!doctype html><html><body style="display:flex">
<aside style="width:200px"><a href="/">Dashboard</a><a href="/orders/">Orders</a></aside>
<main style="padding:24px"><h1 style="font-size:24px">Settings</h1>
{% if saved %}<div style="color:#0a0">Saved</div>{% endif %}
<form method="post">{% csrf_token %}
<label>Name <input name="name"></label><label>Email <input type="email" name="email"></label>
{% include "partials/settings_toggle.html" with name="notify" label="Email notifications" %}
<button style="background:#3366cc;color:#fff"><svg viewBox="0 0 24 24" width="16"><path d="M5 3h11l3 3v15H5z"/></svg> Save</button></form>
<button style="background:#cc3333;color:#fff" onclick="document.getElementById('ask').hidden=false"><svg viewBox="0 0 24 24" width="16"><path d="M6 7h12l-1 14H7z"/></svg> Delete account</button>
<div id="ask" style="position:fixed;background:#fff" hidden><p>Delete your account?</p><form method="post">{% csrf_token %}<button name="delete">Delete</button></form></div>
</main></body></html>
''',
}

if __name__ == "__main__":
    root = Path(sys.argv[2])
    for rel, text in {"react-app": REACT, "django-app": DJANGO}[sys.argv[1]].items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
