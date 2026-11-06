import type { ReactNode } from "react";
export function Notice({ tone = "info", children }: { tone?: "info" | "success" | "error"; children: ReactNode }) {
  return <div role="status" className={`notice notice-${tone}`}>{children}</div>;
}
