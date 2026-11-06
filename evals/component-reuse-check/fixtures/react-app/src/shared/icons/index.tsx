const Icon = ({ d }: { d: string }) => <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path d={d} /></svg>;
export const SaveIcon = () => <Icon d="M5 3h11l3 3v15H5z" />;
export const TrashIcon = () => <Icon d="M6 7h12l-1 14H7zM9 3h6v2H9z" />;
export const UserIcon = () => <Icon d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zm-8 9c0-4 4-6 8-6s8 2 8 6z" />;
export const BellIcon = () => <Icon d="M6 16V10a6 6 0 0 1 12 0v6l2 2H4z" />;
export const GearIcon = () => <Icon d="M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8z" />;
export const BoxIcon = () => <Icon d="M3 7l9-4 9 4v10l-9 4-9-4z" />;
export const ChartIcon = () => <Icon d="M4 20V10h4v10zm6 0V4h4v16zm6 0v-7h4v7z" />;
