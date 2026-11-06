export function Switch({ label, checked, onChange }: { label: string; checked: boolean; onChange: (v: boolean) => void }) {
  return <label className="switch"><input type="checkbox" role="switch" checked={checked} onChange={(e) => onChange(e.target.checked)} />{label}</label>;
}
