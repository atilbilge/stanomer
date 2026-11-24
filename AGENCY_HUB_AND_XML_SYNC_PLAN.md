# Stanomer Agency Hub & Çoklu Portal Senkronizasyonu (Ürün ve Teknik Plan)

## 1. Vizyon ve Değer Önerisi

### Problem:
Sırbistan emlak pazarındaki ~1.500 lisanslı acente için iki büyük operasyonel tıkanıklık bulunmaktadır:
1. **Zaman ve Operasyon Kaybı:** Bir ilanı aynı anda hem Halo Oglasi, hem 4zida, hem Nekretnine.rs, hem de kendi web sitelerine girmek zorunda kalıyorlar.
2. **Eski Dinozor Yazılımlar:** Halihazırda kullandıkları yerel programlar (REAA, Program Nek vb.) 2010'lardan kalma eski PHP arayüzlerine sahip, mobil uyumsuz ve çağ dışı web şablonları sunuyor. Üstelik bunun için ayda 50 - 60 € ödüyorlar.
3. **Sitesi Olmayan Acenteler:** Pazardaki butik ajansların yüzlercesi bağımsız bir web sitesine sahip değil; portalların yüksek listeleme maliyetlerine bağımlı durumdalar.

### Çözüm (Stanomer Agency Hub):
Stanomer'i sadece bir tüketici arama motoru olmaktan çıkarıp, acentelerin tüm dijital operasyonunu yöneten **"Merkezi Dağıtım ve Yönetim Altyapısı"** haline getirmek:
- **Tek Noktadan Giriş:** Acente ilanı Stanomer paneline 2 dakikada girer.
- **Otomatik Dış Dağıtım:** İlan otomatik olarak **4zida.rs, Halo Oglasi, Nekretnine.rs ve Sasomange** uyumlu XML feed'e dönüşür ve bu portallarda anında güncellenir.
- **Modern Kurumsal Vitrin:** Acentenin kendi alan adında (`acenteadi.rs`) çalışan modern, mobil uyumlu, hızlı bir web sitesi altyapısı sağlanır.
- **Stanomer Ekosistemi:** İlanlar doğrudan `stanomer.online` ve `stanomerapp` mobil uygulamasında "Doğrulanmış Partner Portföyü" olarak öne çıkar; acenteye doğrudan alıcı yönlendirilir.

---

## 2. Sistem Mimarisi

```
[ Acente / Danışman ]
         │
         ▼ (İlan, Fiyat, Fotoğraf Girişi)
[ Stanomer Web Sitesi (stanomer.online) ]
  • /agency-panel (Yönetim Paneli)
  • /api/feed/[agency_id]/[portal].xml (XML Motoru)
         │
         ▼ (Merkezi Veri Kaynağı - PostgreSQL)
[ Supabase Veritabanı ]
  • properties
  • property_images
         │
         ├──────────────────────┬──────────────────────┐
         ▼                      ▼                      ▼
  [ Stanomer Web ]       [ Stanomer App ]       [ Dış Portallar ]
  (stanomer.online)      (iOS & Android)        (4zida, Halo Oglasi XML)
```

---

## 3. Veritabanı Modeli (Supabase / PostgreSQL)

