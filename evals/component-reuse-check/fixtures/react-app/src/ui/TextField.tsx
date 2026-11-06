type Props = { label: string; value: string; onChange: (v: string) => void; type?: "text" | "email"; error?: string };
export function TextField({ label, value, onChange, type = "text", error }: Props) {
  return <label className="field">{label}<input type={type} value={value} onChange={(e) => onChange(e.target.value)} />{error && <small>{error}</small>}</label>;
}
