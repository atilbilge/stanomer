# Stanomer Acente Portalı — Örnek Veri Seti Taslağı (Mock Data Spec)

**Hedef Acente Profili:**
* **ID:** `0c0ca8df-765a-46de-aee3-b70daa964015`
* **Şirket Adı:** `Agency Name` (Örnek: *Axia Exclusive Real Estate / Stanomer Partner*)
* **Yetkili E-posta:** `agency@agency.com`
* **Rol:** `agency` (Active Role: `agency`)
* **Pazar:** Sırbistan (Belgrad & Novi Sad) & Uluslararası Expat Portföyü
* **Referans Tarih:** Eylül 2026

---

## 1. Ev Sahipleri (7 Landlords — `profiles`)

Acente portföyündeki 10 evin sahibi olan 7 farklı profil (bazı yatırımcı ev sahiplerinin birden fazla dairesi bulunmaktadır):

| # | Profil ID (UUID) | Ad Soyad | E-posta | Telefon | Mülk Sayısı | Tip & Not |
|---|---|---|---|---|---|---|
| **L1** | `11111111-aaaa-4000-8000-000000000001` | Marko Petrović | `marko.petrovic@example.com` | `+381 64 111 2233` | 2 Daire | Yerel yatırımcı (Vračar & Dorćol) |
| **L2** | `11111111-aaaa-4000-8000-000000000002` | Jelena Jovanović | `jelena.jovanovic@example.com` | `+381 63 222 3344` | 2 Daire | İş kadını (Novi Beograd & Senjak) |
| **L3** | `11111111-aaaa-4000-8000-000000000003` | Ahmet Yılmaz | `ahmet.yilmaz@example.com` | `+90 532 333 4455` | 2 Daire | Yabancı yatırımcı (Belgrade Waterfront) |
| **L4** | `11111111-aaaa-4000-8000-000000000004` | Nikola Đorđević | `nikola.djordjevic@example.com` | `+381 62 444 5566` | 1 Daire | Doktor (Stari Grad) |
| **L5** | `11111111-aaaa-4000-8000-000000000005` | Milica Popović | `milica.popovic@example.com` | `+381 65 555 6677` | 1 Daire | Emekli mimar (Zvezdara) |
| **L6** | `11111111-aaaa-4000-8000-000000000006` | Stefan Ilić | `stefan.ilic@example.com` | `+381 61 666 7788` | 1 Daire | Girişimci (Novi Sad - Centar) |
| **L7** | `11111111-aaaa-4000-8000-000000000007` | Bojana Lukić | `bojana.lukic@example.com` | `+381 69 777 8899` | 1 Daire | Akademisyen (Novi Sad - Liman) |

---

## 2. Kiracılar (10 Tenants — `profiles`)

10 dairede ikamet eden kiracılar (yerel profesyoneller, expatlar ve aileler):

| # | Profil ID (UUID) | Ad Soyad | E-posta | Telefon | İkamet Ettiği Ev | Kira Süresi |
|---|---|---|---|---|---|---|
| **T1** | `22222222-bbbb-4000-8000-000000000001` | Luka Radović | `luka.radovic@example.com` | `+381 60 101 2001` | Ev 1 (Vračar) | 5 aydır kiracı (Kıdemli) |
| **T2** | `22222222-bbbb-4000-8000-000000000002` | Ana Simić | `ana.simic@example.com` | `+381 60 101 2002` | Ev 2 (Dorćol) | 4 aydır kiracı |
| **T3** | `22222222-bbbb-4000-8000-000000000003` | Miloš Božić | `milos.bozic@example.com` | `+381 60 101 2003` | Ev 3 (Novi Beograd) | 4 aydır kiracı |
| **T4** | `22222222-bbbb-4000-8000-000000000004` | Elena Kuzmina | `elena.kuzmina@example.com` | `+381 60 101 2004` | Ev 4 (Senjak) | 3 aydır kiracı (Expat) |
| **T5** | `22222222-bbbb-4000-8000-000000000005` | Caner Demir | `caner.demir@example.com` | `+90 533 101 2005` | Ev 5 (BW Vista) | 3 aydır kiracı (Yazılımcı) |
| **T6** | `22222222-bbbb-4000-8000-000000000006` | Sophie Dupont | `sophie.dupont@example.com` | `+381 60 101 2006` | Ev 6 (BW Aqua) | 2 aydır kiracı (Diplomat) |
| **T7** | `22222222-bbbb-4000-8000-000000000007` | Filip Janković | `filip.jankovic@example.com` | `+381 60 101 2007` | Ev 7 (Stari Grad) | 1 aydır kiracı (Yeni mezun) |
| **T8** | `22222222-bbbb-4000-8000-000000000008` | Ivana Nikolić | `ivana.nikolic@example.com` | `+381 60 101 2008` | Ev 8 (Zvezdara) | Yeni başladı (~10 gün) |
| **T9** | `22222222-bbbb-4000-8000-000000000009` | Aleksandar Vasić | `aleksandar.vasic@example.com` | `+381 60 101 2009` | Ev 9 (Novi Sad Centar) | 5 aydır kiracı |
| **T10**| `22222222-bbbb-4000-8000-000000000010` | Sara Stojanović | `sara.stojanovic@example.com` | `+381 60 101 2010` | Ev 10 (Novi Sad Liman) | Yeni başladı (Bu hafta) |

