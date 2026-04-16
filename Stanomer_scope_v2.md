# 🏠 Stanomer — Master Product Scope (v2.0)

**Hazırlanma Tarihi:** 04.04.2026  
**Güncelleme Tarihi:** 05.04.2026  
**Hedef Pazar:** Sırbistan (Belgrad, Novi Sad)  
**Yazılım Yığını:** Flutter (Android, iOS, Web), Supabase, Firebase Cloud Messaging (FCM), Resend.

---

## 📋 Proje Özeti ve Kapsam Dağılımı

Stanomer; Sırbistan pazarındaki ev sahipleri ve kiracılar arasındaki finansal ve idari süreçleri dijitalleştiren bir platformdur.

| Kapsam | Durum | Açıklama |
|:---|:---|:---|
| ✅ **Hard MVP** | Kritik & Zorunlu | İlk yayında (App Store/Play Store) olması gereken minimum çekirdek özellikler. |
| 🟡 **MVP1.5** | Kısa Vadeli | İlk yayın sonrası hızla eklenmesi hedeflenen tamamlayıcı özellikler. |
| 🔵 **MVP2** | İkinci İterasyon | Kullanıcı deneyimini zenginleştiren ve otomasyon sağlayan özellikler. |

---

## 🌐 Dil & Lokalizasyon

> **Karar gerektirir — scope'u doğrudan etkiler.**

- **Birincil dil:** Sırpça (Latin alfabesi önerilen — hem Sırp hem Hırvat/Bosnalı kullanıcıya hitap eder)
- **İkincil dil:** İngilizce (expat kiracı segmenti için)
- Kiril desteği MVP2'ye ertelenebilir; ancak Flutter'da `intl` paketi ile altyapı baştan kurulmalıdır.

---

## 💰 Monetizasyon Modeli

> **Teknik scope'u etkiler — feature gate noktaları önceden belirlenmeli.**

| Tier | Kapsam | Ücret |
|:---|:---|:---|
| **Ücretsiz** | 1 mülk, temel ledger & bildirim | Ücretsiz |
| **Pro** | Sınırsız mülk, portföy dashboard, kira artış aracı | Aylık/Yıllık abonelik |

> Supabase + FCM + Resend maliyetleri serbest kullanıcı büyümesiyle doğrusal artar. Feature gate'ler en geç MVP1.5'te devreye alınmalıdır.

---

## 1. Hesap, Kimlik & Yasal Uyumluluk

Mağaza politikaları (Apple/Google) ve yerel veri kanunları (GDPR/ZZPL) uyarınca hazırlanan bölümdür.

