# Design System: Stanomer
*Version 3.0 — Renk Audit + Nunito Typography*

---

## Changelog

### v2 → v3: Renk Audit (Logo Renk Hizalaması)

Logodan çıkarılan renklerin sisteme tam olarak yansıtılması için iki kritik düzeltme yapıldı:

**Brand Blue: `#1e4d8c` → `#1a5eb8`**
v1 design system'deki brand blue (`#1e4d8c`) logodaki maviden daha koyu ve daha soğuktu. Logo pikselleri incelendiğinde gerçek değerin `#1a5eb8` olduğu görüldü — daha açık, daha canlı, daha güvenilir. Pressed/dark varyantı `#0e3d80` olarak korundu.

**Paid Green: `#2d7d4f` → `#2db87a`**
v1'deki paid green (`#2d7d4f`) logonun yeşilinden belirgin şekilde daha koyu ve daha soğuktu; "orman yeşili" tonundaydı. Logo yeşilinin gerçek değeri `#2db87a` — canlı, sıcak, el sıkışmanın başarısını temsil eden bir ton. Status pill sistemi bu yeni değerle logo ile tam uyum içinde.

**Terracotta korundu:** Alert rengi `#c8503a` orijinal sistemden değişmedi — bu renk logoya bağlı değil, "uyarı/tehlike" semantic anlamına bağlı. Korunması doğru karar.

**Status pill sistemi güncellendi:** PLAĆENO, ČEKA, KASNI, DELIMIČNO pill'lerinin text ve surface renkleri yeni logo değerleriyle yeniden hizalandı.

---

### v1 → v2: Tipografi Güncellemesi

**Font stack değiştirildi:** DM Sans + DM Serif Display → **Nunito + DM Serif Display + DM Mono**

**Gerekçe:** Logodaki "Stanomer" yazısı geometric-rounded bir sans-serif kullanıyor — harflerin terminal uçları hafif yuvarlatılmış, açık/geniş karakter yapısına sahip, medium-bold ağırlığı oturmuş. DM Sans bu profile kıyasla daha soğuk ve corporate hissettiriyor. Nunito ise:

- Terminal yuvarlaklığı logonun el sıkışma ikonunun organik eğrileriyle uyum kuruyor
- "a", "e", "o" açık harfleri Stanomer kelimesindeki karakterlerle görsel dil tutarlılığı sağlıyor
- Dijital okuryazarlığı düşük veya yaşça büyük kullanıcılar için göz yormayan bir form
- Variable font desteğiyle 300–900 arası eksiksiz weight yelpazesi

**Quicksand neden seçilmedi:** Bold weight'te logo yazısına çok yakın görünse de, light ve regular ağırlıkları finansal data ekranlarında (ödeme satırları, kira miktarları) yeterli ağırlık ve netlik sunmuyor. Legibility önce gelir.

**DM Mono korundu:** Para birimi hizalaması için monospace zorunluluğu değişmedi. DM Mono bu rolde en iyi seçenek olmaya devam ediyor.

---

## 1. Visual Theme & Atmosphere

Stanomer, Sırbistan ve Balkan pazarları için ev sahipleri ve kiracılara yönelik güven öncelikli bir kira yönetim uygulamasıdır. Arayüz, iyi düzenlenmiş bir kira sözleşmesi gibi hissettirmeli — temiz, yetkili ve güven verici — ancak dijital olgunluğu düşük kullanıcılar için de erişilebilir kalmalıdır. Bu bir pazar yeri değil; bir defter, bir kayıt, dijitalleştirilmiş bir el sıkışmadır.

Tasarım, sıcak kırık beyaz bir zemin (`#f8f7f5`) üzerine kuruludur — steril hastane beyazı değil, kaliteli kağıdın rengi — ve ana marka çapası olarak **Tinta Blue** (`#1a5eb8`) ile eşleştirilir. Tinta Blue doğrudan Stanomer logosundan alınmıştır; güveni, resmi belgeleri ve kağıt üzerindeki mürekkeptin güvenilirliğini çağrıştırır. İkinci logo rengi **Sporazum Green** (`#2db87a`) yalnızca onaylanmış ödemeler ve olumlu durumlar için kullanılır — logonun başarılı bir el sıkışmasının görsel dilini güçlendirir. Tek uyarı aksanı **Ćilim Terracotta** (`#c8503a`), yalnızca gecikmiş ödemeler, uyarılar ve acil CTA'lar için ayrılmıştır.

Tipografi, ana değişken font olarak **Nunito**'yu kullanır — yuvarlatılmış terminaller, geniş açık karakter yapısı ve logonun görsel diliyle organik uyum. Büyük gösterim anları (ödeme özetleri, karşılama ekranları) için **DM Serif Display** ile eşleştirilir; burada sıcaklık ve resmiyetin bir arada var olması gerekir. Para birimleri ve sayısal veriler için **DM Mono** — hizalama ve sayısal hassasiyet, ödün verilmez.

