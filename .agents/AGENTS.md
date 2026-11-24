# STABLE PRODUCTION RULES (CANLI ORTAM KURALLARI)

## 1. Zero Impact on Production (Canlı Ortama Kesinlikle Müdahale Edilmez)
- Canlı (Production) Supabase veritabanına (`ustcsvvkzsmsgzbptvpm`) hiçbir SQL migration, tablo değişikliği, RLS politikası değişikliği veya `NOTIFY` komutu ÖNERİLMEZ ve UYGULANMAZ.
- Canlı ortamda yayınlanmış olan uygulamanın mevcut veri yapısı ve API kontratları (table columns, ENUM values, function signatures) %100 KORUNMALIDIR.
- Geliştirme (Dev) ortamı için yapılan tüm SQL script'leri, migration'lar, yeni kolonlar ve test tanımları YALNIZCA Dev Supabase veritabanını (`nbcbfmhztnnhfnapvaet`) ve `--flavor dev` / `.env.dev` konfigürasyonunu hedeflemelidir.

## 2. Environment Isolation & Backward Compatibility
- Canlı ortama ait `.env` ve varsayılan konfigürasyonlar (Production URL / Anon Key) asla bozulamaz.
- Düz `flutter run` çalıştırıldığında mevcut canlı sistem kusursuz biçimde çalışmaya devam etmelidir.

## 3. Versioned Database Migration Management (Versiyonlu Migration Yönetimi)
- Geliştirme sürecinde veritabanında yapılacak HER TÜRLÜ değişiklik (yeni tablo, kolon ekleme/silme, RLS politikası güncellemesi, ENUM tipi değişikliği, trigger/function vb.):
  1. Anında `DATABASE_SCHEMA.md` mimari dokümanına ve `setup_dev_database.sql` (sıfırdan kurulum) betiğine eksiksiz işlenecektir.
  2. Her sürüm/değişiklik için `migrations/` dizini altında versiyon/tarih etiketli bağımsız, %100 güvenli, veri kayıpsız ve idempotent (örn. `IF NOT EXISTS`, `DO $$ BEGIN ... END $$`) migration SQL dosyaları hazırlanacaktır (örn. `migrations/v2.0.2_release_sync.sql` veya `migrations/YYYY-MM-DD_aciklama.sql`).
  3. Tek parça monolitik `production_migration_sync.sql` yerine sürüme özel (versioned/incremental) migration script'leri esas alınacaktır.
- Hiçbir veritabanı değişikliği `migrations/` altındaki ilgili versiyon script'ine ve `DATABASE_SCHEMA.md` / `setup_dev_database.sql` dosyalarına kaydedilmeden "tamamlandı" kabul edilmeyecektir.

## 4. Zero Hardcoded / Static User-Facing Text Rule (Sıfır Statik Metin & %100 i18n Kuralı)
- **KOD İÇİNDE ASLA HARDCODED / STATİK METİN YAZILAMAZ:**
  - Website & Web Paneli tarafında: Tüm metinler `website/lib/translations.json` dosyasına işlenmeli ve `t("anahtar")` fonksiyonu ile çağrılmalıdır.
  - Flutter mobil/web tarafında: `AppLocalizations` / `l10n` kullanılmalıdır.
  - Form validasyon hataları, uyarılar (warnings), doğrulama kutuları (pre-flight validator), başlıklar, butonlar, rozetler ve tooltip'ler DAHİL kullanıcıya gösterilen hiçbir metin doğrudan `.tsx`, `.ts` veya `.dart` dosyalarına Türkçe, İngilizce veya başka bir dilde sabit string olarak YAZILAMAZ.
- **5 DİL EŞZAMANLI GÜNCELLENMELİDİR:**
  - `website/lib/translations.json` içine yeni bir anahtar eklendiğinde, sistemde tanımlı **5 dilin tamamına (`TR`, `EN`, `SR_LAT`, `SR_CYR`, `RU`)** eksiksiz çevirisi girilmeden iş tamamlanmış sayılamaz.
- **VALIDATOR VE SERVİSLER SADECE KEY DÖNEBİLİR:**
  - Doğrulayıcılar (validators), yardımcı fonksiyonlar ve servisler doğrudan son kullanıcı metni döndüremez. Yalnızca `{ key: "agency_val_...", defaultText: "..." }` nesnesi dönebilir. UI bileşeni bunu `t(err.key)` ile dile uygun basar.
- **HEDEF PAZAR BİLİNCİ:**
  - Stanomer'in ana pazarı Sırbistan'dır (Sırpça Latin & Kiril, İngilizce birincil dillerdir). Kod içine doğrudan Türkçe statik metin bırakmak mimari bir hatadır.


