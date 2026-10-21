#!/usr/bin/env python3
import json
import os
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

BASE_DIR = "/Users/atilbilgeorum/projects/stanomer"
JSON_PREVIEW = os.path.join(BASE_DIR, "scripts/import_preview.json")
EXCEL_OUTPUT = os.path.join(BASE_DIR, "doc/2026_property_management_migration_data.xlsx")

with open(JSON_PREVIEW, "r", encoding="utf-8") as f:
    properties = json.load(f)

wb = openpyxl.Workbook()

header_fill = PatternFill(start_color="1A5EB8", end_color="1A5EB8", fill_type="solid")
header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
thin_border = Border(
    left=Side(style='thin', color='E2E8F0'),
    right=Side(style='thin', color='E2E8F0'),
    top=Side(style='thin', color='E2E8F0'),
    bottom=Side(style='thin', color='E2E8F0')
)

# Sheet 1: Portfolio Overview
ws_props = wb.active
ws_props.title = "Portfolio Overview (36 Units)"

headers_props = [
    "#", "Property Name", "Address / Building", "Landlord / Owner", "Current Tenant",
    "Contract Start", "Contract End", "Monthly Rent", "Currency", "Rent Records", "Utility Records", "Status"
]
ws_props.append(headers_props)

for col_num in range(1, len(headers_props) + 1):
    cell = ws_props.cell(1, col_num)
    cell.fill = header_fill
    cell.font = header_font
    cell.alignment = Alignment(horizontal="center" if col_num in [1, 6, 7, 9, 10, 11, 12] else "left", vertical="center")

for idx, p in enumerate(properties, 1):
    c = p.get("contract", {})
    owner = p.get("owner", {}).get("name") or "Unspecified"
    raw_tenant = p.get("tenant", {}).get("name")
    tenant = raw_tenant if raw_tenant else "Vacant (Available)"
    start_date = c.get("start_date") or "-"
    end_date = c.get("end_date") or "-"
    rent = c.get("monthly_rent", 0.0)
    curr = c.get("currency", "EUR")
    rents_count = len(p.get("rent_items", []))
    bills_count = len(p.get("bill_items", []))
    status = "Active Tenancy" if raw_tenant else "Vacant / Available"

    row = [idx, p.get("title", ""), p.get("address", ""), owner, tenant, start_date, end_date, rent, curr, rents_count, bills_count, status]
    ws_props.append(row)

# Sheet 2: 2026 Rent Payments
ws_rent = wb.create_sheet(title="2026 Rent Payments")
headers_rent = ["#", "Property Name", "Tenant", "Due Date", "Payment Date", "Due Amount", "Paid Amount", "Currency", "Status"]
ws_rent.append(headers_rent)
for col_num in range(1, len(headers_rent) + 1):
    cell = ws_rent.cell(1, col_num)
    cell.fill = header_fill
    cell.font = header_font
    cell.alignment = Alignment(horizontal="center", vertical="center")

rent_idx = 1
for p in properties:
    tenant = p.get("tenant", {}).get("name") or "Vacant"
    for r in p.get("rent_items", []):
        due = r.get("due_date", "")
        paid_date = r.get("paid_date") or "-"
        expected = r.get("amount", 0.0)
        paid = r.get("amount_paid", 0.0)
        curr = r.get("currency", "EUR")
        st = "Paid" if r.get("status") == "paid" else "Pending"
        ws_rent.append([rent_idx, p.get("title", ""), tenant, due, paid_date, expected, paid, curr, st])
        rent_idx += 1

# Sheet 3: 2026 Utilities & Expenses
ws_bills = wb.create_sheet(title="2026 Utilities & Expenses")
headers_bills = ["#", "Property Name", "Expense Category", "Billing Period / Month", "Bill Amount (RSD)", "Paid Amount (RSD)", "Remaining Balance (RSD)", "Status", "Notes"]
ws_bills.append(headers_bills)
for col_num in range(1, len(headers_bills) + 1):
    cell = ws_bills.cell(1, col_num)
    cell.fill = header_fill
    cell.font = header_font
    cell.alignment = Alignment(horizontal="center", vertical="center")

bill_idx = 1
for p in properties:
    for b in p.get("bill_items", []):
        cat = b.get("category", "")
        month = b.get("month_name") or b.get("due_date", "")
        amt = b.get("amount", 0.0)
        paid = b.get("amount_paid", 0.0)
        rem = max(0.0, amt - paid)
        st = "Paid" if b.get("status") == "paid" else ("Partially Paid" if paid > 0 else "Pending")
        desc = b.get("note", "")
        ws_bills.append([bill_idx, p.get("title", ""), cat, month, amt, paid, rem, st, desc])
        bill_idx += 1

# Sheet 4: Reconciliation & Filtering Summary
ws_stats = wb.create_sheet(title="Data Reconciliation Summary")
headers_stats = ["Data Category", "Source Volume (Excel/PDF)", "Imported into Stanomer", "Excluded / Filtered Out", "Reconciliation / Filtering Criteria"]
ws_stats.append(headers_stats)
for col_num in range(1, len(headers_stats) + 1):
    cell = ws_stats.cell(1, col_num)
    cell.fill = header_fill
    cell.font = header_font
    cell.alignment = Alignment(horizontal="center", vertical="center")

stats_rows = [
    ["Managed Properties", "36 Folders / 36 Tracking Sheets", "36 Properties", "0", "Belgrade Waterfront, Landmark, West 65, and A Blok units fully mapped."],
    ["Lease Contracts", "35 Master Lines", "34 Active Contracts", "2 Properties", "BW PERLA 2401 and ST. REGIS 3607 recorded as newly handed-over vacant units."],
    ["2026 Rent Payments", "210 Excel Rows", "194 Current Rent Items", "16 Rows", "Pre-2026 historical rows moved outside current calendar into contract inception archive."],
    ["Utility Bills & Expenses", "738 PDFs + ~850 Excel Rows", "668 Verified Invoices", "182 Rows", "Duplicate subtotals (UKUPNO, TOTAL), empty lines, and pre-2026 entries filtered out."],
    ["Operations Log (Dnevnik)", "433 Note Entries", "356 Operation Records", "77 Rows", "Empty separators and single-word checklist marks omitted; maintenance and handover logs preserved."],
    ["Total Financial Transactions", "1,060 Rows", "862 Transactions (194 Rent + 668 Bills)", "198 Rows", "All financial movements reconciled for current calendar year 2026."]
]
for r in stats_rows:
    ws_stats.append(r)

# Auto-adjust column widths
for sheet in wb.worksheets:
    for col in sheet.columns:
        max_len = max(len(str(cell.value or '')) for cell in col)
        col_letter = get_column_letter(col[0].column)
        sheet.column_dimensions[col_letter].width = max(max_len + 3, 12)

wb.save(EXCEL_OUTPUT)
print(f"[+] English Excel export generated: {EXCEL_OUTPUT}")