Bu kombinasyon şu hissi yaratır: modern bir noter — samimi, kesin, güvenilir.

**Temel Karakteristikler:**
- Sıcak kırık beyaz zemin (`#f8f7f5`) — kağıt, ekran değil
- Tinta Blue (`#1a5eb8`) ana marka çapası — doğrudan logodan, resmi ve güvenilir
- Sporazum Green (`#2db87a`) başarı/ödendi aksanı — doğrudan logodan, yalnızca onaylanmış ödemeler için
- Ćilim Terracotta (`#c8503a`) tek uyarı/alert aksanı
- **Nunito** (variable, 300–900) — logonun yuvarlatılmış geometric yapısıyla uyumlu, yaşlı kullanıcı dostu
- **DM Serif Display** — büyük gösterim anları için sıcaklık
- **DM Mono** — her para birimi değeri için, istisnasız
- Token tabanlı renk sistemi (`--color-*`) Flutter genelinde sistematik temalama için
- İki katmanlı belge gölgesi: yumuşak ambiyans + ince sınır kaldırma
- Cömert border-radius: 8px inputlar, 10px kartlar, 16px sheet/modaller
- Veri öncelikli düzen — miktarlar, tarihler ve durum her zaman görsel kahraman
- Durum pill sistemi: Plaćeno (yeşil), Čeka (amber), Kasni (terracotta), Delimično (mavi)

---

## 2. Color Palette & Roles

### Primary Brand
- **Tinta Blue** (`#1a5eb8`): `--color-brand-primary` — birincil CTA'lar, aktif nav, marka başlıkları — logodan alındı
- **Tinta Blue Dark** (`#0e3d80`): `--color-brand-primary-pressed` — pressed/dark varyantı
- **Tinta Blue Light** (`#e6eef9`): `--color-brand-primary-surface` — tintli arka planlar, seçili satırlar

### Success / Paid
- **Sporazum Green** (`#2db87a`): `--color-success-primary` — onaylanmış ödemeler, olumlu durumlar — logodan alındı
- **Sporazum Green Dark** (`#1d8a5a`): `--color-success-pressed` — pressed/dark varyantı
- **Sporazum Green Surface** (`#e6f7f0`): `--color-success-surface` — ödendi badge arka planları, başarı bannerları

### Alert & Warning
- **Ćilim Terracotta** (`#c8503a`): `--color-alert-primary` — gecikmiş ödemeler, yıkıcı eylemler, acil badge'ler
- **Terracotta Dark** (`#a83d29`): `--color-alert-pressed` — pressed terracotta varyantı
- **Terracotta Surface** (`#fdf0ee`): `--color-alert-surface` — gecikmiş satır arka planları, hata bannerları

### Status System
- **Plaćeno Green** (`#2db87a`): `--color-status-paid` — ödendi badge metni/ikonu
- **Plaćeno Green Surface** (`#e6f7f0`): `--color-status-paid-surface` — ödendi badge arka planı
- **Čeka Amber** (`#b06c10`): `--color-status-pending` — bekleyen/yaklaşan badge
- **Čeka Amber Surface** (`#fef6e8`): `--color-status-pending-surface` — bekleyen badge arka planı
- **Delimično Blue** (`#1a5eb8`): `--color-status-partial` — kısmi ödeme (marka rengini yeniden kullanır)
- **Delimično Blue Surface** (`#e6eef9`): `--color-status-partial-surface` — kısmi badge arka planı

### Text Scale
- **Ink Black** (`#1a1a1a`): `--color-text-primary` — birincil metin — sıcak, asla soğuk saf siyah değil
- **Ink Medium** (`#4a4a4a`): `--color-text-secondary` — ikincil etiketler, açıklamalar
- **Ink Light** (`#767676`): `--color-text-tertiary` — ipuçları, yer tutucular, metadata
- **Ink Disabled** (`rgba(26,26,26,0.32)`): `--color-text-disabled` — devre dışı durum metni
- **Ink Inverse** (`#ffffff`): `--color-text-inverse` — koyu/marka yüzeylerdeki metin

### Surface & Background
- **Paper White** (`#f8f7f5`): `--color-bg-page` — sayfa/ekran arka planı — sıcak kırık beyaz
- **Card White** (`#ffffff`): `--color-bg-card` — kart ve sheet yüzeyleri
- **Divider** (`#ebebeb`): `--color-border-default` — liste ayırıcılar, kart kenarlıkları
- **Input Border** (`#c8c8c8`): `--color-border-input` — form alanı kenarlıkları
- **Input Border Focused** (`#1a5eb8`): `--color-border-focused` — aktif input kenarlığı (marka mavisi)

