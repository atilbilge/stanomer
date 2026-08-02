# STABLE PRODUCTION RULES (CANLI ORTAM KURALLARI)

## 1. Zero Impact on Production (Canlı Ortama Kesinlikle Müdahale Edilmez)
- Canlı (Production) Supabase veritabanına (`ustcsvvkzsmsgzbptvpm`) hiçbir SQL migration, tablo değişikliği, RLS politikası değişikliği veya `NOTIFY` komutu ÖNERİLMEZ ve UYGULANMAZ.
- Canlı ortamda yayınlanmış olan uygulamanın mevcut veri yapısı ve API kontratları (table columns, ENUM values, function signatures) %100 KORUNMALIDIR.
- Geliştirme (Dev) ortamı için yapılan tüm SQL script'leri, migration'lar, yeni kolonlar ve test tanımları YALNIZCA Dev Supabase veritabanını (`thvbpifahvasyzmngpzp`) ve `--flavor dev` / `.env.dev` konfigürasyonunu hedeflemelidir.

## 2. Environment Isolation & Backward Compatibility
- Canlı ortama ait `.env` ve varsayılan konfigürasyonlar (Production URL / Anon Key) asla bozulamaz.
- Düz `flutter run` çalıştırıldığında mevcut canlı sistem kusursuz biçimde çalışmaya devam etmelidir.

## 3. Strict Database Migration Synchronization (Senkronize Migration Yönetimi)
- Geliştirme sürecinde veritabanında yapılacak HER TÜRLÜ değişiklik (yeni tablo, kolon ekleme/silme, RLS politikası güncellemesi, ENUM tipi değişikliği, trigger/function vb.):
  1. Anında `DATABASE_SCHEMA.md` mimari dokümanına ve `setup_dev_database.sql` kurulum betiğine eksiksiz işlenecektir.
  2. %100 güvenli, veri kayıpsız ve idempotent (defalarca çalıştırılabilir) `production_migration_sync.sql` canlı senkronizasyon betiğine anında yansıtılacaktır ve sürekli güncel tutulacaktır.
  3. İlgili değişiklik için tarih ve açıklama içeren bağımsız bir migration SQL dosyası hazırlanacaktır.
- Hiçbir veritabanı değişikliği `production_migration_sync.sql` ve `setup_dev_database.sql` dosyalarına kaydedilmeden "tamamlandı" kabul edilmeyecektir.
