import { useState } from "react";
import { AppShell } from "../shell/AppShell";
import { PageHeader } from "../ui/PageHeader";
import { Button } from "../ui/Button";
import { Table } from "../ui/Table";
import { Pagination } from "../ui/Pagination";
import { TrashIcon } from "../shared/icons";
import { Notice } from "../shared/Notice";
import { OrderRow } from "../features/orders/components/OrderRow";
import { ConfirmSheet } from "../features/orders/components/ConfirmSheet";
export function OrdersPage() {
  const [page, setPage] = useState(1); const [ask, setAsk] = useState(false); const [done, setDone] = useState(false);
  return <AppShell><PageHeader title="Orders" actions={<Button variant="danger" icon={<TrashIcon />} onClick={() => setAsk(true)}>Cancel all</Button>} />
    {done && <Notice tone="success">Orders cancelled.</Notice>}
    <Table head={["ID", "Status"]}><OrderRow id="1001" status="Paid" /></Table><Pagination page={page} onPage={setPage} />
    <ConfirmSheet open={ask} title="Cancel all orders?" body="This cannot be undone." confirmLabel="Cancel all" onCancel={() => setAsk(false)} onConfirm={() => { setAsk(false); setDone(true); }} /></AppShell>;
}