### Shadows
- **Card Shadow**: `rgba(0,0,0,0.04) 0px 1px 0px 0px, rgba(0,0,0,0.06) 0px 2px 8px 0px`
- **Sheet Shadow**: `rgba(0,0,0,0.08) 0px 4px 16px 0px`
- **Focused Shadow**: `rgba(26,94,184,0.20) 0px 0px 0px 3px`

---

## 3. Typography Rules

### Font Families

| Rol | Font | Gerekçe |
|-----|------|---------|
| **Primary UI** | `Nunito` (variable, 300–900) | Logonun yuvarlatılmış geometric yapısıyla uyum; yaşlı kullanıcı dostu; samimi ama yetkili |
| **Display / Hero** | `DM Serif Display` (400) | Sıcaklık ve resmiyet gerektiren büyük anlar — onboarding, boş durumlar |
| **Monospace (Amounts)** | `DM Mono` | Para birimi hizalaması; sayısal hassasiyet; defter estetiği |

**Fallback zinciri:**
```css
font-family: 'Nunito', 'Quicksand', system-ui, -apple-system, sans-serif;
font-family: 'DM Serif Display', Georgia, serif;
font-family: 'DM Mono', 'Courier New', monospace;
```

> **Not — Quicksand:** Bold weight'te logoya çok yakın görünüm sağlasa da, light/regular ağırlıkları finansal data ekranlarında yeterli görsel ağırlık sunmuyor. Nunito'nun bu weight yelpazesindeki performansı daha tutarlı. Quicksand alternatif font olarak sistem tanımında tutulabilir (yukarıdaki fallback zincirinde görüldüğü gibi) ancak birincil font olarak önerilmez.

### Hierarchy

| Rol | Font | Boyut | Weight | Line Height | Letter Spacing | Notlar |
|-----|------|-------|--------|-------------|----------------|--------|
| Display / Hero | DM Serif Display | 32px (2.00rem) | 400 | 1.25 | normal | Karşılama ekranları, büyük toplamlar |
| Screen Title | Nunito | 24px (1.50rem) | 800 | 1.33 | -0.3px | AppBar başlıkları, bölüm başlıkları |
| Section Heading | Nunito | 20px (1.25rem) | 700 | 1.40 | -0.2px | Kart başlıkları, grup etiketleri |
| Sub-heading | Nunito | 17px (1.06rem) | 700 | 1.41 | normal | Liste öğesi başlıkları, kiracı adları |
| Body Default | Nunito | 15px (0.94rem) | 400 | 1.53 | normal | Açıklamalar, notlar, gövde metni |
| Body Medium | Nunito | 15px (0.94rem) | 600 | 1.53 | normal | Vurgulu gövde metni |
| Amount Large | DM Mono | 28px (1.75rem) | 600 | 1.14 | -0.5px | Toplam kira miktarı, ana rakamlar |
| Amount Default | DM Mono | 17px (1.06rem) | 500 | 1.41 | normal | Satır düzeyi miktarlar |
| Amount Small | DM Mono | 14px (0.88rem) | 400 | 1.43 | normal | İkincil miktarlar, dökümler |
| Label | Nunito | 13px (0.81rem) | 600 | 1.38 | 0.1px | Form etiketleri, sütun başlıkları |
| Caption | Nunito | 12px (0.75rem) | 400 | 1.33 | normal | Zaman damgaları, metadata |
| Badge | Nunito | 11px (0.69rem) | 700 | 1.18 | 0.4px | Durum pilleri — her zaman büyük harf |
| Micro | Nunito | 10px (0.63rem) | 800 | 1.20 | 0.6px | `text-transform: uppercase`, etiketler |

> **Nunito weight notu:** DM Sans'tan farklı olarak Nunito'da 600 weight görsel olarak DM Sans 500'e yakındır. Bu nedenle hiyerarşide bir adım yukarı kaydırma yapıldı: heading'lerde 700→800, sub-heading'lerde 600→700, badge'lerde 600→700.

### Principles

- **Monospace for money:** Tüm para birimi değerleri (RSD, EUR) DM Mono kullanmalıdır. Bu, defter tarzı listelerde rakam hizalamasını sağlar ve sayısal kesinliği iletir.
- **Serif for warmth:** DM Serif Display yalnızca duygusal tonun önemli olduğu ekranlarda görünür — onboarding, boş durumlar, tebrik ekranları. Finansal konuyu insancıllaştırır.
- **Nunito'nun yuvarlaklığını koru:** Logonun yuvarlatılmış karakterleri ve el sıkışma ikonunun organik eğrileriyle görsel uyumu Nunito sağlar. Başka bir sans-serif karıştırma.
- **Kritik bilgi için ince weight yok:** 300–400 weight'ler yalnızca başlık ve metadata için ayrılmıştır. Herhangi bir ödeme miktarı, kiracı adı veya tarih minimum 600 kullanır.
- **Başlıklarda negatif tracking:** Başlıklarda ve miktarlarda -0.2px ile -0.5px harf aralığı, düzenlenmiş, belge benzeri bir his yaratır.
- **Yalnızca büyük harf badge'ler:** Durum pilleri (PLAĆENO, ČEKA, KASNI) her zaman büyük harf ve geniş tracking (0.4px+) ile yazılır — resmi damga estetiğini taklit eder.

