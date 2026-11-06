#!/usr/bin/env python3
"""Grow a sample project into a messier one, like a repo several people have worked on.

Usage: make_large.py <react-app|django-app> <project-dir>
Adds about 250 files: feature folders, older pages that build their own controls, and
one-off copies of shared components. The original shared components stay as they are,
so the right answer does not change. Output is the same on every run.
"""
import sys
from pathlib import Path

FEATURES = """billing invoices refunds shipping returns inventory suppliers warehouses coupons
loyalty reviews tickets chat campaigns newsletters audit roles teams exports imports
webhooks tax currencies regions catalog pricing bundles giftcards subscriptions analytics""".split()
PARTS = ["List", "Row", "Filters", "Summary", "Form"]


def write(root, rel, text):
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def title(name):
    return name.capitalize()


def react(root):
    for i, feature in enumerate(FEATURES):
        name = title(feature)
        for part in PARTS:
            write(root, f"src/features/{feature}/components/{name}{part}.tsx",
                  f'import {{ Card }} from "../../../ui/Card";\n'
                  f'export function {name}{part}() {{ return <Card title="{name} {part}">{feature}</Card>; }}\n')
        if i % 3 == 0:  # older page, builds its own controls
            body = (f'export function {name}Page() {{\n  return <div style={{{{ padding: 24 }}}}><h1>{name}</h1>'
                    f'<input style={{{{ border: "1px solid #aaa" }}}} /><button style={{{{ background: "#3366cc" }}}}>Save</button></div>;\n}}\n')
        else:
            body = (f'import {{ AppShell }} from "../shell/AppShell";\nimport {{ PageHeader }} from "../ui/PageHeader";\n'
                    f'import {{ Button }} from "../ui/Button";\nimport {{ {name}List }} from "../features/{feature}/components/{name}List";\n'
                    f'export function {name}Page() {{ return <AppShell><PageHeader title="{name}" actions={{<Button>New</Button>}} /><{name}List /></AppShell>; }}\n')
        write(root, f"src/pages/{name}Page.tsx", body)

    # One-off copies people made instead of using the shared ones.
    write(root, "src/features/billing/components/BillingToggle.tsx",
          'export function BillingToggle({ on, set }: { on: boolean; set: (v: boolean) => void }) { return <input type="checkbox" checked={on} onChange={(e) => set(e.target.checked)} />; }\n')
    write(root, "src/features/tickets/components/Modal.tsx",
          'import type { ReactNode } from "react";\nexport function Modal({ children }: { children: ReactNode }) { return <div style={{ position: "fixed", background: "#fff" }}>{children}</div>; }\n')
    write(root, "src/features/audit/components/Alert.tsx",
          'export function Alert({ text }: { text: string }) { return <div style={{ color: "#0a0" }}>{text}</div>; }\n')
    write(root, "src/features/teams/components/Btn.tsx",
          'export function Btn({ label }: { label: string }) { return <button style={{ background: "#2255bb" }}>{label}</button>; }\n')
    # The closest existing page to the task is an old one.
    write(root, "src/pages/AccountPage.tsx", '''// Older page, not moved to the shared components yet.
import { useState } from "react";
export function AccountPage() {
  const [name, setName] = useState(""); const [saved, setSaved] = useState(false);
  return <div style={{ padding: 24 }}><h1>Account</h1>{saved && <div style={{ color: "#0a0" }}>Saved</div>}
    <input value={name} onChange={(e) => setName(e.target.value)} style={{ border: "1px solid #aaa" }} />
    <button style={{ background: "#3366cc", color: "#fff" }} onClick={() => setSaved(true)}>Save</button>
    <button style={{ background: "#cc3333", color: "#fff" }} onClick={() => window.confirm("Delete?")}>Delete</button></div>;
}
''')


def django(root):
    for i, feature in enumerate(FEATURES):
        for part in PARTS:
            write(root, f"templates/{feature}/_{part.lower()}.html",
                  f'{{% include "partials/card.html" with title="{title(feature)} {part}" body="{feature}" %}}\n')
        if i % 3 == 0:  # older page, builds its own controls
            body = (f'<!doctype html><html><body style="padding:24px"><h1>{title(feature)}</h1>'
                    f'<input style="border:1px solid #aaa"><button style="background:#3366cc">Save</button></body></html>\n')
        else:
            body = (f'{{% extends "layouts/app.html" %}}{{% block content %}}{{% include "partials/page_header.html" with title="{title(feature)}" %}}'
                    f'{{% include "partials/button.html" with label="New" %}}{{% include "{feature}/_list.html" %}}{{% endblock %}}\n')
        write(root, f"templates/pages/{feature}.html", body)

    write(root, "templates/billing/_toggle.html", '<input type="checkbox" name="{{ name }}">\n')
    write(root, "templates/tickets/_modal.html", '<div style="position:fixed;background:#fff">{{ body }}</div>\n')
    write(root, "templates/audit/_alert.html", '<div style="color:#0a0">{{ text }}</div>\n')
    write(root, "templates/teams/_btn.html", '<button style="background:#2255bb">{{ label }}</button>\n')
    write(root, "templates/pages/account.html", '''{# Older page, not moved to the shared partials yet. #}
<!doctype html><html><body style="padding:24px"><h1>Account</h1>{% if saved %}<div style="color:#0a0">Saved</div>{% endif %}
<form method="post">{% csrf_token %}<input name="name" style="border:1px solid #aaa"><button style="background:#3366cc;color:#fff">Save</button></form>
<button style="background:#cc3333;color:#fff" onclick="return confirm('Delete?')">Delete</button></body></html>
''')


if __name__ == "__main__":
    {"react-app": react, "django-app": django}[sys.argv[1]](Path(sys.argv[2]))
