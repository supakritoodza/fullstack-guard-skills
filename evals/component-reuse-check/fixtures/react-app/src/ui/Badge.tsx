export function Badge({ tone = "neutral", label }: { tone?: "neutral" | "good" | "bad"; label: string }) { return <span className={`badge badge-${tone}`}>{label}</span>; }
