import { Badge } from "../../../ui/Badge";
export function OrderRow({ id, status }: { id: string; status: string }) { return <tr><td>{id}</td><td><Badge label={status} /></td></tr>; }
