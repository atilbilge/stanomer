# STANOMER VERİ İŞLEME SÖZLEŞMESİ (DATA PROCESSING AGREEMENT - DPA)

> **Yasal Uyarı:** İşbu metin bir sözleşme taslağıdır. Uygulama prodüksiyon ortamında ajansların/kullanıcıların onayına sunulmadan önce faaliyet gösterilen yargı alanına (GDPR, KVKK, Sırbistan ZZPL vb.) uygunluğu açısından bir bilişim ve veri koruma hukuku avukatı tarafından nihai olarak onaylanmalıdır.

---

**Son Güncelleme Tarihi:** 25 Ağustos 2026  
**Sürüm:** 1.1

İşbu Veri İşleme Sözleşmesi ("**DPA**"), Stanomer Hizmet Kullanım Şartları'nın ve Ana Hizmet Sözleşmesi'nin ayrılmaz bir parçasını teşkil eder.

---

## 1. TARAFLAR VE ROLLER

- **Veri Sorumlusu (Data Controller):** Stanomer uygulamasını ve platformunu kendi mülk portföyünü, sözleşmelerini, mali operasyonlarını ve müşteri ilişkilerini yönetmek amacıyla kullanan Mülk Yöneticisi, Emlak Acentesi veya Mülk Sahibi ("**Müşteri / Acente**").
- **Veri İşleyen (Data Processor):** Stanomer platformu, bulut altyapısı ve mobil/web yazılım hizmetlerini sağlayan platform işleticisi ("**Stanomer**").

---

## 2. İŞLEMENİN KONUSU, AMACI VE SÜRESİ

1. **Konu:** Stanomer tarafından sunulan mülk yönetimi yazılımı (SaaS) kapsamında Veri Sorumlusu adına kişisel verilerin toplanması, saklanması, işlenmesi ve senkronize edilmesidir.
2. **Amaç:** Veri Sorumlusu'nun mülk, kiracı, ev sahibi, sayaç okuma, sözleşme, kira tahsilatı, arıza/bakım talepleri ve operasyonel iş akışlarını dijital ortamda yönetmesini sağlamakla sınırlıdır.
3. **Talimatlara Uygunluk:** Stanomer, kişisel verileri yalnızca Veri Sorumlusu'nun belgelenmiş yazılı talimatları ve uygulama üzerindeki kullanıcı eylemleri doğrultusunda işler. Veriler hiçbir koşulda Stanomer tarafından kendi adına ticari amaçla satılamaz, kiralanamaz veya izinsiz üçüncü taraflarla reklam/pazarlama amacıyla paylaşılamaz.
4. **Süre:** İşbu DPA, Veri Sorumlusu'nun Stanomer aboneliği ve hizmet kullanım süresi boyunca yürürlükte kalır.

---

## 3. İŞLENEN KİŞİSEL VERİ KATEGORİLERİ VE İLGİLİ KİŞİ GRUPLARI

### 3.1. İlgili Kişi Grupları (Data Subjects)
- **Kiracılar:** Taşınmazı kiralayan gerçek kişiler ve şirket temsilcileri.
- **Mülk Sahipleri (Ev Sahipleri):** Taşınmaz maliki gerçek kişiler.
- **Acente Çalışanları ve Yöneticileri:** Platformu kullanan yetkili personel.
- **Tedarikçiler / Ustalar:** Bakım ve onarım süreçlerine dahil edilen üçüncü şahıslar.

### 3.2. İşlenen Veri Kategorileri
Stanomer modülleri üzerinden işlenen veriler aşağıdaki kategorileri içerir:

