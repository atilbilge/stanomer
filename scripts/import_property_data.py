#!/usr/bin/env python3
"""
Stanomer Property Management 2026 Data Importer & Parser.
Parses property folders, master lease contracts, Excel financial sheets,
and utility bill PDFs (Infostan, EPS, Maintenance).

Usage:
    python3 scripts/import_property_data.py --dry-run
    python3 scripts/import_property_data.py --generate-sql
"""

import os
import sys
import re
import json
import glob
import uuid
import calendar
import datetime
from decimal import Decimal
import openpyxl
from pypdf import PdfReader

BASE_DIR = "/Users/atilbilgeorum/Downloads/PROPERTY MANAGEMENT"
MASTER_EXCEL = os.path.join(BASE_DIR, "Ugovori o zakupu - Property Menagment.xlsx")
TARGET_AGENCY_ID = "e4a8d708-acf2-4816-b59a-677c7656ce7c" # Profile ID
STANOMER_NAMESPACE = uuid.UUID("7b203417-640b-47b2-a42e-335b1c93a890")

# Serbian Month Translation
MONTH_MAP = {
    "JANUAR": 1,
    "FEBRUAR": 2,
    "MART": 3,
    "APRIL": 4,
    "MAJ": 5,
    "JUN": 6,
    "JUL": 7,
    "AVGUST": 8,
    "SEPTEMBAR": 9,
    "OKTOBAR": 10,
    "NOVEMBAR": 11,
    "DECEMBAR": 12,
}

def clean_amount(val):
    if val is None:
        return 0.0
    if isinstance(val, (int, float)):
        return float(val)
    val_str = str(val).strip()
    if not val_str:
        return 0.0
    val_str = re.sub(r"[^\d,\.]", "", val_str)
    
    # If both dot and comma exist: e.g. "82.472,32" or "82,472.32"
    if "," in val_str and "." in val_str:
        if val_str.rfind(",") > val_str.rfind("."):
            val_str = val_str.replace(".", "").replace(",", ".")
        else:
            val_str = val_str.replace(",", "")
    elif "." in val_str:
        parts = val_str.split(".")
        if len(parts) == 2 and len(parts[1]) == 3:
            val_str = parts[0] + parts[1]
    elif "," in val_str:
        parts = val_str.split(",")
        if len(parts) == 2 and len(parts[1]) == 3:
            val_str = parts[0] + parts[1]
        else:
            val_str = val_str.replace(",", ".")
            
    try:
        return float(val_str)
    except ValueError:
        return 0.0

def parse_deposit_full(dep_val, dep_paid_val, rent):
    for candidate in [dep_paid_val, dep_val]:
        if not candidate:
            continue
        s = str(candidate).replace("O", "0").replace("o", "0").strip()
        if re.match(r"^(da|yes)$", s, re.I):
            continue
            
        # Handle addition expressions like "2450 + 1000" or "1 zakupnina + 1.200"
        if "+" in s:
            parts = s.split("+")
            total = 0.0
            for p in parts:
                p_clean = p.lower()
                if "zakupnin" in p_clean:
                    m = re.search(r"(\d+(?:[\.,]\d+)?)\s*zakupnin", p_clean)
                    mult = float(m.group(1).replace(",", ".")) if m else 1.0
                    total += mult * rent
                else:
                    digits = re.sub(r"[^\d,\.]", "", p)
                    dot_parts = digits.split(".")
                    if len(dot_parts) == 2 and len(dot_parts[1]) == 3:
                        digits = dot_parts[0] + dot_parts[1]
                    try:
                        total += float(digits)
                    except ValueError:
                        pass
            if total > 50:
                return total
                
        # Handle "X zakupnina"
        s_lower = s.lower()
        if "zakupnin" in s_lower:
            m = re.search(r"(\d+(?:[\.,]\d+)?)\s*zakupnin", s_lower)
            if m:
                mult = float(m.group(1).replace(",", "."))
                return mult * rent
            if "1 ipo" in s_lower or "1 i po" in s_lower:
                return 1.5 * rent

        # Numeric parse
        digits = re.sub(r"[^\d,\.]", "", s)
        dot_parts = digits.split(".")
        if len(dot_parts) == 2 and len(dot_parts[1]) == 3:
            digits = dot_parts[0] + dot_parts[1]
        try:
            amt = float(digits)
            if amt > 50:
                return amt
        except ValueError:
            pass

    return rent

def parse_date(val):
    if val is None:
        return None
    if isinstance(val, (datetime.datetime, datetime.date)):
        return val.strftime("%Y-%m-%d")
    val_str = str(val).strip()
    if not val_str or val_str.lower() in ["none", "null", "-", ""]:
        return None
        
    day, month, year = None, None, None
    m = re.match(r"^(\d{1,2})[\./](\d{1,2})[\./](\d{2,4})", val_str)
    if m:
        day, month, year = int(m.group(1)), int(m.group(2)), int(m.group(3))
    else:
        m = re.match(r"^(\d{4})-(\d{1,2})-(\d{1,2})", val_str)
        if m:
            year, month, day = int(m.group(1)), int(m.group(2)), int(m.group(3))
            
    if year and month and day:
        # Fix year typos: e.g. 0206 -> 2026, 26 -> 2026
        if year == 206:
            year = 2026
        elif 20 <= year <= 40:
            year += 2000
            
        if month < 1 or month > 12:
            return None
            
        # Clamp day to maximum valid days for that month (e.g. 31 Nov -> 30 Nov)
        max_days = calendar.monthrange(year, month)[1]
        day = min(day, max_days)
        return f"{year:04d}-{month:02d}-{day:02d}"
        
    return None

