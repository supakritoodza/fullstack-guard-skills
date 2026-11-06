import { BrowserRouter, Routes, Route } from "react-router-dom";
import { DashboardPage } from "./pages/DashboardPage";
import { OrdersPage } from "./pages/OrdersPage";
import { CustomersPage } from "./pages/CustomersPage";
import { ReportsPage } from "./pages/ReportsPage";
export function App() {
  return <BrowserRouter><Routes><Route path="/" element={<DashboardPage />} /><Route path="/orders" element={<OrdersPage />} /><Route path="/customers" element={<CustomersPage />} /><Route path="/reports" element={<ReportsPage />} /></Routes></BrowserRouter>;
}