| Veri Kategorisi | Açıklama ve Kapsam |
| :--- | :--- |
| **Kimlik Bilgileri** | Ad, soyad, unvan, uyruk; kiracı sözleşme ve yabancı tescil süreçleri için gerekli durumlarda pasaport/kimlik no. |
| **İletişim Bilgileri** | E-posta adresi, telefon numarası, ikametgah/tebligat adresi. |
| **Taşınmaz / Mülk Verileri** | Mülk açık adresi, daire no, mülk özellikleri, sayaç seri numaraları. |
| **Finansal ve Ödeme Verileri** | Kira bedeli, depozito tutarı, para birimi, ödeme vadeleri, banka/IBAN bilgileri, ödeme dekontları, borç/alacak kayıtları ve ihtilaf (dispute) kayıtları. |
| **Sözleşme ve Belge Verileri** | Kira sözleşmesi şartları, ek protokoller, fesih/tahliye kayıtları, yüklenen sözleşme PDF'leri ve fotoğraflar. |
| **Sayaç ve Tüketim Verileri** | Elektrik, su, doğalgaz sayaç okuma değerleri, tüketim görselleri ve faturalandırma kayıtları. |
| **Bakım & Onarım Verileri** | Arıza talep açıklamaları, hasar/arıza fotoğrafları, durum güncellemeleri ve mesajlaşma geçmişi. |
| **İşlem Güvenliği & Sistem Logları** | IP adresi, giriş zamanları, cihaz bilgisi, kullanıcı hareket kayıtları (`activity_logs`) ve denetim izleri. |

---

## 4. VERİ İŞLEYEN'İN (STANOMER) YÜKÜMLÜLÜKLERİ

### 4.1. Güvenlik ve Teknik Tedbirler
Stanomer, işlenen kişisel verilerin güvenliğini temin etmek amacıyla güncel sektör standartlarına uygun teknik ve idari tedbirleri uygular:
- **Veri İzolasyonu (Row Level Security - RLS):** Her acentenin ve kullanıcının verileri veritabanı seviyesinde katı RLS politikaları ile izole edilir; bir acentenin verilerine başka bir acentenin erişmesi engellenir.
- **İletim Güvenliği:** Sunucular ile istemciler arasındaki tüm veri trafiği uçtan uca TLS 1.3 / HTTPS protokolleri ile şifrelenir.
- **Erişim ve Yetkilendirme:** Veritabanına ve yönetimsel arayüzlere erişim, en az ayrıcalık ilkesi (least privilege) ve çok faktörlü kimlik doğrulama (MFA) ile sınırlandırılmıştır.

### 4.2. Yerel Cihaz Depolaması (Local Storage / Cache) ve Sorumluluk Sınırı
- Stanomer mobil veya web istemcilerinde çevrimdışı çalışma veya performans amacıyla kullanıcının kendi cihazında yerel olarak önbelleğe alınan (Local Storage / Secure Storage) verilerin fiziksel cihaz güvenliği **Veri Sorumlusu'nun ve ilgili son kullanıcının** sorumluluğundadır.
- Kullanıcı cihazının çalınması, root/jailbreak yapılması veya cihaz şifreleme eksikliğinden kaynaklanan yerel sızıntılardan Stanomer sorumlu tutulamaz.

### 4.3. Veri İhlali Bildirimi
Stanomer, kendi denetimindeki sunucu ve bulut altyapısında kişisel verilere yetkisiz erişim, veri kaybı veya sızıntı tespit etmesi durumunda:
1. Durumu gecikmeksizin ve en geç **72 saat içerisinde** Veri Sorumlusu'na yazılı veya e-posta yoluyla bildirir.
2. İhlalin niteliği, etkilenen veri kategorileri, yaklaşık kişi sayısı ve alınan önleyici tedbirler hakkında detaylı bilgi sağlar.

### 4.4. İlgili Kişi Hakları (Data Subject Rights - DSR)
Kişisel veri sahiplerinden (kiracı, ev sahibi vb.) gelen erişim, düzeltme, silme veya itiraz taleplerinin karşılanması Veri Sorumlusu'nun yükümlülüğündedir. Stanomer, platformun teknik imkanları dahilinde Veri Sorumlusu'na bu talepleri yerine getirebilmesi için gerekli dışa aktarma (export) ve silme araçlarını sunar.