def extract_owner_and_address_from_pdfs(folder_path):
    owner = None
    address = None
    pdfs = glob.glob(os.path.join(folder_path, "**/*.pdf"), recursive=True)
    
    infostan_pdfs = [p for p in pdfs if "infostan" in os.path.basename(p).lower()]
    for p in infostan_pdfs:
        try:
            reader = PdfReader(p)
            text = reader.pages[0].extract_text()
            lines = [l.strip() for l in text.splitlines() if l.strip()]
            for i, l in enumerate(lines):
                if "IDENT" in l and i + 1 < len(lines):
                    cand = lines[i+1]
                    if not any(k in cand for k in ["ПИБ", "МБ", "Данијелова", "Сервисни"]):
                        owner = cand
                    break
            for l in lines:
                if ("Адреса:" in l or "Adresa:" in l) and not address:
                    address = l.split(":", 1)[1].strip()
            if owner and address:
                return owner, address
        except Exception:
            pass

    for p in pdfs:
        try:
            reader = PdfReader(p)
            text = reader.pages[0].extract_text()
            if not owner and "Šifra kupca" in text:
                m = re.search(r"Šifra kupca[^\n]*\n([A-Z0-9\s\.\-]{3,40})", text)
                if m:
                    cand = m.group(1).strip()
                    if "DOO" in cand or len(cand.split()) >= 2:
                        owner = cand
            if not address:
                m = re.search(r"Адреса\s*(?:мерног места)?[^\:]*:\s*([^\n]+)", text)
                if m:
                    address = m.group(1).strip()
            if owner and address:
                return owner, address
        except Exception:
            pass
            
    return owner, address

def load_master_contracts():
    if not os.path.exists(MASTER_EXCEL):
        return {}
    wb = openpyxl.load_workbook(MASTER_EXCEL, data_only=True)
    if "Ugovori" not in wb.sheetnames:
        return {}
    sheet = wb["Ugovori"]
    data = {}
    for r in range(2, sheet.max_row + 1):
        unit = sheet.cell(r, 1).value
        s_val = parse_date(sheet.cell(r, 2).value)
        e_val = parse_date(sheet.cell(r, 3).value)
        if unit:
            u_clean = str(unit).strip().upper()
            data[u_clean] = (s_val, e_val)
    return data

def get_master_contract_dates(clean_title, master_dict):
    if not master_dict:
        return (None, None)
    c_upper = clean_title.upper().strip()
    aliases = {
        'BW TERRACES 104': 'TERRACES 104',
        'BW TERRACES 207': 'TERRACES 207',
        'BW SIMFONIA 1501': 'SIMFONIJA 1501',
        'BW SOLE 1401': 'SOLE 1401',
        'BW RESIDENCES 402': 'RESIDENCES 0402',
        'BW RESIDENCES 1704': 'RESIDENCES 1704',
        'BW AQUA 1607': 'AQUA 1607',
        'BW AQUA 1807': 'AQUA 1807',
        'WEST 9.1': 'WEST 9.1',
        'WEST 18.1': 'WEST 18.1',
        'A BLOK': 'A BLOK',
        'C 7.28 LANDMARK': 'LANDMARK C 7.28',
        'C 8.35 LANDMARK': 'LANDMARK C 8.35',
        'B 7.37 LANDMARK': 'LANDMARK B 7.37',
        'B 8.47 LANDMARK': 'LANDMARK B 8.47',
        'A 5.17 LANDMARK': 'LANDMARK A 5.17',
        'VILA SREMCICA': 'VILA SREMCICA',
        'BW QUARTET C006': 'BW QUARTET C006',
        'BW PERLA 101': 'PERLA 101',
        'BW PERLA 303': 'PERLA 303',
        'BW PERLA 505': 'PERLA 505',
        'BW PERLA 804': 'PERLA 804',
        'BW PERLA 2301': 'PERLA 2301',
        'BW PERLA 2401': 'PERLA 2401',
        'BW RIVIERA 206': 'RIVIERA 206',
        'BW RIVIERA 1004': 'RIVIERA 1004',
        'BW RIVIERA 1104': 'RIVIERA 1104',
        'BW RIVIERA 1304': 'RIVIERA 1304',
        'BW RIVIERA 2104': 'RIVIERA 2104',
        'BW RIVIERA 2203': 'RIVIERA 2203',
        'BW RIVIERA 2304': 'RIVIERA 2304',
        'ST. REGIS 2610': 'ST. REGIS 2610',
        'ST. REGIS 3306': 'ST. REGIS 3306',
        'ST. REGIS 3504': 'ST. REGIS 3504',
        'ST. REGIS 3607': 'ST. REGIS 3607'
    }
    m_key = aliases.get(c_upper, c_upper)
    return master_dict.get(m_key, (None, None))