---

## 3. Evler (10 Properties — `properties`)

Tüm evlerin `agency_id` değeri `0c0ca8df-765a-46de-aee3-b70daa964015` olarak ayarlanmıştır:

| # | Ev ID (UUID) | Ev Sahibi | Kiracı | Başlık | Adres | Şehir | Tip / m² / Kat | Kira | Depozito |
|---|---|---|---|---|---|---|---|---|---|
| **P1** | `33333333-cccc-4000-8000-000000000001` | Marko Petrović (L1) | Luka Radović (T1) | Moderan Stan kod Hrama | Krunska 42, Vračar | Beograd | 2.5 oda / 68 m² / 3. kat | €850 | €850 |
| **P2** | `33333333-cccc-4000-8000-000000000002` | Marko Petrović (L1) | Ana Simić (T2) | Salonski Stan u Centru | Cara Dušana 18, Dorćol | Beograd | 3.0 oda / 85 m² / 2. kat | €950 | €950 |
| **P3** | `33333333-cccc-4000-8000-000000000003` | Jelena Jovanović (L2) | Miloš Božić (T3) | Poslovni Blok Apartman | Bulevar Zorana Đinđića 64, Blok 21 | Beograd | 2.0 oda / 55 m² / 7. kat | €700 | €700 |
| **P4** | `33333333-cccc-4000-8000-000000000004` | Jelena Jovanović (L2) | Elena Kuzmina (T4) | Rezidencijalna Vila Duleks | Sanje Živanovića 12, Senjak | Beograd | 4.0 oda / 140 m² / Villa 1 | €1,800 | €3,600 |
| **P5** | `33333333-cccc-4000-8000-000000000005` | Ahmet Yılmaz (L3) | Caner Demir (T5) | BW Vista Luksuzni Pogled | Hercegovačka 14, BW Vista | Beograd | 2.0 oda / 58 m² / 14. kat | €1,100 | €1,100 |
| **P6** | `33333333-cccc-4000-8000-000000000006` | Ahmet Yılmaz (L3) | Sophie Dupont (T6) | BW Aqua Riverfront Suite | Woodrowa Wilsona 8, BW Aqua | Beograd | 3.0 oda / 92 m² / 9. kat | €1,600 | €1,600 |
| **P7** | `33333333-cccc-4000-8000-000000000007` | Nikola Đorđević (L4) | Filip Janković (T7) | Kompaktan Studio kod Trga | Knez Mihailova 33, Stari Grad | Beograd | Studio / 35 m² / 4. kat | €500 | €500 |
| **P8** | `33333333-cccc-4000-8000-000000000008` | Milica Popović (L5) | Ivana Nikolić (T8) | Uređen Porodični Stan | Bulevar kralja Aleksandra 198 | Beograd | 2.5 oda / 72 m² / 1. kat | €650 | €650 |
| **P9** | `33333333-cccc-4000-8000-000000000009` | Stefan Ilić (L6) | Aleksandar Vasić (T9) | Centar Grada Renoviran | Zmaj Jovina 15 | Novi Sad | 2.0 oda / 50 m² / 2. kat | €550 | €550 |
| **P10**| `33333333-cccc-4000-8000-000000000010` | Bojana Lukić (L7) | Sara Stojanović (T10) | Sunčani Stan kod Dunava | Narodnog Fronta 24, Liman 2 | Novi Sad | 1.5 oda / 44 m² / 5. kat | €450 | €450 |

---

## 4. Sözleşmeler ve Fatura Sorumluluk Dağılımı (`contracts`)

Her sözleşmenin `expenses_config` yapısında 3 fatura kategorisi dağıtılmıştır:
1. **`included`**: Ev sahibi sorumluluğunda / kiraya dahil (€0 ek ödeme).
2. **`utility`**: Kiracı sorumluluğunda (doğrudan sağlayıcıya / kuruma öder, dekontu sisteme yükler).
3. **`owner`**: Kiracının ev sahibine / acenteye ödemesi gereken fatura (kiraya eklenir).

