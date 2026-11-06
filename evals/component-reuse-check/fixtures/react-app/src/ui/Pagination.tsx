import { Button } from "./Button";
export function Pagination({ page, onPage }: { page: number; onPage: (p: number) => void }) {
  return <nav className="pagination"><Button variant="secondary" onClick={() => onPage(page - 1)}>Prev</Button><Button variant="secondary" onClick={() => onPage(page + 1)}>Next</Button></nav>;
}
