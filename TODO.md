# 📝 Stanomer — TODO & Gelecek Özellikler (Roadmap)

## 📌 Sözleşme & Kontrat Yönetimi
- [ ] **Kira Kontrat Yenileme Mutabakatı**: Kira kontratı bitiş tarihinden **30 gün önce** kiracının ve ev sahibinin karşılıklı mutabakatla kontratı yenileyebilmesi / yeni döneme uzatabilmesi akışının eklenmesi.

## 📌 Performans & Mimari (Canlı Sürüm / Release Senkronizasyonu)
- [ ] **Acente Finans Ekranı / View Senkronizasyonu (Flutter & Supabase)**:
  - Canlı (Production) veritabanına `migrations/2026-11-18_view_agency_financial_ledger.sql` uygulandığında, Flutter acente panelindeki (`agency_dashboard_screen.dart`) 36 paralel WebSocket `getRentPaymentsStream` dinleyicisini `view_agency_financial_ledger` view'ine veya optimize edilmiş REST + Realtime invalidation mekanizmasına bağlamak.
  - **Hedef:** Acente portföyü 100+ mülke çıktığında Supabase soket kanal limiti ve Realtime stream sayfalama (pagination) tavanına takılmadan, büyük veri setlerinin tek pakette güvenle ve ultra hızlı çekilmesini sağlamak.

## 📌 UI / UX & Tasarım Tutarlılığı (Design System & Polish)
- [ ] **Add New Property != Add New Listing Ayrımı**:
  - "Yeni Mülk Ekle" (fiziksel yönetilen portföy mülkü / kontrat & kiracı bağlı mülk) ile "Yeni İlan Ekle" (portallara/web sitesine açılan pazarlama ilanı) akışlarının, butonlarının ve modal/form adımlarının UI düzeyinde birbirinden net biçimde ayrıştırılması ve kavramsal karışıklığın tamamen giderilmesi.
- [x] **Filtre ve Özet Kartlarda Harf Boyutu Tutarlılığı (Uppercase vs. Title Case)**:
  - Filtreler, sekme başlıkları ve özet/KPI sayaç kartlarında sayfalara göre değişen harf formatı karmaşasının (bazı ekranlarda UPPERCASE, bazılarında Title Case) giderilerek tek bir tipografi standardına oturtulması.
- [x] **Bileşen Radius (Border Radius) Değerlerinin Standardizasyonu**:
  - Bütün ekranlardaki kartlar, açılır paneller, modallar, form elemanları, butonlar ve rozetlerdeki tutarsız köşe yuvarlama (`rounded-*`) değerlerinin taranarak marka rehberine uygun tek tip radius hiyerarşisiyle (Design System Token) eşitlenmesi.

