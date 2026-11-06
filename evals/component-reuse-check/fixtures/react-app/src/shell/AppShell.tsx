import type { ReactNode } from "react";
import { NavLink } from "react-router-dom";
import { navItems } from "./nav";
export function AppShell({ children }: { children: ReactNode }) {
  return <div className="shell"><aside>{navItems.map((n) => <NavLink key={n.path} to={n.path}>{n.label}</NavLink>)}</aside><main>{children}</main></div>;
}