### 4.5. Gizlilik Taahhüdü
Stanomer, kişisel verilere erişimi olan tüm personelinin ve alt yüklenicilerinin sözleşmesel veya yasal gizlilik yükümlülüğü altında olduğunu taahhüt eder.

---

## 5. ALT İŞLEYİCİLER (SUB-PROCESSORS)

1. **Genel Yetkilendirme:** Veri Sorumlusu, Stanomer'in hizmeti sağlayabilmek amacıyla üçüncü taraf altyapı ve yazılım sağlayıcılarını ("Alt İşleyici") kullanmasına genel onay verir.
2. **Mevcut Alt İşleyiciler Listesi:**
   - **Supabase Inc.:** Veritabanı barındırma, kullanıcı kimlik doğrulama (Auth), bulut dosya depolama (Storage) ve gerçek zamanlı senkronizasyon (Realtime).
   - **Bulut Barındırma & CDN (AWS / Vercel / Cloudflare):** Web uygulaması barındırma, DNS ve ağ güvenliği.
   - **İletişim & Bildirim Servisleri (Resend / Firebase Cloud Messaging):** Sistem bildirimleri, şifre sıfırlama ve e-posta gönderimleri.
3. **Değişiklik Bildirimi:** Stanomer, altyapısına yeni bir alt işleyici eklemesi veya mevcut olanı değiştirmesi durumunda web sitesi veya e-posta kanalıyla makul bir süre önceden bildirimde bulunur. Veri Sorumlusu'nun haklı gerekçelerle itiraz etme hakkı saklıdır.

---

## 6. ULUSLARARASI VERİ AKTARIMI

Hizmetlerin ifası için kullanılan bulut sunucularının veya alt işleyicilerin farklı ülkelerde bulunması halinde, Stanomer yürürlükteki veri koruma mevzuatına (GDPR Madde 44-49, KVKK Madde 9 vb.) uygun güvenceleri (Standart Sözleşme Maddeleri - SCC veya eşdeğer yasal mekanizmalar) sağlar.

---

## 7. VERİLERİN İADESİ, İMHASI VE HESAP KAPATMA

1. **Hizmet Sona Ermesi:** Abonelik feshedildiğinde veya hesap kapatıldığında Veri Sorumlusu, Stanomer arayüzü üzerinden portföy ve müşteri verilerini dışa aktarma (JSON / CSV / PDF) imkanına sahiptir.
2. **Silme ve İmha:** Hizmet ilişkisinin sonlanmasını takip eden **30 gün** içinde (kanunen saklanması zorunlu mali ve yasal log kayıtları hariç olmak üzere) Veri Sorumlusu'na ait tüm veriler canlı veritabanından güvenli biçimde silinir. Yedek sistemlerdeki veriler rutin yedekleme döngüsünün (en geç 90 gün) sonunda üzerine yazılarak kalıcı olarak imha edilir.

---

## 8. DENETİM VE BİLGİ EDİNME HAKKI

Stanomer, Veri Sorumlusu'nun işbu DPA kapsamındaki yükümlülüklere uyumu doğrulayabilmesi için gerekli teknik ve idari güvenlik sertifikasyonlarını, uyumluluk özetlerini ve belgelerini talep halinde paylaşır.

---

## 9. YÜRÜRLÜK VE DEĞİŞİKLİKLER

İşbu Sözleşme, Veri Sorumlusu'nun Stanomer platformuna kaydolması, ilgili kutucuğu işaretlemesi veya platformu kullanmaya başlaması ile birlikte yürürlüğe girer. Stanomer, mevzuat değişiklikleri veya sistem güncellemeleri doğrultusunda bu DPA'yı güncelleyebilir; güncel metin platform üzerinde yayımlanır.

---

### TARAFLARIN BEYANI
Veri Sorumlusu, işbu Veri İşleme Sözleşmesi'nin tüm maddelerini okuduğunu, anladığını ve uygulamayı kullanarak onayladığını kabul ve beyan eder.
