import { Button } from "../../../ui/Button";
type Props = { open: boolean; title: string; body: string; confirmLabel: string; onConfirm: () => void; onCancel: () => void };
export function ConfirmSheet({ open, title, body, confirmLabel, onConfirm, onCancel }: Props) {
  if (!open) return null;
  return <div role="dialog" aria-modal="true" className="sheet"><h2>{title}</h2><p>{body}</p><Button variant="secondary" onClick={onCancel}>Cancel</Button><Button variant="danger" onClick={onConfirm}>{confirmLabel}</Button></div>;
}