---

## 4. Component Stylings

### Buttons

**Primary (Brand Blue)**
- Background: `#1a5eb8`
- Text: `#ffffff`, 16px Nunito weight 700
- Padding: 14px 24px
- Radius: 10px
- Pressed: background `#0e3d80`
- Disabled: `rgba(26,94,184,0.38)` background
- Focus: `rgba(26,94,184,0.20) 0px 0px 0px 3px` ring

**Destructive / Alert**
- Background: `#c8503a`
- Text: `#ffffff`, 16px Nunito weight 700
- Yalnızca şunlar için kullanın: kira sözleşmesini sil, gecikmiş olarak işaretle, geri alınamaz eylemler
- Primary ile aynı boyut ve radius

**Secondary (Outlined)**
- Background: `transparent`
- Border: `1.5px solid #1a5eb8`
- Text: `#1a5eb8`, Nunito weight 700
- Radius: 10px
- Pressed: background `#e6eef9`

**Ghost / Text Button**
- Background: `transparent`
- Text: `#1a5eb8`, Nunito weight 600
- Border yok, shadow yok
- Şunlar için kullanın: ikincil navigasyon, "Detayları gör", satır içi eylemler

**FAB (Floating Action Button)**
- Background: `#1a5eb8`
- İkon: beyaz, 24px
- Radius: 16px (squircle, daire değil — belge estetiği, pazar yeri değil)
- Shadow: `rgba(26,94,184,0.32) 0px 4px 16px`
- Şunlar için kullanın: Ödeme Ekle, Kiracı Ekle, Yeni Kira Sözleşmesi

### Status Pills / Badges
- Radius: 6px (köşeli ama yuvarlatılmış — resmi damga hissi)
- Padding: 3px 8px
- Font: 11px Nunito weight 700, büyük harf, 0.4px tracking
- **Plaćeno (Ödendi)**: bg `#e6f7f0`, text `#1d8a5a`
- **Čeka (Bekliyor)**: bg `#fef6e8`, text `#b06c10`
- **Kasni (Gecikmiş)**: bg `#fdf0ee`, text `#c8503a`
- **Delimično (Kısmi)**: bg `#e6eef9`, text `#1a5eb8`

### Payment Row (ListTile equivalent)
- Background: `#ffffff`
- Padding: 16px yatay, 14px dikey
- Divider: `1px solid #ebebeb` (yalnızca alt, sol 16px içeriden)
- Sol: Ay/tarih etiketi 13px Nunito weight 600 `#4a4a4a`, altında kiracı adı 17px Nunito weight 700 `#1a1a1a`
- Sağ: DM Mono 17px weight 500'de miktar, altında durum pili
- Gecikmiş satır: sol border `3px solid #c8503a`, background `#fdf0ee` %40 opaklıkta
- Pressed: background `#f0f4fa` (düşük opaklıkta marka mavisi tinti)
- Radius: Kart içindeki liste öğelerinde 0px; bağımsız kartlarda 10px

