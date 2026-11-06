import { Card } from "../../../ui/Card";
export function CustomerCard({ name, email }: { name: string; email: string }) { return <Card title={name}>{email}</Card>; }