def parse_property_folder(folder_name, master_dict=None):
    folder_path = os.path.join(BASE_DIR, folder_name)
    clean_title = re.sub(r"^\d+\.\s*", "", folder_name).strip()
    
    excel_files = [f for f in os.listdir(folder_path) if (f.endswith(".xlsx") or f.endswith(".xls")) and not f.startswith("~$")]
    if not excel_files:
        return None

    excel_path = os.path.join(folder_path, excel_files[0])
    wb = openpyxl.load_workbook(excel_path, data_only=True)
    
    owner_name, raw_address = extract_owner_and_address_from_pdfs(folder_path)
    if not raw_address:
        final_address = f"{clean_title}, Belgrade, Serbia"
    else:
        final_address = f"{raw_address}, Belgrade, Serbia"
        
    contract_sheet_name = None
    for s in wb.sheetnames:
        if "ugovor" in s.lower():
            contract_sheet_name = s
            break
            
    tenant_name = None
    tenant_phone = None
    tenant_email = None
    start_date = None
    end_date = None
    monthly_rent = 0.0
    deposit_amount = 0.0
    payment_method = "cash"
    contract_notes = ""
    
    if contract_sheet_name:
        sheet = wb[contract_sheet_name]
        candidates = []
        for r in range(2, min(10, sheet.max_row + 1)):
            c_start = parse_date(sheet.cell(r, 2).value)
            c_end = parse_date(sheet.cell(r, 4).value)
            c_name = sheet.cell(r, 8).value
            if c_name or c_start or c_end:
                candidates.append((r, c_start, c_end, c_name))
        
        chosen_row = None
        for r, s_d, e_d, c_name in reversed(candidates):
            if s_d or e_d:
                chosen_row = r
                break
        if not chosen_row and candidates:
            chosen_row = candidates[-1][0]
            
        if chosen_row:
            r = chosen_row
            start_date = parse_date(sheet.cell(r, 2).value)
            end_date = parse_date(sheet.cell(r, 4).value)
            monthly_rent = clean_amount(sheet.cell(r, 5).value)
            raw_dep = sheet.cell(r, 6).value
            raw_dep_paid = sheet.cell(r, 12).value
            deposit_amount = parse_deposit_full(raw_dep, raw_dep_paid, monthly_rent)
            
            pm_val = str(sheet.cell(r, 7).value or "").strip().lower()
            if "gotovina" in pm_val or "kes" in pm_val or "cash" in pm_val:
                payment_method = "cash"
            elif "racun" in pm_val or "bank" in pm_val:
                payment_method = "bank_transfer"
            else:
                payment_method = "cash"
                
            tenant_name = sheet.cell(r, 8).value
            if tenant_name:
                tenant_name = str(tenant_name).strip()
            
            p_val = sheet.cell(r, 9).value
            if p_val:
                p_str = re.sub(r"[^\d\+]", "", str(p_val))
                if p_str:
                    tenant_phone = f"+{p_str}" if not p_str.startswith("+") else p_str
                    
            e_val = sheet.cell(r, 10).value
            if e_val and "@" in str(e_val):
                tenant_email = str(e_val).strip()
                
    # Overwrite / enrich contract dates from master table Ugovori o zakupu - Property Menagment
    m_start, m_end = get_master_contract_dates(clean_title, master_dict)
    if m_start == "2027-10-01" and m_end == "2027-09-30":
        m_start = "2026-10-01"  # Fix typo in master sheet for St. Regis 3306

    if m_start and m_end:
        start_date = m_start
        end_date = m_end
        
        # User Rule: "bir yıldan uzun süredir devam etmiş sözleşmeler varsa onların sözleşme başlangıç tarihini sözleşme bitiş tarihinden bir yıl önce başlamış gibi içeri almak lazım. Yani AQUA 1807 06.11.2023 05.11.2026 sözleşmesi aslında 6.11.2025 tarihinde başlamış bir sözleşme."
        s_dt = datetime.date.fromisoformat(start_date)
        e_dt = datetime.date.fromisoformat(end_date)
        if (e_dt - s_dt).days > 370 and s_dt < datetime.date(2025, 1, 1):
            orig_s_str = start_date
            while s_dt < datetime.date(2025, 1, 1):
                try:
                    s_dt = datetime.date(s_dt.year + 1, s_dt.month, s_dt.day)
                except ValueError:
                    s_dt = s_dt + datetime.timedelta(days=365)
            start_date = s_dt.strftime("%Y-%m-%d")
            contract_notes = (f"Orijinal Kontrat: {orig_s_str} - {end_date}. " + (contract_notes or "")).strip()

    manual_notes_list = []
    if contract_notes:
        manual_notes_list.append(f"Kontrat Notu: {contract_notes}")
        
    dnevnik_notes = []
    dnevnik_entries = []
    for s in wb.sheetnames:
        if "dnevnik" in s.lower() or "dogad" in s.lower():
            s_dnevnik = wb[s]
            ishod_col = None
            opis_col = 2
            date_col = 1
            for c in range(1, min(15, s_dnevnik.max_column + 1)):
                header_c = str(s_dnevnik.cell(2, c).value or "").strip().upper()
                if "ISHOD" in header_c:
                    ishod_col = c
                elif "OPIS" in header_c:
                    opis_col = c
                elif "DATUM" in header_c:
                    date_col = c

            for r in range(2, s_dnevnik.max_row + 1):
                raw_d = s_dnevnik.cell(r, date_col).value
                raw_desc = s_dnevnik.cell(r, opis_col).value
                ishod = s_dnevnik.cell(r, ishod_col).value if ishod_col else None
                
                if raw_desc:
                    desc_str = str(raw_desc).strip()
                    if not desc_str or desc_str.upper() in ["OPIS", "DESCRIPTION", "NONE"]:
                        continue
                    d_val = parse_date(raw_d)
                    date_prefix = f"[{d_val}] " if d_val else ""
                    note_line = f"{date_prefix}{desc_str}"
                    if ishod and str(ishod).strip() and str(ishod).strip().upper() not in ["NONE", "NULL", "-"]:
                        note_line += f" -> Sonuç: {str(ishod).strip()}"
                    dnevnik_notes.append(note_line)

                    full_note = desc_str
                    if ishod and str(ishod).strip() and str(ishod).strip().upper() not in ["NONE", "NULL", "-"]:
                        full_note += f" (Sonuç: {str(ishod).strip()})"
                    dnevnik_entries.append({
                        "date": d_val,
                        "note": full_note
                    })
            break

    if dnevnik_notes:
        manual_notes_list.append("--- Dnevnik Događaja ---")
        manual_notes_list.extend(dnevnik_notes)

    fin_sheet = None
    for s in wb.sheetnames:
        if "2026" in s and ("pm" in s.lower() or "c 7.28" in s.lower() or s == "PM 2026"):
            fin_sheet = wb[s]
            break
            
    rent_items = []
    bill_items = []
    
    if fin_sheet:
        headers = {}
        for c in range(1, fin_sheet.max_column + 1):
            h_val = str(fin_sheet.cell(1, c).value or "").strip().upper()
            if h_val:
                headers[c] = h_val
                
        rent_due_col = next((c for c, h in headers.items() if "ZADUŽENJE RENTA" in h or "ZADUZENJE RENTA" in h), 2)
        rent_paid_col = next((c for c, h in headers.items() if "UPLAĆENO RENTA" in h or "UPLACENO RENTA" in h), 3)
        rent_date_col = next((c for c, h in headers.items() if "DATUM UPLATE" in h), 4)
        
        bill_due_col = next((c for c, h in headers.items() if "ZADUŽENJE RAČUNI" in h or "ZADUZENJE RACUNI" in h), 6)
        bill_paid_col = next((c for c, h in headers.items() if "UPLAĆENO RAČUNI" in h or "UPLACENO RACUNI" in h), 7)
        bill_date_col = next((c for c, h in headers.items() if h in ["DATE", "DATUM"] and c > 5), 8)
        
        other_col = next((c for c, h in headers.items() if "OTHER" in h), None)
        
        bill_columns = []
        for c, h in headers.items():
            if c in [rent_due_col, rent_paid_col, rent_date_col, bill_due_col, bill_paid_col, bill_date_col, other_col]:
                continue
            if "BALANS" in h or h == "2026" or "5" == h:
                continue
                
            b_type = None
            if "PARK" in h or "GARA" in h:
                b_type = "Parking"
            elif "INFOSTAN" in h or "INFO STAN" in h:
                b_type = "Infostan"
            elif "ELECTRICITY" in h or "EPS" in h:
                b_type = "Electricity"
            elif "INTERNET" in h or "MTS" in h:
                b_type = "Internet/TV"
            elif any(k in h for k in ["MAINTENANCE", "HAUZMAJSTOR", "STAMBENA ZAJEDNICA", "FORM FOKUS", "CITY FACILITY"]):
                b_type = "Building Maintenance"
                
            if b_type:
                bill_columns.append((c, b_type, h))

        for r in range(2, 14):
            month_name = str(fin_sheet.cell(r, 1).value or "").strip().upper()
            if month_name not in MONTH_MAP:
                continue
            month_num = MONTH_MAP[month_name]
            
            if other_col:
                o_val = fin_sheet.cell(r, other_col).value
                if o_val and str(o_val).strip() not in ["", "0", "0.0"]:
                    manual_notes_list.append(f"[2026-{month_num:02d} Notu]: {str(o_val).strip()}")
                    
            r_due = clean_amount(fin_sheet.cell(r, rent_due_col).value)
            r_paid = clean_amount(fin_sheet.cell(r, rent_paid_col).value)
            r_date = parse_date(fin_sheet.cell(r, rent_date_col).value)
            
            if r_due > 0 or r_paid > 0:
                due_date_str = f"2026-{month_num:02d}-01"
                status = "paid" if (r_paid >= (r_due - 1.0) and r_due > 0) else "pending"
                rent_items.append({
                    "year": 2026,
                    "month": month_num,
                    "month_name": month_name,
                    "title": "Kira",
                    "due_amount": r_due if r_due > 0 else r_paid,
                    "paid_amount": r_paid,
                    "currency": "EUR",
                    "due_date": due_date_str,
                    "paid_at": r_date if r_paid > 0 else None,
                    "status": status,
                    "payment_method": payment_method
                })
                
            total_bill_due = clean_amount(fin_sheet.cell(r, bill_due_col).value)
            total_bill_paid = clean_amount(fin_sheet.cell(r, bill_paid_col).value)
            bill_date = parse_date(fin_sheet.cell(r, bill_date_col).value)
            
            sub_bills = []
            for c_idx, b_type, orig_h in bill_columns:
                sub_amount = clean_amount(fin_sheet.cell(r, c_idx).value)
                if sub_amount > 0:
                    sub_bills.append({
                        "type": b_type,
                        "raw_header": orig_h,
                        "due_amount": sub_amount
                    })
                    
            if sub_bills:
                sum_subs = sum(b["due_amount"] for b in sub_bills)
                effective_due = total_bill_due if total_bill_due > 0 else sum_subs
                
                for sb in sub_bills:
                    due_amt = sb["due_amount"]
                    # Kuruş/para yuvarlama toleransı (1.0 RSD): örn. B 7.37 Mayis 27320.86 vs 27320.56 (0.30 RSD fark)
                    if (total_bill_paid >= (effective_due - 1.0)) and effective_due > 0:
                        bill_items.append({
                            "year": 2026,
                            "month": month_num,
                            "month_name": month_name,
                            "title": sb["type"],
                            "raw_type": sb["raw_header"],
                            "due_amount": due_amt,
                            "paid_amount": due_amt,
                            "currency": "RSD",
                            "due_date": f"2026-{month_num:02d}-15",
                            "paid_at": bill_date,
                            "status": "paid",
                            "owner_note": None,
                            "payment_method": payment_method,
                            "receiver_type": "owner"
                        })
                    elif total_bill_paid > 0 and effective_due > 0:
                        # Oransal (pro-rata) dağıtım: Ödenen tutar ve kalan borç 2 ayrı satır olarak yazılır
                        ratio = total_bill_paid / effective_due
                        paid_amt = round(due_amt * ratio, 2)
                        rem_amt = round(due_amt - paid_amt, 2)

                        # 1. Ödenen kısım (PAID)
                        if paid_amt > 0:
                            bill_items.append({
                                "year": 2026,
                                "month": month_num,
                                "month_name": month_name,
                                "title": sb["type"],
                                "raw_type": sb["raw_header"],
                                "due_amount": paid_amt,
                                "paid_amount": paid_amt,
                                "currency": "RSD",
                                "due_date": f"2026-{month_num:02d}-15",
                                "paid_at": bill_date,
                                "status": "paid",
                                "owner_note": f"Oransal kısmi ödeme ({paid_amt:.2f} RSD ödendi)",
                                "payment_method": payment_method,
                                "receiver_type": "owner"
                            })

                        # 2. Kalan borç kısmı (PENDING)
                        if rem_amt > 0:
                            bill_items.append({
                                "year": 2026,
                                "month": month_num,
                                "month_name": month_name,
                                "title": f"{sb['type']} (Kalan)",
                                "raw_type": sb["raw_header"],
                                "due_amount": rem_amt,
                                "paid_amount": 0.0,
                                "currency": "RSD",
                                "due_date": f"2026-{month_num:02d}-15",
                                "paid_at": None,
                                "status": "pending",
                                "owner_note": f"Kalan borç bakiyesi ({rem_amt:.2f} RSD)",
                                "payment_method": payment_method,
                                "receiver_type": "owner"
                            })
                    else:
                        # Hiç ödenmemiş
                        bill_items.append({
                            "year": 2026,
                            "month": month_num,
                            "month_name": month_name,
                            "title": sb["type"],
                            "raw_type": sb["raw_header"],
                            "due_amount": due_amt,
                            "paid_amount": 0.0,
                            "currency": "RSD",
                            "due_date": f"2026-{month_num:02d}-15",
                            "paid_at": None,
                            "status": "pending",
                            "owner_note": None,
                            "payment_method": payment_method,
                            "receiver_type": "owner"
                        })

    orig_start_date = start_date
    orig_end_date = end_date
    if start_date:
        # Ensure end_date is at least end of 2026 if contract was already expired on paper
        if end_date and end_date < "2026-01-01":
            manual_notes_list.insert(0, f"[Orijinal Kontrat Bitişi: {orig_end_date}]")
            end_date = "2026-12-31"

    all_manual_notes = "\n".join(manual_notes_list) if manual_notes_list else None
    
    # Deterministic IDs
    prop_id = str(uuid.uuid5(STANOMER_NAMESPACE, f"property_{clean_title}"))
    contract_id = str(uuid.uuid5(STANOMER_NAMESPACE, f"contract_{clean_title}")) if start_date else None
    
    # Contract notes with original date and Dnevnik notes
    c_notes_parts = []
    formatted_contract_notes = (contract_notes or "").strip()
    if orig_start_date and orig_start_date < "2026-01-01" and "Orijinal Kontrat:" not in formatted_contract_notes:
        formatted_contract_notes = f"Orijinal Kontrat: {orig_start_date} - {orig_end_date or 'Belirsiz'}. {formatted_contract_notes}".strip()
    if formatted_contract_notes:
        c_notes_parts.append(formatted_contract_notes)
    if dnevnik_notes:
        c_notes_parts.append("--- Dnevnik Događaja ---")
        c_notes_parts.extend(dnevnik_notes)
    final_contract_notes = "\n".join(c_notes_parts) if c_notes_parts else ""

    return {
        "id": prop_id,
        "contract_id": contract_id,
        "folder": folder_name,
        "title": clean_title,
        "address": final_address,
        "owner": {
            "name": owner_name,
            "email": None,
            "phone": None
        },
        "tenant": {
            "name": tenant_name,
            "email": tenant_email,
            "phone": tenant_phone
        },
        "contract": {
            "start_date": start_date,
            "end_date": end_date,
            "orig_start_date": orig_start_date,
            "orig_end_date": orig_end_date,
            "monthly_rent": monthly_rent,
            "deposit_amount": deposit_amount,
            "deposit_currency": "EUR",
            "payment_method": payment_method,
            "notes": final_contract_notes,
            "is_active_2026": bool(start_date)
        },
        "manual_notes": all_manual_notes,
        "dnevnik_entries": dnevnik_entries,
        "rent_items": rent_items,
        "bill_items": bill_items
    }

