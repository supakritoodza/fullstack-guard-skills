export async function api<T>(path: string, init?: RequestInit): Promise<T> { const r = await fetch(`/api${path}`, init); if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.json(); }