| Mülk & Sözleşme | Başlangıç Tarihi | Durum | Kiraya Dahil (`included`) | Kiracı Direkt Kuruma (`utility`) | Acenteye/Ev Sahibine Ödenen (`owner`) |
|---|---|---|---|---|---|
| **C1** (P1 - Vračar) | 2026-04-01 (5 ay önce) | `active` | Bina Yönetim Aidatı (€20) | Elektrik - EPS (~€45) | İnfostan (€85) |
| **C2** (P2 - Dorćol) | 2026-05-01 (4 ay önce) | `active` | İnternet & Optik TV (€30) | Elektrik - EPS (~€50) | İnfostan (€95) + Bina Temizliği (€15) |
| **C3** (P3 - Novi Bgd) | 2026-05-15 (4 ay önce) | `active` | — | Elektrik (~€40), İnternet (€25) | İnfostan (€75) |
| **C4** (P4 - Senjak Villa) | 2026-06-01 (3 ay önce) | `active` | Bahçıvan & Güvenlik Aidatı (€150), İnfostan/Isınma (€180) | Elektrik (~€120), Yüksek Hızlı Fiber (€45) | Su & Ortak Gider (€60) |
| **C5** (P5 - BW Vista) | 2026-06-15 (3 ay önce) | `active` | BW Concierge & Resepsiyon Aidatı (€110) | Elektrik (~€65) | İnfostan/Klima Merkezi Isı (€90) |
| **C6** (P6 - BW Aqua) | 2026-07-01 (2 ay önce) | `active` | BW Bakım & Temizlik Hizmeti (€130), İnternet (€35) | Elektrik (~€80) | İnfostan (€110) |
| **C7** (P7 - Stari Grad) | 2026-08-01 (1 ay önce) | `active` | İnfostan (€50 - Ev sahibi karşılar) | Elektrik (~€30), İnternet (€20) | — |
| **C8** (P8 - Zvezdara) | 2026-09-01 (Yeni) | `active` | — | Elektrik (~€35), İnternet (€25) | İnfostan (€65) |
| **C9** (P9 - Novi Sad) | 2026-04-15 (5 ay önce) | `active` | Su & Çöp (€15) | Elektrik (~€40), SBB İnternet (€25) | Informatika (€70) |
| **C10** (P10 - Liman) | 2026-09-05 (Yeni) | `active` | — | Elektrik (~€30) | Informatika Novi Sad (€55) |

---

## 5. Finansal Ödemeler — Kiralar ve Faturalar (`rent_payments`)

Acente dashboard'unda zengin grafikler, gecikme uyarıları ve filtrelerin tam çalışması için kurgulanan finansal durumlar:

### Senaryo Dağılımı:
1. **Düzenli Ödenenler (`paid`)**: Vadesinde ödenmiş, ev sahibi/acente tarafından onaylanmış geçmiş aylar.
2. **Ödeme Beyanı Yapılmış, Onay Bekleyenler (`declared`)**: Kiracı dekont yüklemiş, acentenin onaylamasını bekliyor.
3. **Vadesi Gelmiş / Gecikmişler (`overdue`)**: Ödeme günü geçmiş, bildirim tetiklenmiş ödenmemiş kiralar.
4. **Vadesi Gelmemiş Bekleyenler (`pending`)**: Önümüzdeki günlerde vadesi gelecek mevcut ay ödemeleri.
5. **İtirazlı / Uyuşmazlık Kayıtları (`disputed`)**: Yanlış dekont veya eksik tutar sebebiyle reddedilen/itiraz edilen kalemler.

### Detaylı Finans Tablosu Örneği:

