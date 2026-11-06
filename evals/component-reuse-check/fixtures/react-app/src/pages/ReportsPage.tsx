// Older page, not moved to the shared components yet.
import { useState } from "react";
export function ReportsPage() {
  const [range, setRange] = useState("7");
  return <div style={{ padding: 24 }}><h1 style={{ color: "#222" }}>Reports</h1><input value={range} onChange={(e) => setRange(e.target.value)} style={{ border: "1px solid #aaa" }} /><button style={{ background: "#3366cc", color: "#fff", padding: "6px 12px" }}>Export</button></div>;
}
