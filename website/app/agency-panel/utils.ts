import { AgencyRentPayment } from "./types";

/**
 * Groups and deduplicates rent and utility payments matching Flutter agency_dashboard_screen.dart:176-215 (_processRentPayments).
 *
 * Rules:
 * 1. Maintenance settlement records (is_maintenance === true) are preserved as-is.
 * 2. Regular rent and utility bills are grouped per property_id.
 * 3. Inside each property, bills are grouped per month (${year}-${month}).
 * 4. For each title in that month:
 *    - An entered bill (amount > 0) supersedes a placeholder bill (amount === 0).
 *    - A declared bill (status === 'declared') supersedes an undeclared bill.
 *    - A bill with receipt_url supersedes one without receipt_url.
 *    - Duplicate 0-amount placeholders with the same title are collapsed into one.
 * 5. Returns sorted list by due_date descending.
 */
export function processRentPayments(rawRows: AgencyRentPayment[]): AgencyRentPayment[] {
  if (!rawRows || rawRows.length === 0) return [];

  // Separate maintenance payments vs regular payments
  const maintenanceRows: AgencyRentPayment[] = [];
  const regularRows: AgencyRentPayment[] = [];

  for (const p of rawRows) {
    if (p.is_maintenance) {
      maintenanceRows.push(p);
    } else {
      regularRows.push(p);
    }
  }

  // Group regular payments by property_id
  const byProperty = new Map<string, AgencyRentPayment[]>();
  for (const p of regularRows) {
    const propId = p.property_id || "unknown";
    const list = byProperty.get(propId) || [];
    list.push(p);
    byProperty.set(propId, list);
  }

  const processedList: AgencyRentPayment[] = [];

  for (const propList of byProperty.values()) {
    // Group by month (${year}-${month})
    const groupedByMonth = new Map<string, AgencyRentPayment[]>();
    for (const p of propList) {
      let key = "unknown";
      if (p.due_date) {
        const datePart = p.due_date.split("T")[0];
        const parts = datePart.split("-");
        if (parts.length >= 2) {
          const y = parseInt(parts[0], 10);
          const m = parseInt(parts[1], 10);
          if (!isNaN(y) && !isNaN(m)) {
            key = `${y}-${m}`;
          }
        }
      }
      const list = groupedByMonth.get(key) || [];
      list.push(p);
      groupedByMonth.set(key, list);
    }

    // Select best entry by title in each month
    for (const monthList of groupedByMonth.values()) {
      const bestByTitle = new Map<string, AgencyRentPayment>();
      for (const p of monthList) {
        const title = (p.title || "Kira").trim().toLowerCase();
        const existing = bestByTitle.get(title);
        if (!existing) {
          bestByTitle.set(title, p);
        } else {
          const pAmount = Number(p.amount) || 0;
          const exAmount = Number(existing.amount) || 0;
          if (pAmount > 0 && exAmount === 0) {
            bestByTitle.set(title, p);
          } else if (p.status === "paid" && existing.status !== "paid") {
            bestByTitle.set(title, p);
          } else if (
            existing.status !== "paid" &&
            (p.status === "declared" || p.status === "disputed") &&
            existing.status !== "declared" &&
            existing.status !== "disputed"
          ) {
            bestByTitle.set(title, p);
          } else if (existing.status !== "paid" && p.receipt_url && !existing.receipt_url) {
            bestByTitle.set(title, p);
          }
        }
      }
      processedList.push(...Array.from(bestByTitle.values()));
    }
  }

  // Combine processed regular payments + maintenance requests
  const combined = [...processedList, ...maintenanceRows];

  // Sort due_date descending
  combined.sort((a, b) => {
    const aDate = a.due_date || "";
    const bDate = b.due_date || "";
    return bDate.localeCompare(aDate);
  });

  return combined;
}
