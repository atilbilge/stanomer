#!/usr/bin/env python3
import json
import os
import subprocess

BASE_DIR = "/Users/atilbilgeorum/projects/stanomer"
JSON_PREVIEW = os.path.join(BASE_DIR, "scripts/import_preview.json")
HTML_OUTPUT = os.path.join(BASE_DIR, "doc/2026_property_management_migration_report.html")
PDF_OUTPUT = os.path.join(BASE_DIR, "doc/2026_property_management_migration_report.pdf")

with open(JSON_PREVIEW, "r", encoding="utf-8") as f:
    properties = json.load(f)

html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Portfolio Digitization & Data Migration Report</title>
<style>
  @page {{
    size: A4;
    margin: 18mm 15mm 18mm 15mm;
  }}
  body {{
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    color: #1e293b;
    font-size: 10pt;
    line-height: 1.45;
    margin: 0;
    padding: 0;
  }}
  .header {{
    border-bottom: 2px solid #2563eb;
    padding-bottom: 12px;
    margin-bottom: 20px;
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
  }}
  .logo {{
    font-size: 22pt;
    font-weight: 800;
    color: #2563eb;
    letter-spacing: -0.5px;
  }}
  .report-title {{
    font-size: 14pt;
    font-weight: 700;
    color: #0f172a;
    margin-top: 4px;
  }}
  .meta {{
    font-size: 8.5pt;
    color: #64748b;
    text-align: right;
  }}
  h2 {{
    font-size: 11.5pt;
    font-weight: 700;
    color: #1e3a8a;
    border-bottom: 1px solid #cbd5e1;
    padding-bottom: 4px;
    margin-top: 22px;
    margin-bottom: 10px;
    page-break-after: avoid;
  }}
  h3 {{
    font-size: 10pt;
    font-weight: 600;
    color: #0f172a;
    margin-top: 12px;
    margin-bottom: 4px;
    page-break-after: avoid;
  }}
  p, li {{
    font-size: 9pt;
    color: #334155;
    margin: 4px 0;
  }}
  table {{
    width: 100%;
    border-collapse: collapse;
    margin: 12px 0;
    font-size: 8pt;
    page-break-inside: auto;
  }}
  tr {{
    page-break-inside: avoid;
    page-break-after: auto;
  }}
  th {{
    background-color: #f1f5f9;
    color: #0f172a;
    font-weight: 700;
    text-align: left;
    padding: 6px 8px;
    border: 1px solid #cbd5e1;
  }}
  td {{
    padding: 5px 8px;
    border: 1px solid #e2e8f0;
    vertical-align: top;
  }}
  .text-center {{ text-align: center; }}
  .text-right {{ text-align: right; }}
  .font-bold {{ font-weight: bold; }}
  .badge {{
    display: inline-block;
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 7.5pt;
    font-weight: 600;
  }}
  .badge-active {{ background-color: #dcfce7; color: #166534; }}
  .badge-vacant {{ background-color: #f1f5f9; color: #475569; }}
  .rule-box {{
    background-color: #f8fafc;
    border-left: 3px solid #2563eb;
    padding: 8px 12px;
    margin: 8px 0;
    border-radius: 0 4px 4px 0;
  }}
  .footer {{
    margin-top: 30px;
    border-top: 1px solid #e2e8f0;
    padding-top: 8px;
    font-size: 8pt;
    color: #94a3b8;
    text-align: center;
  }}
</style>
</head>
<body>

<div class="header">
  <div>
    <div class="logo">STANOMER</div>
    <div class="report-title">Portfolio Digitization & Migration Result Report</div>
  </div>
  <div class="meta">
    <strong>Client:</strong> Axia Exclusive Real Estate & Property Management<br>
    <strong>Date:</strong> October 21, 2026<br>
    <strong>Scope:</strong> 36 Managed Units — Belgrade Portfolio
  </div>
</div>

<h2>Executive Summary</h2>
<p>
All records for the <strong>36 managed luxury residential units</strong> in the Axia Exclusive portfolio—including active lease agreements, landlord and tenant profiles, 2026 rent schedules and collections, utility invoices (Infostan, Electricity, Building Maintenance, Parking, Internet), and property operations logs (Dnevnik Događaja)—have been systematically imported, reconciled, and verified on the Stanomer platform.
</p>

<h2>1. Data Sources, Imported Records, and Reconciliation Statistics</h2>
<table>
  <thead>
    <tr>
      <th>Data Category</th>
      <th class="text-center">Excel Source Volume</th>
      <th class="text-center">Imported to Stanomer</th>
      <th class="text-center">Excluded / Filtered Out</th>
      <th>Reconciliation & Filtering Criteria</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="font-bold">Managed Properties</td>
      <td class="text-center">36 Folders / 36 Files</td>
      <td class="text-center font-bold">36 Properties</td>
      <td class="text-center">0</td>
      <td>Belgrade Waterfront, Landmark, West 65, and A Blok units fully mapped.</td>
    </tr>
    <tr>
      <td class="font-bold">Lease Contracts</td>
      <td class="text-center">35 Master Lines</td>
      <td class="text-center font-bold">34 Active Contracts</td>
      <td class="text-center">2 Properties</td>
      <td>BW PERLA 2401 and ST. REGIS 3607 recorded as newly handed-over vacant units.</td>
    </tr>
    <tr>
      <td class="font-bold">2026 Rent Payments</td>
      <td class="text-center">210 Excel Rows</td>
      <td class="text-center font-bold">194 Current Rent Items</td>
      <td class="text-center">16 Rows</td>
      <td>Pre-2026 historical rows moved outside the current accounting calendar to the tenancy inception archive.</td>
    </tr>
    <tr>
      <td class="font-bold">Utility Bills & Expenses</td>
      <td class="text-center">738 PDFs + ~850 Excel Rows</td>
      <td class="text-center font-bold">668 Verified Invoices</td>
      <td class="text-center">182 Rows</td>
      <td>Duplicate subtotals (UKUPNO, TOTAL), empty lines, and pre-2026 archives filtered out of the current calendar.</td>
    </tr>
    <tr>
      <td class="font-bold">Operations Log (Dnevnik)</td>
      <td class="text-center">433 Note Entries</td>
      <td class="text-center font-bold">356 Operation Records</td>
      <td class="text-center">77 Rows</td>
      <td>Empty separators and single-word checklist marks omitted; technical service, delivery, and maintenance logs preserved.</td>
    </tr>
    <tr style="background-color: #f8fafc;">
      <td class="font-bold">Total Financial Transactions</td>
      <td class="text-center font-bold">1,060 Rows</td>
      <td class="text-center font-bold" style="color: #1e3a8a;">862 Transactions</td>
      <td class="text-center font-bold">198 Rows</td>
      <td>194 Rent + 668 Utility items verified and booked for the 2026 calendar year.</td>
    </tr>
  </tbody>
</table>

<h2>2. Migration Principles and Scope Decisions</h2>
<div class="rule-box">
  <h3>2.1. Scope: January 1, 2026 and onwards, per Axia's request</h3>
  <p>Financial and operational tracking has been structured covering January 1, 2026 and onwards, as requested by Axia.</p>
</div>

<div class="rule-box">
  <h3>2.2. Annual Renewal Chain</h3>
  <p>For contracts with an annual renewal chain, the most recent contract year has been imported into the system. The original initial start date of the tenancy is preserved in the property records.</p>
</div>

<div class="rule-box">
  <h3>2.3. Proportional Allocation of Partial Utility Payments</h3>
  <p>When a tenant payment was less than the total monthly utility debt, the amount was distributed proportionally across the corresponding utility bills (Infostan, Electricity, Maintenance). The settled portion was cleared, and the remainder was booked as an outstanding payable.</p>
</div>

<div class="rule-box">
  <h3>2.4. Cash Rounding Tolerance (1 RSD)</h3>
  <p>As the smallest cash denomination in Serbia is 1 RSD, minor rounding differences under 1 Dinar arising from banking or decimal conversions were treated as settled within reconciliation tolerance.</p>
</div>

<div class="rule-box">
  <h3>2.5. Expense Category Standardization</h3>
  <p>Building management nomenclature has been standardized into 5 core operational categories: Infostan (Municipal utilities), Electricity (EPS), Building Maintenance, Parking, and Internet/TV.</p>
</div>

<div class="rule-box">
  <h3>2.6. Contact Information & Direct Invitation Infrastructure</h3>
  <p>No synthetic or placeholder email addresses were generated for owners or tenants without an existing email; fields were left blank to allow the agency to enter verified contact details and dispatch invitations directly.</p>
</div>

<h2>3. Portfolio Overview & Unit Status (36 Properties)</h2>
<table>
  <thead>
    <tr>
      <th class="text-center" style="width: 20px;">#</th>
      <th>Property Name</th>
      <th>Landlord / Entity</th>
      <th>Active Tenant</th>
      <th class="text-center">Contract Period</th>
      <th class="text-right">Monthly Rent</th>
      <th class="text-center">Status</th>
    </tr>
  </thead>
  <tbody>
"""

for idx, p in enumerate(properties, 1):
    c = p.get("contract", {})
    owner = p.get("owner", {}).get("name") or "Unspecified"
    raw_tenant = p.get("tenant", {}).get("name")
    tenant = raw_tenant if raw_tenant else "Vacant (Available)"
    start_date = c.get("start_date") or "-"
    end_date = c.get("end_date") or "-"
    period = f"{start_date} – {end_date}" if start_date != "-" else "-"
    rent = c.get("monthly_rent", 0.0)
    curr = c.get("currency", "EUR")
    rent_str = f"{int(rent):,} {curr}".replace(",", ".") if rent > 0 else "-"
    is_active = bool(raw_tenant)
    badge_html = '<span class="badge badge-active">Tenanted</span>' if is_active else '<span class="badge badge-vacant">Vacant</span>'

    html_content += f"""    <tr>
      <td class="text-center font-bold">{idx}</td>
      <td class="font-bold">{p.get("title", "")}</td>
      <td>{owner}</td>
      <td>{tenant}</td>
      <td class="text-center">{period}</td>
      <td class="text-right font-bold">{rent_str}</td>
      <td class="text-center">{badge_html}</td>
    </tr>\n"""

html_content += """  </tbody>
</table>

<h2>4. Export Deliverables & Live Reporting</h2>
<p>
Comprehensive datasets and reports are available on the filesystem and through the Stanomer platform:
</p>
<ul>
  <li><strong>Official PDF Report:</strong> <code>doc/2026_property_management_migration_report.pdf</code></li>
  <li><strong>Excel Financial & Portfolio Dataset:</strong> <code>doc/2026_property_management_migration_data.xlsx</code> (Features 4 sheets: Portfolio list, 194 rent records, 668 bill line items, and reconciliation summary)</li>
  <li><strong>Agency Dashboard Live Reporting:</strong> Real-time PDF and Excel reports can be generated on demand with customizable date filters via the Stanomer Agency Portal (<code>/agency</code>).</li>
</ul>

<div class="footer">
  Stanomer Property Management Technologies &bull; Axia Exclusive Portfolio Report &bull; October 21, 2026
</div>

</body>
</html>
"""

with open(HTML_OUTPUT, "w", encoding="utf-8") as f:
    f.write(html_content)

print(f"[+] English HTML generated: {HTML_OUTPUT}")

chrome_path = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
cmd = [
    chrome_path,
    "--headless",
    "--disable-gpu",
    "--no-pdf-header-footer",
    f"--print-to-pdf={PDF_OUTPUT}",
    HTML_OUTPUT
]
res = subprocess.run(cmd, capture_output=True, text=True)
if res.returncode == 0:
    print(f"[+] English PDF generated successfully: {PDF_OUTPUT}")
else:
    print(f"[-] PDF generation error: {res.stderr}")