### Cards & Containers
- Background: `#ffffff`
- Radius: 10px (standart), 16px (bottom sheet'ler, modaller)
- Shadow: `rgba(0,0,0,0.04) 0px 1px 0px 0px, rgba(0,0,0,0.06) 0px 2px 8px 0px`
- Padding: 16px
- Bölüm kartları ilgili verileri gruplar (ör. kira sözleşmesi özeti, bir kiracı için ödeme geçmişi)

### Form Inputs
- Background: `#ffffff`
- Border: `1.5px solid #c8c8c8`
- Focused border: `1.5px solid #1a5eb8` + focused shadow ring
- Radius: 8px
- Label: 13px Nunito weight 600, `#4a4a4a`, input'un üzerinde konumlandırılmış
- Placeholder: `#767676`, Nunito weight 400
- Hata durumu: border `#c8503a`, 12px terracotta hata metni altta
- Yükseklik: 52px (mobil için rahat dokunma hedefi)

### AppBar / Navigation
- Background: `#ffffff`
- Alt border: `1px solid #ebebeb`
- Başlık: 18px Nunito weight 800, `#1a1a1a`, ortalanmış
- Öncü/sondaki ikonlar: 24px, `#1a1a1a`
- Alt navigasyon çubuğu: Maksimum 4 sekme, aktif ikon + etiket `#1a5eb8`, pasif `#767676`

### Empty States
- İllüstrasyon: Basit, çizgi-sanatı stili (fotoğrafik içerik yok)
- Başlık: DM Serif Display 24px, `#1a1a1a`
- Gövde: Nunito 15px weight 400, `#4a4a4a`
- CTA: Birincil düğme, ortalanmış
- Boş durumlar şunlar için kullanın: kiracı yok, bu ay ödeme yok, kira sözleşmesi yok

---

## 5. Layout Principles

### Spacing System
- Temel birim: 4px
- Ölçek: 2, 4, 6, 8, 12, 16, 20, 24, 32, 40, 48, 64px
- İçerik kenar marjları: 16px (mobil), 24px (tablet/web)
- Kart iç padding: 16px
- Kartlar arası: 12px boşluk
- Bölümler arası: 24px boşluk

### Screen Structure (Flutter)
- **Scaffold**: Her zaman `#f8f7f5` arka plan
- **AppBar**: Beyaz, 56px yükseklik, 1px alt border
- **Body**: Kaydırılabilir, içerik 16px yatay padding
- **FAB**: Sağ alt, alt ve sağ kenardan 16px
- **Bottom Nav**: Beyaz, 64px yükseklik, 1px üst border

### Information Hierarchy per Screen
1. **Durum özeti** (kaç tane gecikmiş, bu ay toplam borç) — her zaman üstte
2. **Birincil liste** (kiracılar veya ödemeler) — temel içerik
3. **Eylemler** — birincil için FAB, ikincil için bağlamsal kaydırma eylemleri

### Whitespace Philosophy
- **Defter benzeri nefes alanı:** Her ödeme satırı, paket değil taranabilir olacak kadar dikey padding'e ihtiyaç duyar. Basılı bir banka ekstresi düşünün, e-tablo değil.
- **Kart gruplandırması netlik sağlar:** İlgili bilgiler bir kart içinde yaşar. Kartlar arasındaki beyaz alan kaygıları birbirinden ayırır.
- **Görsel karmaşadan kaçının:** Veri ekranlarında dekoratif illüstrasyon yok. Süsleme yalnızca onboarding ve boş durumlarda.

### Border Radius Scale
| Token | Değer | Kullanım |
|-------|-------|----------|
| `--radius-xs` | 4px | Etiketler, mikro badge'ler |
| `--radius-sm` | 6px | Durum pilleri |
| `--radius-md` | 8px | Inputlar, küçük düğmeler |
| `--radius-lg` | 10px | Kartlar, standart düğmeler |
| `--radius-xl` | 16px | Bottom sheet'ler, modaller |
| `--radius-full` | 9999px | Toggle anahtarları, dairesel avatarlar |

---

## 6. Depth & Elevation (Flutter)

| Seviye | Shadow | Flutter Elevation | Kullanım |
|--------|--------|-------------------|----------|
| Flat (0) | Yok | 0 | Sayfa arka planı, liste ayırıcılar |
| Card (1) | `rgba(0,0,0,0.04) 0px 1px 0px 0px, rgba(0,0,0,0.06) 0px 2px 8px` | 1–2 | Ödeme satırları, özet kartları |
| Raised (2) | `rgba(0,0,0,0.08) 0px 4px 16px` | 4 | FAB, eylem sheet'leri |
| Overlay (3) | `rgba(0,0,0,0.12) 0px 8px 24px` | 8 | Bottom sheet'ler, dialoglar |
| Modal (4) | `rgba(0,0,0,0.18) 0px 16px 40px` | 16 | Tam ekran overlay'ler |

**Shadow Felsefesi:** Stanomer'daki gölgeler sade ve serin tonludur (Airbnb gibi sıcak değil), finansal kayıtların gerçekçi doğasını yansıtır. Dramatik gölge yok — her yüzey yükselmesinin işlevsel bir gerekçesi olmalıdır.

**Flutter uygulama notu:** Token tabanlı gölgeler kesin çok katmanlı kontrol gerektirdiğinden, Material'ın varsayılan elevation'ı yerine özel `BoxShadow` listeleriyle `BoxDecoration` kullanın.

---

## 7. Iconography

- **Stil:** Nav ve eylem ikonları için outlined (dolu değil); yalnızca aktif nav durumu için dolu
- **Boyut:** Standart 24px, yoğun listelerde 20px, FAB'da 28px
- **Renk:** Varsayılan `#1a1a1a`, aktif/marka `#1a5eb8`, başarı/ödendi `#2db87a`, uyarı/sil `#c8503a`
- **Önerilen kütüphane:** `lucide_flutter` — DM Mono ve Nunito'nun geometric karakteriyle örtüşen temiz geometric outlineler
- **Ana ikonlar:** `home`, `people`, `receipt_long`, `calendar_month`, `notifications`, `add`, `chevron_right`, `check_circle`, `warning_amber`, `delete_outline`
- **Para birimi sembolü:** Her zaman `RSD` veya `€` metin etiketi olarak gösterin, ikon olarak değil

---

## 8. Data Visualization (Charts)

- **Grafik türü:** Çubuk grafik (aylık ödeme toplama) ve basit çizgi (gelir trendi)
- **Birincil çubuk rengi:** `#1a5eb8` (ödendi)
- **Uyarı çubuk rengi:** `#c8503a` (gecikmiş/boşluk)
- **Bekleyen çubuk rengi:** `#e8b84b` (yaklaşan) — amber, ikisinden de farklı
- **Arka plan:** 10px radius ile `#ffffff` kart
- **Kılavuz çizgileri:** `#ebebeb`, 1px, yalnızca yatay
- **Etiketler:** 12px Nunito weight 400, `#767676`
- **Değer etiketleri:** 13px DM Mono weight 500, `#1a1a1a`
- **Dekoratif gradient yok:** Çubuklar düz, dolgu yok — veriler hissedilmeden okunmalı
- **Önerilen paket:** Flutter için `fl_chart`

---

## 9. Localization & Cultural Notes

- **Para birimi gösterimi:** `15.000 RSD` (binlik ayırıcı olarak nokta, Sırpça konvansiyonu) veya `€150,00` (EUR için ondalık olarak virgül)
- **Tarih formatı:** `DD.MM.YYYY` — standart Sırpça tarih formatı. Asla `MM/DD/YYYY` değil.
- **Grafiklerdeki ay etiketleri:** Sırpça kısa aylar — özellikle Ağustos için Sırpça'da `Avg`
- **Metin uzunluğu:** Sırpça metin çoğunlukla İngilizce eşdeğerinden %20–30 daha uzundur. Tüm UI bileşenleri taşmayı önlemek için Sırpça dizelerle test edilmelidir.
- **Sağdan sola:** Sırpça/Balkan hedef pazarı için gerekli değil.
- **Metinde resmi ton:** Tüm UI dizelerinde resmi ikinci şahıs kullanın (`Vi`, `Vaš`) — bu finansal bir uygulama, sosyal ağ değil.

---

## 10. Do's and Don'ts

### Do ✓
- Tüm ekran arka planları için `#f8f7f5` (sıcak kağıt beyazı) kullanın — arka planlar için asla saf beyaz değil
- Tüm birincil eylemler, aktif durumlar ve marka anları için Tinta Blue (`#1a5eb8`) uygulayın
- Sporazum Green (`#2db87a`) yalnızca ödendi/onaylandı ödeme durumları için — logoya bağlanır ve "tamamlandı" anlamına gelir
- Ćilim Terracotta (`#c8503a`) yalnızca gecikmiş, uyarı ve yıkıcı durumlar için
- Her para birimi miktarı için DM Mono kullanın — defterlerde hizalama tartışmasız
- Tüm kartlar için iki katmanlı belge gölgesi uygulayın: `rgba(0,0,0,0.04) + rgba(0,0,0,0.06)`
- Kartlar/düğmeler için 10px radius, inputlar için 8px — kesin, yumuşak değil
- Her yerde tarihleri `DD.MM.YYYY` formatında gösterin
- Gecikmiş satırları sol border ile işaretleyin (`3px solid #c8503a`) — taranabilir durum için
- Duygusal ekranlar için DM Serif Display kullanın (onboarding, boş durumlar)
- İlgili verileri kartlar içinde gruplandırın — asla konteyner bağlamı olmadan ham listeler sunmayın
- Başlıklarda ve sub-heading'lerde Nunito 700–800 weight kullanın — ince weight'ler Nunito'da daha belirgin görünür

### Don't ✗
- Sayfa arka planı olarak saf beyaz (`#ffffff`) kullanmayın — steril ve eksik görünür
- Büyük arka plan yüzeylerine Tinta Blue uygulamayın — çapa, dolgu değil
- Aynı ekranda para birimi formatlarını karıştırmayın
- Ödeme miktarları veya kiracı adları için ince weight (300–400) kullanmayın
- Veri ekranlarına dekoratif illüstrasyon eklemeyin — süsleme yalnızca onboarding'de
- Daire FAB kullanmayın — belge estetiğini korumak için squircle (16px radius) kullanın
- Herhangi bir tek durum sisteminde 4'ten fazla renk kullanmayın — 4 durumlu pill (Ödendi/Bekliyor/Gecikmiş/Kısmi) sınırıdır
- Dramatik sıcak gölgeler kullanmayın — gölgeleri serin ve sade tutun (finansal, konaklama değil)
- Boş durumları atlayın — her liste ekranının tasarlanmış bir boş durumu olmalıdır
- Ürünün herhangi bir yerinde `MM/DD/YYYY` tarih formatı kullanmayın
- UI ekranlarında Nunito dışında başka bir sans-serif karıştırmayın — tutarlılık için Nunito tek sans-serif'tir

---

## 11. Flutter Token Reference

```dart
// typography.dart — Stanomer Typography Tokens
// Font değişikliği: DM Sans → Nunito (v2.0)
// Gerekçe: Logo geometric-rounded yapısıyla uyum, yaşlı kullanıcı dostu

abstract class StanomerTypography {
  static const fontSans   = 'Nunito';           // v2: DM Sans → Nunito
  static const fontSerif  = 'DM Serif Display'; // değişmedi
  static const fontMono   = 'DM Mono';          // değişmedi — para hizalaması için zorunlu

  // Weight notu: Nunito'da görsel ağırlık DM Sans'tan farklıdır.
  // DM Sans w600 ≈ Nunito w700, DM Sans w700 ≈ Nunito w800
  // Hiyerarşi buna göre ayarlandı.

  static const displayHero = TextStyle(
    fontFamily: fontSerif,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.25,
    color: StanomerColors.textPrimary,
  );

  static const screenTitle = TextStyle(
    fontFamily: fontSans,
    fontSize: 24,
    fontWeight: FontWeight.w800,  // DM Sans w700'e karşılık Nunito w800
    height: 1.33,
    letterSpacing: -0.3,
    color: StanomerColors.textPrimary,
  );

  static const sectionHeading = TextStyle(
    fontFamily: fontSans,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.40,
    letterSpacing: -0.2,
    color: StanomerColors.textPrimary,
  );

  static const subHeading = TextStyle(
    fontFamily: fontSans,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.41,
    color: StanomerColors.textPrimary,
  );

  static const bodyDefault = TextStyle(
    fontFamily: fontSans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.53,
    color: StanomerColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontFamily: fontSans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.53,
    color: StanomerColors.textPrimary,
  );

  static const amountLarge = TextStyle(
    fontFamily: fontMono,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.14,
    letterSpacing: -0.5,
    color: StanomerColors.textPrimary,
  );

  static const amountDefault = TextStyle(
    fontFamily: fontMono,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.41,
    color: StanomerColors.textPrimary,
  );

  static const amountSmall = TextStyle(
    fontFamily: fontMono,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: StanomerColors.textSecondary,
  );

  static const label = TextStyle(
    fontFamily: fontSans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.38,
    letterSpacing: 0.1,
    color: StanomerColors.textSecondary,
  );

  static const caption = TextStyle(
    fontFamily: fontSans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: StanomerColors.textTertiary,
  );

  static const badge = TextStyle(
    fontFamily: fontSans,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: 0.4,
    // Her zaman TextStyle içinde toUpperCase() uygula
  );

  static const micro = TextStyle(
    fontFamily: fontSans,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    height: 1.20,
    letterSpacing: 0.6,
    // Her zaman TextStyle içinde toUpperCase() uygula
  );
}

// colors.dart — Stanomer Design Tokens
// v3 renk audit: logo pikselleri ile tam hizalama
// Brand Blue: #1e4d8c → #1a5eb8 | Paid Green: #2d7d4f → #2db87a | Terracotta: korundu

abstract class StanomerColors {
  // Brand (logodan)
  static const brandPrimary        = Color(0xFF1A5EB8);
  static const brandPrimaryPressed = Color(0xFF0E3D80);
  static const brandPrimarySurface = Color(0xFFE6EEF9);

  // Success / Paid (logodan)
  static const successPrimary  = Color(0xFF2DB87A);
  static const successPressed  = Color(0xFF1D8A5A);
  static const successSurface  = Color(0xFFE6F7F0);

  // Alert / Overdue
  static const alertPrimary = Color(0xFFC8503A);
  static const alertPressed  = Color(0xFFA83D29);
  static const alertSurface  = Color(0xFFFDF0EE);

  // Status
  static const statusPaid           = Color(0xFF2DB87A);
  static const statusPaidSurface    = Color(0xFFE6F7F0);
  static const statusPending        = Color(0xFFB06C10);
  static const statusPendingSurface = Color(0xFFFEF6E8);
  static const statusPartial        = Color(0xFF1A5EB8);
  static const statusPartialSurface = Color(0xFFE6EEF9);

  // Text
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A4A4A);
  static const textTertiary  = Color(0xFF767676);
  static const textDisabled  = Color(0x521A1A1A); // %32 opaklık
  static const textInverse   = Color(0xFFFFFFFF);

  // Surface
  static const bgPage       = Color(0xFFF8F7F5);
  static const bgCard       = Color(0xFFFFFFFF);
  static const borderDefault = Color(0xFFEBEBEB);
  static const borderInput  = Color(0xFFC8C8C8);
}

// radius.dart

abstract class StanomerRadius {
  static const xs   = Radius.circular(4);
  static const sm   = Radius.circular(6);
  static const md   = Radius.circular(8);
  static const lg   = Radius.circular(10);
  static const xl   = Radius.circular(16);
  static const full = Radius.circular(9999);
}

// shadows.dart

abstract class StanomerShadows {
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 0, offset: Offset(0, 1)),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const fab = [
    BoxShadow(color: Color(0x521A5EB8), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

// pubspec.yaml — Google Fonts dependency (v3 — font + renk güncellemesi)
// Değişen: dm_sans kaldırıldı, nunito eklendi

dependencies:
  google_fonts: ^6.2.1

// Kullanım:
// import 'package:google_fonts/google_fonts.dart';
// GoogleFonts.nunito(textStyle: StanomerTypography.screenTitle)
// GoogleFonts.dmSerifDisplay(textStyle: StanomerTypography.displayHero)
// GoogleFonts.dmMono(textStyle: StanomerTypography.amountLarge)
```

---

## 12. Agent Prompt Guide

### Quick Color Reference
- Sayfa arka planı: `#f8f7f5` (sıcak kağıt, beyaz değil)
- Kart yüzeyi: `#ffffff`
- Birincil metin: `#1a1a1a`
- İkincil metin: `#4a4a4a`
- Marka mavisi: `#1a5eb8` (logo mavi — CTA'lar, aktif durumlar)
- Ödendi yeşili: `#2db87a` (logo yeşil — yalnızca ödendi durumu)
- Uyarı terracotta: `#c8503a` (gecikmiş, yıkıcı — sadece)
- Divider: `#ebebeb`
- Kart gölgesi: `rgba(0,0,0,0.04) 0px 1px 0px, rgba(0,0,0,0.06) 0px 2px 8px`

### Quick Font Reference
- UI metni: `Nunito` — her şey için (başlıklar, gövde, etiketler, badge'ler)
- Hero/Display: `DM Serif Display` — yalnızca büyük duygusal anlar
- Para birimleri: `DM Mono` — her sayısal miktar, istisnasız

### Example Component Prompts (v3 — Nunito + logo renkleri)
- "Ödeme satırı: beyaz kart, 10px radius. Sol: ay etiketi 13px Nunito weight 600 #4a4a4a, kiracı adı 17px Nunito weight 700 #1a1a1a. Sağ: DM Mono 17px weight 500'de miktar, altında durum pili. Gecikmiş varyant: sol border 3px #c8503a, background #fdf0ee %40 opaklıkta."
- "Özet kart: beyaz, 10px radius, kart gölgesi. Başlık: 13px Nunito weight 600 büyük harf 0.1px tracking. Hero miktar: 28px DM Mono weight 600 #1a1a1a. Alt etiket: 13px Nunito #767676."
- "Durum pili: 6px radius, 3px 8px padding. 11px Nunito weight 700 büyük harf 0.4px tracking. Ödendi: bg #e6f7f0 metin #1d8a5a. Gecikmiş: bg #fdf0ee metin #c8503a."
- "Birincil düğme: #1a5eb8 bg, beyaz metin, 10px radius, 14px 24px padding, 16px Nunito weight 700. Pressed: #0e3d80. Focus ring: rgba(26,94,184,0.20) 3px."
- "AppBar: beyaz, 56px, 1px alt border #ebebeb. Başlık: 18px Nunito weight 800 ortalanmış. Öncü geri ikonu: 24px #1a1a1a."
- "Boş durum: DM Serif Display 24px ortalanmış, gövde 15px Nunito #4a4a4a, birincil CTA düğmesi. Veri ekranlarında illüstrasyon yok."

### Iteration Guide
1. `#f8f7f5` sayfa arka planıyla başlayın — kağıdın sıcaklığı tonu belirler
2. Marka mavisi (`#1a5eb8`) tek güven çapasıdır — yalnızca birincil eylemlere uygulayın
3. Ödendi yeşili (`#2db87a`) "başarılı" demektir — onaylanmış ödemeler için tutarlı kullanın
4. Terracotta (`#c8503a`) bir şeylerin yanlış olduğu anlamına gelir — seyrek ve tutarlı kullanın
5. Tüm miktarlar DM Mono'da — her zaman, istisnasız
6. Kartlar için iki katmanlı yumuşak gölge — belge benzeri, dramatik değil
7. Kartlar/düğmeler için 10px radius — kesin belge hissi, balon değil
8. Nunito weight'lerini bir adım yukarı kaydırın (DM Sans w600 → Nunito w700) — ince weight'ler Nunito'da daha belirgin görünür
9. Durum pilleri duygusal yükü taşır — tasarımlarına ve tutarlılıklarına yatırım yapın
10. Sırpça biçimlendirme her zaman: `DD.MM.YYYY` tarihler, nokta ayrımlı binler