| Ev & Kiracı | Kalem Adı | Tutar | Vade Tarihi | Durum (`status`) | Alıcı Türü | Açıklama / Not |
|---|---|---|---|---|---|---|
| **P1** (Vračar - Luka) | Kira (Nisan) | €850 | 2026-04-05 | `paid` | `owner` | Banka havalesi ile ödendi, onaylandı |
| **P1** (Vračar - Luka) | Kira (Mayıs) | €850 | 2026-05-05 | `paid` | `owner` | Onaylandı |
| **P1** (Vračar - Luka) | Kira (Haziran) | €850 | 2026-06-05 | `paid` | `owner` | Onaylandı |
| **P1** (Vračar - Luka) | Kira (Temmuz) | €850 | 2026-07-05 | `paid` | `owner` | Onaylandı |
| **P1** (Vračar - Luka) | Kira (Ağustos) | €850 | 2026-08-05 | `paid` | `owner` | Onaylandı |
| **P1** (Vračar - Luka) | Kira (Eylül) | €850 | 2026-09-05 | `paid` | `owner` | 2026-09-04 tarihinde ödendi |
| **P1** (Vračar - Luka) | İnfostan (Ağustos) | €85 | 2026-08-15 | `paid` | `owner` | Acenteye ödendi |
| **P1** (Vračar - Luka) | İnfostan (Eylül) | €85 | 2026-09-15 | `pending` | `owner` | Vadesine 4 gün var |
| **P2** (Dorćol - Ana) | Kira (Mayıs-Temmuz) | €950/ay | 05.05 - 05.07 | `paid` | `owner` | Ödendi |
| **P2** (Dorćol - Ana) | Kira (Ağustos) | €950 | 2026-08-05 | `paid` | `owner` | Gecikmeli ödendi |
| **P2** (Dorćol - Ana) | **Kira (Eylül)** | **€950** | **2026-09-05** | **`overdue`** | **`owner`** | **Gecikmiş ödeme! Kiracıya hatırlatma iletildi.** |
| **P2** (Dorćol - Ana) | İnfostan + Temizlik | €110 | 2026-09-10 | `declared` | `owner` | Kiracı dekont yükledi, acente onayı bekliyor |
| **P3** (Novi Bgd - Miloš) | Kira (Eylül) | €700 | 2026-09-01 | `declared` | `owner` | Dekont yüklendi (Mobi Banka) |
| **P3** (Novi Bgd - Miloš) | Elektrik (EPS Direkt) | €42 | 2026-09-15 | `paid` | `third_party` | Kiracı EPS gişesine yatırıp fişi sisteme işledi |
| **P4** (Senjak - Elena) | Kira (Haziran-Ağustos) | €1,800/ay | 01.06 - 01.08 | `paid` | `owner` | Düzenli ödendi |
| **P4** (Senjak - Elena) | Kira (Eylül) | €1,800 | 2026-09-01 | `paid` | `owner` | Ödendi |
| **P4** (Senjak - Elena) | Su & Ek Masraf | €60 | 2026-09-10 | `disputed` | `owner` | Sayaç uyuşmazlığı nedeniyle itiraz edildi |
| **P5** (BW Vista - Caner) | Kira (Haziran-Ağustos) | €1,100/ay | 15.06 - 15.08 | `paid` | `owner` | Ödendi |
| **P5** (BW Vista - Caner) | Kira (Eylül) | €1,100 | 2026-09-15 | `pending` | `owner` | Vadesi yaklaşan |
| **P6** (BW Aqua - Sophie) | Kira (Temmuz-Ağustos) | €1,600/ay | 01.07 - 01.08 | `paid` | `owner` | Nakit tahsilat makbuzu ile ödendi |
| **P6** (BW Aqua - Sophie) | Kira (Eylül) | €1,600 | 2026-09-01 | `paid` | `owner` | Acente ofisinde elden teslim alındı |
| **P7** (Stari Grad - Filip) | Kira (Ağustos) | €500 | 2026-08-01 | `paid` | `owner` | İlk kira ödendi |
| **P7** (Stari Grad - Filip) | Kira (Eylül) | €500 | 2026-09-01 | `declared` | `owner` | Dekont incelemede |
| **P8** (Zvezdara - Ivana) | Depozito | €650 | 2026-09-01 | `paid` | `owner` | Depozito hesaba geçti |
| **P8** (Zvezdara - Ivana) | Kira (Eylül) | €650 | 2026-09-10 | `pending` | `owner` | İlk ay kirası ödeme aşamasında |
| **P9** (Novi Sad - Aleksandar)| Kira (Nisan-Ağustos) | €550/ay | Her ayın 15'i | `paid` | `owner` | Düzenli ödendi |
| **P9** (Novi Sad - Aleksandar)| **Kira (Eylül)** | **€550** | **2026-09-15** | **`pending`** | **`owner`** | Bakım masrafından mahsup edilecek |
| **P10** (Novi Sad - Sara) | Depozito + 1. Kira | €900 | 2026-09-05 | `paid` | `owner` | Sözleşme başlangıç tahsilatı tamamlandı |

---

## 6. Bakım & Arıza Kayıtları (`maintenance_requests`, `maintenance_charges` & `maintenance_messages`)

Acente dashboard'undaki **Bakım (Requests/Maintenance)** sekmesini, maliyet mahsup akışlarını ve detaylı sohbet geçmişini gösteren 5 gerçekçi kayıt:

