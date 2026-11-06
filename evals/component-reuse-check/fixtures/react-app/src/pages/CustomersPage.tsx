import { useState } from "react";
import { AppShell } from "../shell/AppShell";
import { PageHeader } from "../ui/PageHeader";
import { TextField } from "../ui/TextField";
import { Switch } from "../shared/controls/Switch";
import { CustomerCard } from "../features/customers/components/CustomerCard";
export function CustomersPage() {
  const [q, setQ] = useState(""); const [vip, setVip] = useState(false);
  return <AppShell><PageHeader title="Customers" /><TextField label="Search" value={q} onChange={setQ} /><Switch label="VIP only" checked={vip} onChange={setVip} /><CustomerCard name="Ana" email="ana@example.com" /></AppShell>;
}