| ID | User Story | Acceptance Criteria | Kapsam |
|:---|:---|:---|:---|
| **US-01** | E-posta/Şifre Kayıt | E-posta doğrulaması zorunludur. Rol (Ev Sahibi/Kiracı) seçimi yapılır. | ✅ Hard MVP |
| **US-02** | Davet ile Kayıt | 72 saatlik dinamik linkler. Kayıt sonrası mülk ile otomatik eşleşme sağlanır. | ✅ Hard MVP |
| **US-04** | Şifre Sıfırlama | Kullanıcıya tek kullanımlık sıfırlama linki gönderilir. | ✅ Hard MVP |
| **US-32** | **Hesabı Silme** | Apple zorunluluğu: Kullanıcı verilerini uygulama içinden tamamen silebilir. | ✅ Hard MVP |
| **US-33** | **Veri Onay (Consent)** | Kayıt sırasında Sırbistan ZZPL/GDPR uyumlu metin onayı alınır. | ✅ Hard MVP |
| **US-03** | Sosyal Giriş | **Google & Apple Sign-In**. (iOS'ta Apple zorunluluğu karşılanır). | 🔵 MVP2 |

---

## 2. Daire & Sözleşme Yönetimi

Mülk bazlı verilerin ve taraflar arası "mutabakat" süreçlerinin yönetildiği alandır.

| ID | User Story | Acceptance Criteria | Kapsam |
|:---|:---|:---|:---|
| **US-05** | Daire Kaydı | Adres, EUR/RSD seçimi, kira bedeli ve depozito bilgileri girilir. | ✅ Hard MVP |
| **US-06** | ES → Kiracı Daveti | Ev sahibi, kiracının e-postasını girerek sistemi başlatır. | ✅ Hard MVP |
| **US-26** | **Kiracı → ES Daveti** | Kiracı mülkü tanımlar ve ev sahibini sisteme davet eder. | ✅ Hard MVP |
| **US-27** | **Fatura Mutabakatı** | Elektrik, Su, İnternet için "Sorumlu Kim?" ve "Ödeme Yolu" seçilir. | ✅ Hard MVP |
| **US-28** | **Ayarlar Onayı (Consensus)** | Ödeme ayarı değişikliği bildirim ile karşı tarafa iletilir; X gün içinde itiraz edilmezse otomatik kabul edilir. | 🟡 MVP1.5 |
| **US-07** | Sözleşme Arşivi | PDF yükleme, güvenli Storage (Private Bucket) kullanımı. | 🟡 MVP1.5 |
| **US-34** | **İşlem Kanıtı (Log)** | Kritik onaylarda (sözleşme/mutabakat) IP ve zaman damgası tutulur. | 🟡 MVP1.5 |
| **US-35** | **Sözleşme Sona Erme Akışı** | Kira bitiş tarihi yaklaşınca bildirim gönderilir. Taraflar "Yenile" veya "Sonlandır" seçeneğini seçer. Sonlandırma seçilince depozito iade adımı başlatılır ve mülk "Boş" statüsüne geçer. | 🟡 MVP1.5 |
| **US-36** | **Kiracı Ayrılışı & Mülk Devri** | Mevcut kiracı ayrıldıktan sonra mülk arşivlenir; ev sahibi aynı mülk için yeni kiracı daveti yapabilir. Tüm geçmiş ledger erişilebilir kalır. | 🟡 MVP1.5 |
| **US-08** | Portföy Yönetimi | Birden fazla dairenin tek dashboard üzerinden yönetilmesi. (Pro tier) | 🔵 MVP2 |

> **Not — US-28 UX Kararı:** Orijinal "her iki taraf aktif onaylamalı" tasarımı WhatsApp alışkanlıklarına sürtünme yaratır. Önerilen akış: değişiklik → karşı tarafa bildirim → X gün sessizlik = otomatik kabul. Aktif onay yalnızca kira bedeli değişikliği gibi kritik güncellemelerde zorunlu tutulabilir.

---

## 3. Finansal Takip & Ödemeler

Kira ve mutabık kalınan faturaların ödeme süreçlerini kapsar.

| ID | User Story | Acceptance Criteria | Kapsam |
|:---|:---|:---|:---|
| **US-11** | Kira Ödeme Onayı | Ev sahibi ödemeyi "Alındı" olarak işaretler, kiracı geçmişte görür. | ✅ Hard MVP |
| **US-12** | Finansal Geçmiş | Aylık bazda kira ve faturaların toplu ledger dökümü. | ✅ Hard MVP |
| **US-29** | **Fatura Ödeme Takibi** | "Kiracı ES'ye öder" tipi faturalar için "Ödendi/Bekliyor" statüsü. | 🟡 MVP1.5 |
| **US-30** | **Dekont/Makbuz Yükleme** | Kiracı ödeme kanıtını (fotoğraf/PDF) sisteme yükler. | 🟡 MVP1.5 |
| **US-37** | **Kısmi Ödeme İşaretleyici** | Kiracı "Bu ay eksik ödedim" seçeneğini işaretler; ev sahibi kalan tutarı girer. Fark bir sonraki aya borç olarak yansır. | 🟡 MVP1.5 |
| **US-15** | Kira Artış Aracı | SORS (Sırbistan İstatistik) verilerine göre artış önerisi sunar. (Pro tier) | 🔵 MVP2 |
| **US-14** | Kısmi Ödeme (Tam) | Eksik kalan tutarların otomatik devir ve raporlaması. | 🔵 MVP2 |

> **Not — US-37 (Kısmi Ödeme İşaretleyici):** US-14'ün tam otomasyonu MVP2'de kalsın; ancak basit bir "eksik ödeme" işaretleyici Hard MVP'ye alınmaması ilk kullanıcıları WhatsApp'a geri döndürebilir. Bu nedenle MVP1.5'e alındı.

---

## 4. Arıza Bildirimi & Teknik Destek

| ID | User Story | Acceptance Criteria | Kapsam |
|:---|:---|:---|:---|
| **US-16** | Arıza Kaydı | Kiracı başlık, kategori ve açıklama ile talep açar. | ✅ Hard MVP |
| **US-17** | Süreç Takibi | Açık → İnceleniyor → Çözüldü statü geçişleri. | ✅ Hard MVP |
| **US-19** | Fotoğraflı Kanıt | Arızanın fotoğraflarının eklenmesi ve galeride gösterilmesi. | 🔵 MVP2 |
| **US-20** | Acil Durum Bildirimi | Kritik arızalar için öncelikli push bildirimi. | 🔵 MVP2 |

---

## 5. Bildirim Mekanizması

| ID | User Story | Acceptance Criteria | Kapsam |
|:---|:---|:---|:---|
| **US-31** | **Kritik Push (FCM)** | Ödeme günü, yeni davet ve arıza güncellemelerinde anlık bildirim. | ✅ Hard MVP |
| **US-24** | Kanal Tercihleri | Kullanıcı E-posta ve Push kanallarını ayrı ayrı yönetebilir. | 🟡 MVP1.5 |
| **US-25** | Bildirim Merkezi | Uygulama içindeki "Çan" ikonu ile tüm geçmişe erişim. | 🔵 MVP2 |

---

## 🗓 Öncelik Haritası (Özet)

| Öncelik | Story ID'leri | Adet |
|:---|:---|:---|
| ✅ Hard MVP | US-01, 02, 04, 05, 06, 11, 12, 16, 17, 26, 27, 31, 32, 33 | 14 |
| 🟡 MVP1.5 | US-07, 28, 29, 30, 34, 35, 36, 37 | 8 |
| 🔵 MVP2 | US-03, 08, 14, 15, 19, 20, 24, 25 | 8 |

---

## 🏗 Teknik & Stratejik Notlar

- **🌐 Web / 🤖 Android / 🍎 iOS:** Davet linkleri için **Supabase Deep Links** kullanılmalıdır.
- **Para Birimi:** Sırbistan pazarı için EUR ana, RSD ikincil birimdir. Hesaplamalarda kur farkları göz önünde bulundurulmalıdır.
- **Güvenlik (RLS):** Hiçbir kullanıcı, tarafı olmadığı mülke veya belgeye erişemez. Supabase RLS politikaları mülk (`property_id`) üzerinden kurgulanacaktır.
- **Hukuki Geçerlilik:** Dijital mutabakatlar (US-28) ve işlem logları (US-34), Sırbistan yasalarına göre olası uyuşmazlıklarda "delil başlangıcı" olarak tasarlanmıştır.
- **i18n Altyapısı:** Flutter `intl` paketi ile lokalizasyon altyapısı baştan kurulmalı; dil ekleme sonradan kolaylaştırılmalıdır.
- **Feature Gating:** Ücretsiz/Pro tier ayrımı için Supabase'de `subscription_tier` kolonu en geç MVP1.5'te devreye alınmalıdır.

---

## 📝 v1 → v2 Değişiklik Özeti

| # | Değişiklik | Gerekçe |
|:---|:---|:---|
| 1 | Hard MVP / MVP1.5 / MVP2 kapsam katmanı eklendi | 14 story'li tek MVP solo geliştirici için çok geniş |
| 2 | US-28 Consensus akışı yeniden tasarlandı (pasif onay) | Aktif çift onay UX sürtünmesi yaratır; WhatsApp'a dönüşü tetikler |
| 3 | US-35 (Sözleşme Sona Erme) yeni story olarak eklendi | Kiracı çıkışı ve depozito iadesi hayat döngüsünü tamamlıyor |
| 4 | US-36 (Kiracı Ayrılışı & Mülk Devri) yeni story olarak eklendi | Mülkün yeni kiracıya hazırlanması temel iş akışı |
| 5 | US-37 (Kısmi Ödeme İşaretleyici) MVP1.5'e alındı | Tam otomasyon MVP2'de; temel işaretleyici erken vazgeçişi önler |
| 6 | Dil & Lokalizasyon bölümü eklendi | Sırpça/İngilizce karar scope'u doğrudan etkiliyor |
| 7 | Monetizasyon bölümü eklendi | Freemium/Pro tier feature gate kararları teknik planı etkiler |



