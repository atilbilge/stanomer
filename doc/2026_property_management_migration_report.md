# Portfolio Digitization & Migration Result Report

**Client:** Axia Exclusive Real Estate & Property Management  
**Prepared by:** Stanomer Property Management Technologies  
**Date:** October 21, 2026  
**Scope:** 36 Managed Units — Belgrade Portfolio  
**Export Deliverables:**
- [Official PDF Report](file:///Users/atilbilgeorum/projects/stanomer/doc/2026_property_management_migration_report.pdf)
- [Portfolio & Financial Dataset (Excel / XLSX)](file:///Users/atilbilgeorum/projects/stanomer/doc/2026_property_management_migration_data.xlsx)

---

### Executive Summary

All records for the **36 managed luxury residential units** in the Axia Exclusive portfolio—including active lease agreements, landlord and tenant profiles, 2026 rent schedules and collections, utility invoices (Infostan, Electricity, Building Maintenance, Parking, Internet), and property operations logs (Dnevnik Događaja)—have been systematically imported, reconciled, and verified on the Stanomer platform.

The data migration covered 36 property folders, 35 master lease lines, 36 individual unit tracking sheets, and 738 scanned utility invoices, mapping them seamlessly into Stanomer's operational calendar.

---

### 1. Data Sources, Imported Records, and Reconciliation Statistics

| Data Category | Source Volume (Excel/PDF) | Imported to Stanomer | Excluded / Filtered Out | Reconciliation & Filtering Criteria |
| :--- | :---: | :---: | :---: | :--- |
| **Managed Properties** | 36 Folders / 36 Tracking Sheets | **36 Properties** | 0 | Belgrade Waterfront, Landmark, West 65, and A Blok units fully mapped. |
| **Lease Contracts** | 35 Master Lines | **34 Active Contracts** | 2 Properties | `BW PERLA 2401` and `ST. REGIS 3607` recorded as newly handed-over vacant units. |
| **2026 Rent Payments** | 210 Excel Rows | **194 Current Rent Items** | 16 Rows | Pre-2026 historical rows moved outside the current accounting calendar to the tenancy inception archive. |
| **Utility Bills & Expenses** | 738 PDFs + ~850 Excel Rows | **668 Verified Invoices** | 182 Rows | Duplicate subtotals (UKUPNO, TOTAL), empty lines, and pre-2026 archives filtered out of the current calendar. |
| **Operations Log (Dnevnik)** | 433 Note Entries | **356 Operation Records** | 77 Rows | Empty separators and single-word checklist marks omitted; technical service, delivery, and maintenance logs preserved. |
| **Total Financial Transactions** | 1,060 Rows | **862 Transactions** | 198 Rows | 194 Rent + 668 Utility items verified and booked for the 2026 calendar year. |

---

### 2. Migration Principles and Scope Decisions

#### 2.1. Scope: January 1, 2026 and onwards, per Axia's request
Financial and operational tracking has been structured covering January 1, 2026 and onwards, as requested by Axia.

#### 2.2. Annual Renewal Chain
For contracts with an annual renewal chain, the most recent contract year has been imported into the system. The original initial start date of the tenancy is preserved in the property records.

#### 2.3. Proportional Allocation of Partial Utility Payments
When a tenant payment was less than the total monthly utility debt, the amount was distributed proportionally across the corresponding utility bills (Infostan, Electricity, Maintenance). The settled portion was cleared, and the remainder was booked as an outstanding payable.

#### 2.4. Cash Rounding Tolerance (1 RSD)
As the smallest cash denomination in Serbia is 1 RSD, minor rounding differences under 1 Dinar arising from banking or decimal conversions were treated as settled within reconciliation tolerance.

#### 2.5. Expense Category Standardization
Building management nomenclature has been standardized into 5 core operational categories:
1. **Infostan** (Municipal Services / Utilities)
2. **Electricity** (EPS)
3. **Building Maintenance** (Building Management & Common Areas)
4. **Parking** (Garage & Dedicated Parking Space)
5. **Internet/TV** (Broadband & Cable TV)

#### 2.6. Contact Information & Direct Invitation Infrastructure
No synthetic or placeholder email addresses were generated for owners or tenants without an existing email; fields were left blank to allow the agency to enter verified contact details and dispatch invitations directly.

---

### 3. Portfolio Overview & Unit Status (36 Properties)

| # | Property Name | Landlord / Entity | Active Tenant | Contract Period | Monthly Rent | Status |
| :---: | :--- | :--- | :--- | :---: | :---: | :---: |
| **1** | **BW TERRACES 104** | Asseria Stone Partners | Narcis Bečirović | 20.11.2025 - 19.11.2026 | 2,500 EUR | Tenanted |
| **2** | **BW TERRACES 207** | Asseria Stone Partners | Kostiantyn Kuzmenko | 02.12.2025 - 01.12.2026 | 2,600 EUR | Tenanted |
| **3** | **BW SIMFONIA 1501** | Growth Edge DOO | Myroslav Plakhotia | 29.04.2025 - 30.10.2026 | 1,800 EUR | Tenanted |
| **4** | **BW SOLE 1401** | Growth Edge DOO | Abstract doo | 01.08.2024 - 31.12.2026 | 1,800 EUR | Tenanted |
| **5** | **BW RESIDENCES 402** | Growth Edge | Borko Grecic | 13.05.2026 - 12.05.2027 | 3,500 EUR | Tenanted |
| **6** | **BW AQUA 1607** | Mimić Aleksandar | Aleksei Shkarin | 01.12.2025 - 01.12.2029 | 1,500 EUR | Tenanted |
| **7** | **BW AQUA 1807** | Mimić Aleksandar | Lidia Pavlova, Ivan Senikov | 06.11.2025 - 05.11.2026 | 1,550 EUR | Tenanted |
| **8** | **WEST 9.1** | Growth Edge DOO | EKO SERBIA AD | 01.11.2025 - 31.10.2027 | 2,200 EUR | Tenanted |
| **9** | **WEST 18.1** | Growth Edge DOO | Portfolio Management | 08.04.2025 - 31.03.2027 | 2,450 EUR | Tenanted |
| **10** | **A BLOK** | Asseria Stone Partners | Marko Nikollić | 01.10.2025 - 30.09.2026 | 1,500 EUR | Tenanted |
| **11** | **C 7.28 LANDMARK** | Asseria Stone Partners | Sigitov Denis, Alena Safronova | 24.06.2026 - 23.06.2027 | 2,300 EUR | Tenanted |
| **12** | **C 8.35 LANDMARK** | Asseria Stone Partners | Rade Jerinic | 22.07.2025 - 21.07.2027 | 1,900 EUR | Tenanted |
| **13** | **B 7.37 LANDMARK** | Asseria Stone Partners | Branko Pavlovic | 01.06.2025 - 31.05.2027 | 2,300 EUR | Tenanted |
| **14** | **B 8.47 LANDMARK** | Asseria Stone Partners | Slavica Jovanovic | 04.04.2026 - 03.04.2027 | 1,700 EUR | Tenanted |
| **15** | **A 5.17 LANDMARK** | Asseria Stone Partners | Maja Vukovic | 02.09.2025 - 01.09.2027 | 1,600 EUR | Tenanted |
| **16** | **VILA SREMCICA** | Landlord | Marco Gajic | 01.10.2025 - 30.09.2026 | 1,200 EUR | Tenanted |
| **17** | **TERRACES 1304** | Landlord | Keith Camilleri | 11.01.2026 - 11.07.2026 | 4,000 EUR | Tenanted |
| **18** | **BW QUARTET C006** | Asseria Stone Partners | Eduard Samofal, Tatiana Morozova | 10.06.2026 - 09.06.2027 | 1,800 EUR | Tenanted |
| **19** | **BW RESIDENCES 1704** | Đorđević Saša | Vasyl Ruzov | 11.05.2026 - 10.05.2027 | 4,000 EUR | Tenanted |
| **20** | **BW PERLA 101** | Landlord | Simone Vuletic da Silva | 01.08.2026 - 31.07.2027 | 2,800 EUR | Tenanted |
| **21** | **BW PERLA 303** | Landlord | Ghter Lizaveta | 10.08.2026 - 09.08.2027 | 2,900 EUR | Tenanted |
| **22** | **BW PERLA 505** | Landlord | Jorge Arturo Acevedo | 01.08.2026 - 31.07.2027 | 2,700 EUR | Tenanted |
| **23** | **BW PERLA 804** | Landlord | Radmila Saradzic | 01.08.2026 - 31.07.2027 | 3,200 EUR | Tenanted |
| **24** | **BW PERLA 2301** | Landlord | Kirilov Aleksei, A. Saveleva | 15.09.2026 - 14.09.2027 | 4,500 EUR | Tenanted |
| **25** | **BW PERLA 2401** | Landlord | *Vacant (Available)* | *No Contract* | — | Vacant |
| **26** | **BW RIVIERA 206** | Landlord | Bojan Stanic | 01.09.2026 - 31.08.2027 | 3,500 EUR | Tenanted |
| **27** | **BW RIVIERA 1004** | Landlord | Philip Morris Services d.o.o. | 01.08.2026 - 31.07.2029 | 3,600 EUR | Tenanted |
| **28** | **BW RIVIERA 1104** | Landlord | Milica & Luka Vildoza | 15.08.2026 - 14.08.2027 | 3,800 EUR | Tenanted |
| **29** | **BW RIVIERA 1304** | Landlord | Artem Dzhangirian | 10.08.2026 - 09.08.2027 | 3,600 EUR | Tenanted |
| **30** | **BW RIVIERA 2104** | Landlord | Kabaev Ivan | 04.08.2026 - 03.08.2027 | 3,700 EUR | Tenanted |
| **31** | **BW RIVIERA 2203** | Landlord | Dominik Zane | 10.09.2026 - 09.09.2027 | 3,500 EUR | Tenanted |
| **32** | **BW RIVIERA 2304** | Landlord | Alexander Latinovic | 14.08.2026 - 13.08.2027 | 3,700 EUR | Tenanted |
| **33** | **ST. REGIS 2610** | Landlord | Ruza Vuksanovic | 01.10.2026 - 30.09.2027 | 5,000 EUR | Tenanted |
| **34** | **ST. REGIS 3306** | Landlord | Igor Gospic | 01.10.2026 - 30.09.2027 | 4,800 EUR | Tenanted |
| **35** | **ST. REGIS 3504** | Landlord | Nikola Jovanovic | 16.09.2026 - 30.04.2027 | 4,500 EUR | Tenanted |
| **36** | **ST. REGIS 3607** | Landlord | *Vacant (Available)* | *No Contract* | — | Vacant |

---

### 4. Export Deliverables & Live Reporting Options

1. **Official PDF Report:**
   - [2026_property_management_migration_report.pdf](file:///Users/atilbilgeorum/projects/stanomer/doc/2026_property_management_migration_report.pdf)
2. **Excel Financial & Portfolio Dataset:**
   - [2026_property_management_migration_data.xlsx](file:///Users/atilbilgeorum/projects/stanomer/doc/2026_property_management_migration_data.xlsx)
   *(Includes 4 dedicated tabs: Portfolio overview, 194 rent collections, 668 utility bills, and reconciliation summary)*
3. **Live Reporting via Stanomer Agency Portal:**
   - Instant PDF and Excel reports can be generated on demand with customizable date filters via the Stanomer Agency Portal (`/agency`).
