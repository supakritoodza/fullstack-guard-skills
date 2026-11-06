import { AppShell } from "../shell/AppShell";
import { PageHeader } from "../ui/PageHeader";
import { Card } from "../ui/Card";
export function DashboardPage() { return <AppShell><PageHeader title="Dashboard" /><Card title="Today">12 orders</Card></AppShell>; }