### MR-1: Curenje vode na slavini u kupatilu (Vračar - P1)
* **Talep No:** `MR-10021`
* **Bildiren:** Kiracı Luka Radović
* **Öncelik / Kategori:** `urgent` / `plumbing`
* **Durum:** `resolved` (Tamamlandı)
* **Masraf:** **€85.00** (Zamena Grohe slavine i novih dihtunga)
* **Masraf Kaydı (`maintenance_charges`):** Acente avans ödedi (`agency_advance`), usta "Vodoinstalater Jovanović", kiradan düşüldü (`rent_offset`) ve ev sahibi Marko Petrović onayladı.
* **Sohbet & Statü Geçmişi (`maintenance_messages` / `activity_logs`):** Kiracının acil çağrısı → Acentenin usta yönlendirmesi → Ev sahibinin kaliteli Grohe batarya onaylaması → Ustanın montajı bitirip dekontu paylaşması → Kiracı ve ev sahibinin memnuniyet onayı.

### MR-2: Problem sa grejanjem - radijatori u dnevnoj sobi hladni (Novi Sad - P9)
* **Talep No:** `MR-10022`
* **Bildiren:** Kiracı Aleksandar Vasić
* **Öncelik / Kategori:** `urgent` / `heating`
* **Durum:** `resolved` (Tamamlandı)
* **Masraf:** **€140.00** (Zamena cirkulacione pumpe i odzračivanje radijatora)
* **Masraf Kaydı (`maintenance_charges`):** Kiracı ustaya elden ödedi (`reimbursement`), usta "Termo Eko Servis Novi Sad", faturayı beyan etti ve acente kiradan mahsup onayını verdi.
* **Sohbet & Statü Geçmişi (`maintenance_messages` / `activity_logs`):** Kiracı soğuk uyarısı → Acente yetkilendirmesi → Servis faturası yüklemesi → Kiradan €140 düşüm mutabakatı.

### MR-3: Klima uređaj ne hladi (sumnja na curenje gasa) (BW Vista - P5)
* **Talep No:** `MR-10023`
* **Bildiren:** Kiracı Caner Demir
* **Öncelik / Kategori:** `normal` / `other`
* **Durum:** `investigating` (İncelemede)
* **Masraf:** **€65.00** (Dopuna gasa R32 i servis filtera)
* **Masraf Kaydı (`maintenance_charges`):** `agency_advance`, servis "Frigo Eko Servis Beograd".
* **Sohbet & Statü Geçmişi:** Kiracı klima gazı şüphesi bildirdi → Agencija Frigo Eko servisi randevuladı → Servis gaz doldurup 24 saatlik basınç testi önerdi.

### MR-4: Pukla gurtna za roletnu na terasi (Novi Beograd - P3)
* **Talep No:** `MR-10024`
* **Bildiren:** Kiracı Miloš Božić
* **Öncelik / Kategori:** `normal` / `other`
* **Durum:** `open` (Yeni Açık Talep)
* **Açıklama:** Gurtna pukla pri povlačenju, roletna ostala zaglavljena na dnu prozora.

### MR-5: Greška E4 na mašini za sudove (zadržavanje vode) (Dorćol - P2)
* **Talep No:** `MR-10025`
* **Bildiren:** Kiracı Ana Simić
* **Öncelik / Kategori:** `normal` / `other`
* **Durum:** `resolved` (Tamamlandı)
* **Masraf:** **€35.00** (Čišćenje odvoda, pumpe i servisni pregled)
* **Masraf Kaydı (`maintenance_charges`):** Kiracı doğrudan ustaya ödedi (`direct_charge`), ev sahibine masraf yansıtılmadı.
* **Sohbet & Statü Geçmişi:** Kiracı E4 hatası bildirdi → Servis yönlendirildi → Pompadan kırık cam parçası çıkarıldı ve kiracı doğrudan ödedi.

---

## 7. Özet İstatistikler (Acente Paneli KPI'ları)

Bu veri seti yüklendiğinde acente dashboard'undaki KPI sayaçları şu değerleri gösterecektir:

* **Yönetilen Mülk Sayısı:** 10 Daire
* **Aktif Doluluk Oranı:** %100 (10 / 10 ev kirada)
* **Aylık Toplam Portföy Kira Hacmi:** **€9,900 / ay**
* **Bekleyen Tahsilatlar (Declared/Pending):** €2,850
* **Gecikmiş Kira Sayısı (Overdue):** 1 Adet (€950 — P2 Dorćol)
* **Açık / Devam Eden Arıza Talepleri:** 2 Adet (MR-10023 ve MR-10024)
* **Çözülmüş Bakım Talepleri:** 3 Adet
