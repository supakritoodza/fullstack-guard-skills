import type { ReactNode } from "react";
type Props = { variant?: "primary" | "secondary" | "danger"; icon?: ReactNode; disabled?: boolean; type?: "button" | "submit"; onClick?: () => void; children: ReactNode };
export function Button({ variant = "primary", icon, type = "button", ...rest }: Props) {
  return <button type={type} className={`btn btn-${variant}`} {...rest}>{icon}{rest.children}</button>;
}