### A. `properties` Tablosu
- `id`: UUID / BigInt (Primary Key)
- `agency_id`: İlanın ait olduğu acente (Foreign Key -> `agencies.id`)
- `external_ref`: Acentenin dahili ilan kodu (örn: `BG-2041`)
- `title`: İlan başlığı (Sırpça)
- `description`: Detaylı açıklama metni
- `transaction_type`: `prodaja` (satılık) / `izdavanje` (kiralık)
- `property_type`: `stan` (daire), `kuca` (ev), `poslovni_prostor` (işyeri), `plac` (arsa), `garaza` (garaj)
- `price`: Sayısal tutar
- `currency`: `EUR` veya `RSD`
- `area_m2`: Metrekare (ondalıklı)
- `rooms`: Oda yapısı (`0.5`, `1.0`, `1.5`, `2.0`, `2.5`, `3.0`, `3.5`, `4.0+`)
- `floor`: Bulunduğu kat (-1, 0, 1, 2...)
- `total_floors`: Binadaki toplam kat sayısı
- `heating`: `CG` (merkezi), `EG` (kat kaloriferi), `Gas`, `Struja`, `Podno`, `Klima`
- `condition`: `Novogradnja`, `Renovirano`, `Izvorno`, `U_izgradnji`
- `city`: `Beograd`, `Novi Sad`, `Niš` vb.
- `municipality`: Opština (Stari Grad, Vračar, Novi Beograd, Zvezdara vb.)
- `neighborhood`: Naselje (Centar, Dorćol, Bežanijska Kosa vb.)
- `address`: Açık sokak ve kapı no
- `features`: JSONB veya boolean sütunlar (asansör, teras, otopark, klima, interfon vb.)
- `is_active`: Boolean (ilan yayında mı)
- `created_at` / `updated_at`: Zaman damgaları

### B. `property_images` Tablosu
- `id`: UUID (Primary Key)
- `property_id`: Foreign Key (`properties.id`)
- `url`: Supabase Storage veya CDN üzerindeki genel resim linki
- `order_index`: Sıralama (0, 1, 2...)
- `is_cover`: Kapak fotoğrafı mı?

---

## 4. XML Feed Motoru (Next.js App Router)

### Uç Noktalar (Endpoints):
- `GET /api/feed/[agency_id]/4zida.xml`
- `GET /api/feed/[agency_id]/halooglasi.xml`
- `GET /api/feed/[agency_id]/sasomange.xml`

### Çalışma Prensibi:
1. İlgili `agency_id` için `is_active = true` olan tüm ilanlar ve fotoğraflar Supabase'den çekilir.
2. Portala özel eşleştirici (Mapper) fonksiyon çağrılır:
   - 4zida'nın istediği etiketler (`<RealEstateFeed>`, `<Property>`, `<Price>`...)
   - Halo Oglasi'nin istediği etiketler (`<Oglasi>`, `<Oglas>`, `<Cena>`...)
3. Yanıt `Content-Type: application/xml; charset=utf-8` başlığıyla döndürülür.
4. **Önbellek (Caching):**  
   Header: `Cache-Control: public, s-maxage=900, stale-while-revalidate=1800`  
   Portallar saatte bir feed'i çektiğinde veritabanına doğrudan sorgu gitmez; Vercel CDN önbelleğinden milisaniyeler içinde yanıt verilir.

---

## 5. Uygulama Adımları (Fazlar)

### Faz 1: Veritabanı ve Çekirdek Sözlük
- Supabase SQL migration dosyasının çalıştırılması (`properties` ve `property_images`).
- Sırpça lokasyon, oda ve ısıtma sözlüklerinin (`serbianRealEstateDict.ts`) projeye eklenmesi.

### Faz 2: XML Motorunun Kodlanması
- Portallardan gelen resmi XSD ve şablon dokümanlarına göre XML oluşturucu servisinin yazılması.
- Örnek bir acente ve test ilanları ile yerel ortamda XML çıktısının test edilmesi.

### Faz 3: Acente İlan Giriş Paneli (MVP)
- `stanomer.online/agency-panel` altında sade ve modern bir ilan giriş formu.
- Çoklu fotoğraf yükleme (Supabase Storage entegrasyonu).
- Tek tıkla ilan yayınlama / yayından kaldırma.

### Faz 4: Pilot Test & Sahaya Çıkış
- İlk partner acente ile 4zida ve Halo Oglasi hesap yöneticilerine XML feed linkinin iletilmesi.
- Otomatik senkronizasyonun canlı ortamda doğrulanması.
- Soğuk e-posta kampanyasında bu özelliğin acentelere bir teklif olarak sunulması.