def escape_sql(val):
    if val is None:
        return "NULL"
    val_str = str(val).replace("'", "''")
    return f"'{val_str}'"

def generate_sql_migration(parsed_properties, output_path, agency_id=None):
    if not agency_id:
        agency_id = TARGET_AGENCY_ID
    lines = []
    lines.append("-- ==============================================================================")
    lines.append("-- MIGRATION: 2026-10-21_import_2026_property_management_data.sql")
    lines.append(f"-- HEDEF PROFİL (AGENCY / LANDLORD ID): {agency_id}")
    lines.append("-- TANIM: 36 adet mülk, aktif kontratlar, kira ve fatura hareketlerinin aktarımı.")
    lines.append("-- IDEMPOTENT: Tüm kayıtlar deterministic UUID ile üretilmiş olup mükerrer oluşturmaz.")
    lines.append("-- ==============================================================================\n")
    lines.append("BEGIN;\n")

    # Ensure invitee_email is NULLABLE on contracts if legacy constraint exists
    lines.append("-- Ensure contracts.invitee_email allows NULL when tenant email is not provided")
    lines.append("ALTER TABLE public.contracts ALTER COLUMN invitee_email DROP NOT NULL;\n")

    # 0. CLEANUP PREVIOUS DATA FOR TARGET AGENCY
    lines.append("-- ------------------------------------------------------------------------------")
    lines.append(f"-- 0. CLEANUP PREVIOUS DATA FOR PROFILE {agency_id}")
    lines.append("-- ------------------------------------------------------------------------------")
    lines.append(f"""DO $$
DECLARE
    v_agency_id UUID := '{agency_id}';
BEGIN
    -- 1. Delete maintenance records linked to properties of this agency
    DELETE FROM public.maintenance_charges 
    WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);
    
    DELETE FROM public.maintenance_requests 
    WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);

    -- 2. Delete activity logs
    DELETE FROM public.activity_logs 
    WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);

    -- 3. Delete rent payments & bills
    DELETE FROM public.rent_payments 
    WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id)
       OR contract_id IN (SELECT id FROM public.contracts WHERE agency_id = v_agency_id);

    -- 4. Delete invitations & leases
    DELETE FROM public.invitations 
    WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);
    
    DELETE FROM public.leases 
    WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);

    -- 5. Delete contracts
    DELETE FROM public.contracts 
    WHERE agency_id = v_agency_id 
       OR property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);

    -- 6. Delete properties
    DELETE FROM public.properties 
    WHERE agency_id = v_agency_id OR landlord_id = v_agency_id;
END $$;\n""")

    # 0.1 Update generate_missing_rent_payments to ensure contracts starting in 2025 do not produce pre-2026 debt
    lines.append("-- ------------------------------------------------------------------------------")
    lines.append("-- 0.1 UPDATE generate_missing_rent_payments RPC (No Phantom Pre-2026 Debt)")
    lines.append("-- ------------------------------------------------------------------------------")
    lines.append("""CREATE OR REPLACE FUNCTION public.generate_missing_rent_payments(p_property_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_contract_id   uuid;
  v_start_date    date;
  v_end_date      date;
  v_current_date  date;
  v_monthly_rent  numeric;
  v_currency      text;
  v_tenant_id     uuid;
  v_due_day       integer;
  v_expenses_cfg  jsonb;
  v_expense       jsonb;
  v_exp_name      text;
  v_exp_amount    numeric;
  v_exp_receiver  text;
  v_approved_row  record;
BEGIN
  -- Get the ACTIVE contract for the property
  SELECT id, start_date, monthly_rent, currency, tenant_id,
         COALESCE(due_day, 1), COALESCE(expenses_config, '[]'::jsonb)
  INTO v_contract_id, v_start_date, v_monthly_rent, v_currency, v_tenant_id, v_due_day, v_expenses_cfg
  FROM public.contracts
  WHERE property_id = p_property_id AND status = 'active'
  ORDER BY updated_at DESC
  LIMIT 1;

  IF v_contract_id IS NULL OR v_monthly_rent IS NULL THEN
    RETURN;
  END IF;

  -- AUTO-APPROVE: Mark 'declared' as 'paid' after 5 days
  FOR v_approved_row IN
    UPDATE public.rent_payments
    SET status = 'paid', paid_at = (declared_at + interval '5 days')
    WHERE contract_id = v_contract_id
      AND status = 'declared'
      AND receiver_type = 'owner'
      AND declared_at < (now() - interval '5 days')
    RETURNING id, due_date
  LOOP
    INSERT INTO public.activity_logs (property_id, type, metadata)
    VALUES (p_property_id, 'rent_auto_approved',
            jsonb_build_object('month', v_approved_row.due_date));
  END LOOP;

  -- CLEANUP: Remove any pending rows before 2026-01-01
  DELETE FROM public.rent_payments
  WHERE contract_id = v_contract_id
    AND status = 'pending'
    AND (due_date < '2026-01-01'::date OR date_trunc('month', due_date) < date_trunc('month', v_start_date));

  -- Generate rows from start (clamped to 2026-01-01 minimum so pre-2026 contracts never produce 2025 debt)
  IF v_start_date < '2026-01-01'::date THEN
    v_current_date := (date_trunc('month', '2026-01-01'::date) + (v_due_day - 1) * interval '1 day')::date;
  ELSE
    v_current_date := (date_trunc('month', v_start_date) + (v_due_day - 1) * interval '1 day')::date;
  END IF;

  v_end_date := (date_trunc('month', now()) + (v_due_day - 1) * interval '1 day')::date;

  WHILE v_current_date <= v_end_date LOOP
    -- A. Ana kira satırı
    INSERT INTO public.rent_payments
      (property_id, contract_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
    VALUES
      (p_property_id, v_contract_id, v_tenant_id, v_monthly_rent, v_currency, v_current_date, 'pending', 'Kira', 'owner')
    ON CONFLICT (contract_id, due_date, title)
    DO UPDATE SET
      amount    = EXCLUDED.amount,
      currency  = EXCLUDED.currency,
      tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id)
    WHERE rent_payments.status = 'pending';

    -- B+C. Masraf kalemleri
    IF jsonb_array_length(v_expenses_cfg) > 0 THEN
      FOR v_expense IN SELECT jsonb_array_elements(v_expenses_cfg)
      LOOP
        v_exp_name     := v_expense->>'name';
        v_exp_amount   := COALESCE((v_expense->>'amount')::numeric, 0);
        v_exp_receiver := v_expense->>'receiver';

        IF v_exp_name IS NULL THEN
          CONTINUE;
        END IF;

        IF v_exp_receiver = 'owner' THEN
          INSERT INTO public.rent_payments
            (property_id, contract_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
          VALUES
            (p_property_id, v_contract_id, v_tenant_id, v_exp_amount, v_currency, v_current_date, 'pending', v_exp_name, 'owner')
          ON CONFLICT (contract_id, due_date, title)
          DO UPDATE SET
            amount    = CASE
                          WHEN rent_payments.invoice_url IS NOT NULL THEN rent_payments.amount
                          WHEN rent_payments.amount > 0              THEN rent_payments.amount
                          ELSE EXCLUDED.amount
                        END,
            currency  = EXCLUDED.currency,
            tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id)
          WHERE rent_payments.status = 'pending';
        END IF;
      END LOOP;
    END IF;

    v_current_date := (v_current_date + interval '1 month')::date;
  END LOOP;
END;
$$;\n""")

    # 1. Properties
    lines.append("-- ------------------------------------------------------------------------------")
    lines.append("-- 1. PROPERTIES")
    lines.append("-- ------------------------------------------------------------------------------")
    for p in parsed_properties:
        prop_id = p["id"]
        title = escape_sql(p["title"])
        address = escape_sql(p["address"])
        owner_name = escape_sql(p["owner"]["name"])
        desc = escape_sql(p["manual_notes"])
        m_rent = p["contract"]["monthly_rent"] or 0.0
        dep_amt = p["contract"]["deposit_amount"] or 0.0
        
        expense_names = list(set([b["title"] for b in p["bill_items"]]))
        if not expense_names:
            expense_names = ["Infostan", "Electricity", "Building Maintenance"]
        tmpl = [{"name": name, "receiver": "owner", "amount": 0.0, "payment_method": p["contract"]["payment_method"]} for name in expense_names]
        tmpl_json = escape_sql(json.dumps(tmpl, ensure_ascii=False))

        lines.append(f"""INSERT INTO public.properties (
    id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
    default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
) VALUES (
    '{prop_id}', '{agency_id}', '{agency_id}', {owner_name}, {title}, {title}, {address}, 'Beograd', 'EUR',
    {m_rent}, {dep_amt}, true, {desc}, {tmpl_json}::jsonb, now(), now()
) ON CONFLICT (id) DO UPDATE SET
    landlord_name = EXCLUDED.landlord_name,
    name = EXCLUDED.name,
    title = EXCLUDED.title,
    address = EXCLUDED.address,
    description = EXCLUDED.description,
    default_monthly_rent = EXCLUDED.default_monthly_rent,
    default_deposit_amount = EXCLUDED.default_deposit_amount,
    expenses_template = EXCLUDED.expenses_template,
    updated_at = now();
""")

    # 2. Contracts
    lines.append("\n-- ------------------------------------------------------------------------------")
    lines.append("-- 2. CONTRACTS")
    lines.append("-- ------------------------------------------------------------------------------")
    for p in parsed_properties:
        if not p["contract_id"] or not p["contract"]["start_date"]:
            continue
        c_id = p["contract_id"]
        prop_id = p["id"]
        tenant_name = escape_sql(p["tenant"]["name"])
        tenant_phone = escape_sql(p["tenant"]["phone"])
        tenant_email = escape_sql(p["tenant"]["email"]) # Strictly NULL if missing!
        
        # Token
        c_token = str(uuid.uuid5(STANOMER_NAMESPACE, f"token_{c_id}")).replace("-", "")
        token_sql = escape_sql(c_token)
        
        s_date = escape_sql(p["contract"]["start_date"])
        e_date = escape_sql(p["contract"]["end_date"])
        m_rent = p["contract"]["monthly_rent"] or 0.0
        dep_amt = p["contract"]["deposit_amount"] or 0.0
        notes = escape_sql(p["contract"]["notes"])
        
        expense_names = list(set([b["title"] for b in p["bill_items"]]))
        if not expense_names:
            expense_names = ["Infostan", "Electricity", "Building Maintenance"]
        cfg = [{"name": name, "receiver": "owner", "amount": 0.0, "payment_method": p["contract"]["payment_method"]} for name in expense_names]
        cfg_json = escape_sql(json.dumps(cfg, ensure_ascii=False))
        
        lines.append(f"""INSERT INTO public.contracts (
    id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
    token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
    status, expenses_config, tenant_notes, due_day, created_at
) VALUES (
    '{c_id}', '{prop_id}', '{agency_id}', '{agency_id}', {tenant_name}, {tenant_phone}, {tenant_email},
    {token_sql}, {s_date}, {e_date}, {m_rent}, {dep_amt}, 'EUR', 'EUR',
    'active', {cfg_json}::jsonb, {notes}, 1, now()
) ON CONFLICT (id) DO UPDATE SET
    tenant_name = EXCLUDED.tenant_name,
    tenant_phone = EXCLUDED.tenant_phone,
    invitee_email = EXCLUDED.invitee_email,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    monthly_rent = EXCLUDED.monthly_rent,
    tenant_notes = EXCLUDED.tenant_notes;
""")

    # 2.5 Activity Logs (Dnevnik Događaja -> manual_note)
    lines.append("\n-- ------------------------------------------------------------------------------")
    lines.append("-- 2.5 ACTIVITY LOGS (Dnevnik Događaja -> manual_note)")
    lines.append("-- ------------------------------------------------------------------------------")
    for p in parsed_properties:
        prop_id = p["id"]
        for idx, entry in enumerate(p.get("dnevnik_entries", [])):
            log_id = str(uuid.uuid5(STANOMER_NAMESPACE, f"activity_log_{prop_id}_{idx}_{entry['note']}"))
            created_at = f"'{entry['date']} 12:00:00+00'::timestamptz" if entry['date'] else "now()"
            note_escaped = escape_sql(entry['note'])
            lines.append(f"""INSERT INTO public.activity_logs (
    id, property_id, user_id, type, metadata, created_at
) VALUES (
    '{log_id}', '{prop_id}', '{agency_id}', 'manual_note',
    jsonb_build_object('note', {note_escaped}), {created_at}
) ON CONFLICT (id) DO UPDATE SET
    metadata = EXCLUDED.metadata,
    created_at = EXCLUDED.created_at;
""")

    # 3. Rent & Bill Payments
    lines.append("\n-- ------------------------------------------------------------------------------")
    lines.append("-- 3. RENT & BILL PAYMENTS")
    lines.append("-- ------------------------------------------------------------------------------")
    for p in parsed_properties:
        prop_id = p["id"]
        c_id = p["contract_id"]
        
        for item in p["rent_items"]:
            pay_id = str(uuid.uuid5(STANOMER_NAMESPACE, f"payment_{prop_id}_{item['title']}_{item['year']}_{item['month']}"))
            due_d = escape_sql(item["due_date"])
            paid_d = escape_sql(item["paid_at"])
            st = escape_sql(item["status"])
            amt = item["due_amount"]
            pm = escape_sql(item["payment_method"])
            contract_sql = f"'{c_id}'" if c_id else "NULL"
            
            lines.append(f"""INSERT INTO public.rent_payments (
    id, property_id, contract_id, title, amount, currency, due_date, paid_at,
    status, payment_method, receiver_type, created_at
) VALUES (
    '{pay_id}', '{prop_id}', {contract_sql}, 'Kira', {amt}, 'EUR', {due_d}, {paid_d},
    {st}, {pm}, 'owner', now()
) ON CONFLICT (id) DO UPDATE SET
    amount = EXCLUDED.amount,
    paid_at = EXCLUDED.paid_at,
    status = EXCLUDED.status;
""")

        for item in p["bill_items"]:
            pay_id = str(uuid.uuid5(STANOMER_NAMESPACE, f"bill_{prop_id}_{item['title']}_{item['year']}_{item['month']}"))
            due_d = escape_sql(item["due_date"])
            paid_d = escape_sql(item["paid_at"])
            st = escape_sql(item["status"])
            amt = item["due_amount"]
            pm = escape_sql(item["payment_method"])
            note = escape_sql(item.get("owner_note"))
            contract_sql = f"'{c_id}'" if c_id else "NULL"
            b_title = escape_sql(item["title"])
            
            lines.append(f"""INSERT INTO public.rent_payments (
    id, property_id, contract_id, title, amount, currency, due_date, paid_at,
    status, owner_note, payment_method, receiver_type, created_at
) VALUES (
    '{pay_id}', '{prop_id}', {contract_sql}, {b_title}, {amt}, 'RSD', {due_d}, {paid_d},
    {st}, {note}, {pm}, 'owner', now()
) ON CONFLICT (id) DO UPDATE SET
    amount = EXCLUDED.amount,
    paid_at = EXCLUDED.paid_at,
    status = EXCLUDED.status,
    owner_note = EXCLUDED.owner_note;
""")

    # Extra safety: remove any rent payments before 2026 for this agency's properties to ensure zero 2025 phantom debt
    lines.append("\n-- Ensure absolutely no rent or utility bills exist before 2026-01-01 for this profile's properties")
    lines.append(f"""DELETE FROM public.rent_payments 
WHERE due_date < '2026-01-01' 
  AND property_id IN (
    SELECT id FROM public.properties 
    WHERE agency_id = '{agency_id}' OR landlord_id = '{agency_id}'
  );\n""")

    lines.append("\nCOMMIT;\n")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"[+] SQL migration successfully generated at: {output_path}")

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Stanomer Property Management 2026 Importer")
    parser.add_argument("--agency-id", default=TARGET_AGENCY_ID, help="Target agency/landlord profile UUID")
    parser.add_argument("--sql-output", default=None, help="Output SQL migration path")
    args, _ = parser.parse_known_args()

    target_id = args.agency_id

    master_dict = load_master_contracts()
    print(f"[*] Loaded {len(master_dict)} contract rows from master table: {MASTER_EXCEL}")

    dirs = sorted([d for d in os.listdir(BASE_DIR) if os.path.isdir(os.path.join(BASE_DIR, d))], 
                  key=lambda x: int(re.match(r"^(\d+)", x).group(1)) if re.match(r"^(\d+)", x) else 999)
                  
    parsed_properties = []
    print(f"[*] Parsing {len(dirs)} property folders from: {BASE_DIR}")
    for d in dirs:
        p_data = parse_property_folder(d, master_dict)
        if p_data:
            parsed_properties.append(p_data)
            
    preview_file = os.path.join(os.path.dirname(__file__), "import_preview.json")
    with open(preview_file, "w", encoding="utf-8") as f:
        json.dump(parsed_properties, f, ensure_ascii=False, indent=2)

    md_file = os.path.join(os.path.dirname(__file__), "import_summary.md")
    with open(md_file, "w", encoding="utf-8") as f:
        f.write("# Stanomer 2026 Property Import Summary\n\n")
        f.write(f"**Acente / Profil:** `{target_id}`\n")
        f.write(f"**Toplam Taranan Mülk:** {len(parsed_properties)}\n\n")
        f.write("| # | Mülk Adı | Ev Sahibi | Kiracı | Kontrat 2026 | Kira Kalemi | Fatura Kalemi | Not Sayısı |\n")
        f.write("|---|---|---|---|---|---|---|---|\n")
        for i, p in enumerate(parsed_properties, 1):
            owner = p["owner"]["name"] or "*Bilinmiyor*"
            tenant = p["tenant"]["name"] or "*Boş*"
            c_str = f"{p['contract']['start_date']} - {p['contract']['end_date']}" if p['contract']['start_date'] else "❌ Yok"
            rents = len(p["rent_items"])
            bills = len(p["bill_items"])
            notes_count = len(p["manual_notes"].splitlines()) if p["manual_notes"] else 0
            f.write(f"| {i} | {p['title']} | {owner} | {tenant} | {c_str} | {rents} | {bills} | {notes_count} |\n")

    sql_path = args.sql_output or "/Users/atilbilgeorum/projects/stanomer/migrations/2026-10-21_import_2026_property_management_data.sql"
    generate_sql_migration(parsed_properties, sql_path, agency_id=target_id)

if __name__ == "__main__":
    main()
