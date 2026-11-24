# Stanomer: Marka Kimliği ve Rehberi

*Brand Guide v3 ve Design System v4 tek belgede. Kasım 2026. Bölüm 1 marka ve iletişimi, Bölüm 2 arayüz değerlerini tanımlar; çelişki durumunda Bölüm 2 geçerlidir.*

**[Bölüm 1: Marka Kimliği](#marka)**

- [Changelog (v2 → v3)](#bg-changelog-v2-v3)
- [1. Marka hikâyesi ve isim](#bg-1-marka-hikayesi-ve-isim)
- [2. Konumlandırma](#bg-2-konumlandirma)
- [3. İddia denetimi](#bg-3-iddia-denetimi)
- [4. Kişilik ve değerler](#bg-4-kisilik-ve-degerler)
- [5. Roller](#bg-5-roller)
- [6. Logo](#bg-6-logo)
- [7. İletişim dili](#bg-7-iletisim-dili)
- [8. Ortak marka (beyaz etiket)](#bg-8-ortak-marka-beyaz-etiket)
- [9. Müşteriye dönük metin kuralları](#bg-9-musteriye-donuk-metin-kurallari)
- [10. Açık kalan kararlar](#bg-10-acik-kalan-kararlar)

**[Bölüm 2: Design System](#ds)**

- [Changelog (v3 → v4)](#ds-changelog-v3-v4)
- [1. Atmosfer](#ds-1-atmosfer)
- [2. Renk (Açık tema)](#ds-2-renk-acik-tema)
- [3. Tipografi](#ds-3-tipografi)
- [4. Bileşenler](#ds-4-bilesenler)
- [5. Yerleşim, radius, gölge](#ds-5-yerlesim-radius-golge)
- [6. İkonlar](#ds-6-ikonlar)
- [7. Grafik](#ds-7-grafik)
- [8. Yerelleştirme](#ds-8-yerellestirme)
- [9. Beyaz etiket kuralları](#ds-9-beyaz-etiket-kurallari)
- [10. Yapma listesi](#ds-10-yapma-listesi)
- [11. Flutter token’ları](#ds-11-flutter-token-lari)
- [12. Agent prompt rehberi](#ds-12-agent-prompt-rehberi)

---

# <a id="marka"></a>Bölüm 1: Marka Kimliği ve Rehberi

*Versiyon 3.0 | Kasım 2026 | v2 üzerine kritik revizyon*  
*Görsel ve UI değerleri için tek kaynak Bölüm 2 (Design System). Bu bölüm renk, font ve bileşen tanımlamaz.*

## <a id="bg-changelog-v2-v3"></a>Changelog (v2 → v3)

1. **Design System ile çelişkiler kaldırıldı.** v2 Inter/Outfit, 16 px kart, 8 px buton, glassmorphism ve mor acente rengi öneriyordu. Uygulama ise Nunito, 10 px kart ve kâğıt estetiği kullanıyor. Bu bölümde görsel değer yok.
2. **Doğrulanmamış ya da yanlış iddialar çıkarıldı.** “Ömür boyu referans komisyonu” ve “pasif gelir” (referral modeli ücretsiz, ve müşteriye dönük metinde “referans” kelimesi kullanılmıyor), “değiştirilemez zaman damgası”, “sıfır bürokrasi” (ispatlanamayan taahhütler). Detay bölüm 3.
3. **Konumlandırma daraltıldı.** Stanomer kiralama sürecinin tamamını değil **kira sonrası süreci** yönetir. v2’nin “Mülk Yönetiminde Yeni Nesil Şeffaflık” sloganı bunu söylemiyordu ve her rakipte durabilecek kadar genel.
4. **Müşteri adı çıkarıldı.** “Axia Exclusive gold rozet” kaldırıldı: marka rehberi dışarı paylaşılabilir ve NDA kapsamındaki bir müşteriyi içermemeli.
5. **Rol renkleri kaldırıldı.** Kiracı = yeşil, “ödendi” = yeşil çakışması yaratıyordu. Roller ikon ve etiketle ayrılır.
6. **Logo bölümü tamamlandı.** Minimum boyut, koyu zemin, yanlış kullanım ve eksik varlık listesi eklendi.
7. **İsim hikâyesi sorgulandı.** Bölüm 1.

---

## <a id="bg-1-marka-hikayesi-ve-isim"></a>1. Marka hikâyesi ve isim

**Stan** Sırpçada daire, konut. **-mer** ekiyle biten kelimeler (vodomer, toplomer) Sırpçada ölçü aletini anlatır. Bu iyi bir yön: isim “yaşam alanının net kaydı” gibi okunabilir.

İki risk, Sırpça bilen biriyle doğrulanmalı:
- “Stanomer” ilk bakışta “daire sayacı” gibi, yani bir tüketim ölçüm cihazı gibi okunabilir.
- v2’deki “MER = şeffaflık, standart” açıklaması etimolojik olarak gerçeğe değil, güzel bir hikâyeye dayanıyor. Dışarıya “isim şu anlama gelir” diye anlatılmadan önce kontrol edilmeli.

Bu yüzden isim hikâyesi iddia değil **çerçeve** olarak kullanılır: “Kira sonrası her şeyi ölçülü ve net tutan yer.” Logo ile uyumlu: el sıkışma (anlaşma), çatı (ev), daire (bütün kayıt tek yerde).

## <a id="bg-2-konumlandirma"></a>2. Konumlandırma

**Ne yapar:** Kira sözleşmesi imzalandıktan sonra ev sahibi, kiracı ve acente arasındaki süreci yönetir: kira ödemeleri, faturalar, onaylar, notlar, belgeler.  
**Ne yapmaz:** Kiracı ya da ev sahibi bulmaz, ilan yayınlamaz. Bu kapsam dışıdır ve metinlerde ima edilmemelidir.

**Birincil kitle:** İlk aşamada emlak acenteleri (beyaz etiket paneli ya da tavsiye modeli). Ev sahibi ve kiracı, acentenin davetiyle gelen ikincil kitledir.

**Acente için ana fayda (tercih edilen çerçeve):** Kira sonrası uzlaşma ve ödemelerdeki anlaşmazlık ya da verimsizlik müşteri memnuniyetsizliği yaratır ve acentenin itibarını etkiler. Stanomer bunu iki tarafa da şeffaf tutar. (Acentenin kendi idari zamanı üzerinden anlatılmaz.)

### Slogan önerileri

| Dil | Slogan | Türkçe karşılığı |
| --- | --- | --- |
| SR (Latin) | Posle potpisa ugovora, sve na jednom mestu. | Sözleşme imzalandıktan sonra her şey tek yerde. |
| SR (Ćirilica) | После потписа уговора, све на једном месту. | (aynısı, Kiril yazımıyla) |
| SR alt satır | Zakupnina i računi, jasni za obe strane. | Kira ve faturalar, iki taraf için net. |
| TR | Kira sonrası süreç, tek yerde ve net. |  |
| EN | After the lease is signed, everything in one place. |  |
| RU | После подписания договора всё в одном месте. |  |

Gerekçe: acente e-postalarındaki “Ugovor je potpisan. Kako izgleda proces nakon izdavanja?” (Sözleşme imzalandı. İlan sonrası süreç nasıl işliyor?) sorusuyla aynı dili konuşur ve kapsamı doğru çizer.

## <a id="bg-3-iddia-denetimi"></a>3. İddia denetimi

v2’deki ifadelerin durumu. “Doğrula” olanlar teyit edilmeden kullanılmamalı.

| v2 ifadesi | Durum | Not |
| --- | --- | --- |
| Ömür boyu referans komisyonu | **Çıkar** | Referral modeli ücretsiz. “Referans” kelimesi müşteri metninde kullanılmıyor, “tavsiye / preporuka” kullan. |
| Pasif gelir (acente) | **Çıkar** | Yukarıdaki ile aynı. |
| Değiştirilemez zaman damgası | **Doğrula** | Teknik olarak uygulanmadıysa söyleme. DPA ve sözleşme ile hukuki taahhüt hâline gelebilir. |
| Sıfır bürokrasi | **Çıkar** | Kanıtlanamaz abartı. |
| 5 dilde çift taraflı çeviri | **Doğrula** | Rehber ve blog 5 dilde. Uygulama arayüzü ve mesaj çevirisi için ayrıca teyit et. |
| QR ile anında eşleşme | **Güncelle** | Onboarding doğrudan kurulum bağlantısını önceliyor, QR tek yol değil. |
| 3 tıkta kira bildirimi | **Doğrula** | Ölçüp yaz ya da çıkar. |
| Gizli ücret yok | Tut | Fiyat sayfasıyla uyumlu olduğu sürece. |
| Beyaz etiket, acente paneli | Tut | Doğru ve canlı. |
| Web, iOS ve Android | Tut | Canlı. |

## <a id="bg-4-kisilik-ve-degerler"></a>4. Kişilik ve değerler

Üç ilke, her ekran ve metin bunlarla test edilir:
1. **Tarafsız hakem:** Ev sahibi ile kiracı arasında taraf tutmaz, rakamlar ve onay adımları konuşur. Kiracı ne görüyorsa ev sahibi de görür.
2. **Sakin netlik:** Para ekranlarında süs yok. Tutar, tarih, durum ilk bakışta okunur.
3. **Yerel doğruluk:** Sırbistan formatları (DD.MM.YYYY, 15.000 RSD), Sırpça birinci dil, Latin ve Kiril.

## <a id="bg-5-roller"></a>5. Roller

Tek hesapta üç rol: ev sahibi, kiracı, acente. Roller **ikon ve etiketle** ayrılır, renkle değil. Acente rolü diğer iki kullanıcının izinlerini geçersiz kılabilir. Acente beyaz etiket kullanıyorsa kendi logosuyla görünür.

## <a id="bg-6-logo"></a>6. Logo

Varlıklar: ikon (el sıkışma, ev çatısı, daire) ve yatay logo (ikon ve “Stanomer”).

| Kural | Değer |
| --- | --- |
| Koruma alanı | İkon yüksekliğinin yarısı, her yönde |
| Minimum boyut | Yatay logo 24 px yükseklik, ikon 20 px |
| Zemin | Beyaz ya da çok açık zemin. Koyu zeminde **beyaz kapsül** içinde (wordmark koyu renkli) |
| Uygulama ikonu | Beyaz zemin, ikon kenarlardan %12 boşlukla |
| Yapma | Renk değiştirme, ikonu çevirme, gölge ya da gradyan, daireyi kırpma, acente logosuyla aynı boyda yan yana koyma |

**Henüz olmayan ve çizilmesi gereken varlıklar:** beyaz wordmark (koyu zemin), tek renkli (siyah ve beyaz) sürüm, favicon seti (16, 32, 180, 512), Android adaptive icon katmanları, e-posta imzası için küçük yatay sürüm.

Marka renkleri logodan ölçülmüştür: mavi #1B5888, yeşil #40945D. Kullanım detayı Bölüm 2’de.

## <a id="bg-7-iletisim-dili"></a>7. İletişim dili

İlke: kullanıcıya sadece sorunu değil, atacağı bir sonraki adımı söyle. Resmi hitap (Vi). Hata özür dilemez, ne olduğunu ve nasıl düzeltileceğini söyler. Aynı eylem akış boyunca aynı adı taşır.

| Durum | Tercih edilen | Kaçınılan |
| --- | --- | --- |
| Ödeme kaydı | “Novembar: uplata je zabeležena i prosleđena zakupodavcu.” (Kasım: ödeme kaydedildi ve ev sahibine iletildi.) | “Dug je plaćen.” (Borç ödendi, soğuk ve borç odaklı) |
| Fatura onayı | “Račun čeka odobrenje agencije.” (Fatura acentenin onayını bekliyor.) | “Greška: nedostaje odobrenje.” (Hata: onay eksik, yönlendirmiyor) |
| E-posta eşleşmesi | “Imejl se ne poklapa. Unesite adresu koju je upisala agencija.” (E-posta eşleşmiyor. Acentenin kaydettiği adresi girin.) | “Nevažeći unos.” (Geçersiz giriş) |
| Acente bildirimi | “Za 3 ugovora ostalo je manje od 60 dana. Pripremite produženje.” (3 sözleşmenin bitimine 60 günden az kaldı. Yenileme hazırlayın.) | “Ugovori su istekli.” (Sözleşmeler doldu) |

## <a id="bg-8-ortak-marka-beyaz-etiket"></a>8. Ortak marka (beyaz etiket)

- Üst bar: acente logosu, en fazla 36 px yükseklik.
- Alt rozet: “Powered by Stanomer” (Sırpça seçenek: “Pokreće Stanomer”).
- Acente rengi yalnızca birincil buton ve üst bar. Durum renkleri sabit.
- Acente rengi okunabilirlik eşiğini geçmezse otomatik koyulaştırılır.

## <a id="bg-9-musteriye-donuk-metin-kurallari"></a>9. Müşteriye dönük metin kuralları

- “Referans” kelimesi yok: “preporuka” (tavsiye).
- Tarafsızlık: ev sahibi lehine ya da kiracı lehine dil yok.
- Kapsam dışı vaat yok: kiracı bulma, ilan, eşleştirme.
- Rakamsal ve hukuki iddia yok, teyit edilmedikçe.
- Müşteri ve ortak adları (Axia, Cityspace ve diğerleri) marka rehberinde ve herkese açık materyalde izinsiz geçmez.

## <a id="bg-10-acik-kalan-kararlar"></a>10. Açık kalan kararlar

1. İsmin Sırpça okunuşu ve “ölçü aleti” çağrışımı için kısa bir anadil kontrolü.
2. Slogan seçimi (bölüm 2).
3. Eksik logo varlıklarının çizimi.
4. Bölüm 3’teki “doğrula” iddiaları.

---

# <a id="ds"></a>Bölüm 2: Design System

*Versiyon 4.0 | Kasım 2026 | v3 üzerine kritik revizyon*

## <a id="ds-changelog-v3-v4"></a>Changelog (v3 → v4)

1. **Renkler logodan gerçekten ölçüldü.** v3, “logo pikselleri incelendi, gerçek mavi #1a5eb8” diyordu. İkon dosyasından piksel örneklemesi şunu verdi: mavi **#1B5888**, yeşil **#40945D**. Yani v3 “düzeltmesi” logodan uzaklaştı: v1’deki #1e4d8c, v3’teki #1a5eb8’den logoya daha yakındı. Yeşil #2db87a ise logodakinden belirgin şekilde daha parlak ve naneli.
2. **Kontrast hataları giderildi.** v3’teki #2db87a beyaz üstünde 2.55:1 veriyor (metin için en az 4.5:1 gerekir). Pill metinleri de (#1d8a5a, #b06c10, #c8503a) küçük boyutta sınırın altında kalıyordu. Her renk için “grafik” ve “metin” varyantı ayrıldı.
3. **Okunabilirlik.** Yaşlı kullanıcı hedefi ile 10 ve 11 px yazı çelişiyordu. Minimum 12 px, gövde 16 px. Pill’ler büyük harften cümle düzenine geçti.
4. **Kiril ve çok dilli destek.** DM Serif Display ve DM Mono Kiril karakterleri içermiyor (Latin ve Latin Extended). Kiril arayüzde serif kullanılmaz, mono yalnızca rakam ve Latin para kodunda kalır.
5. **Font yükleme.** Runtime Google Fonts yerine fontlar uygulamaya gömülür (GDPR, çevrimdışı çalışma, tutarlı render).
6. **Kod hataları.** Kart gölgesi alfa değeri spec ile uyuşmuyordu, badge yorumundaki `toUpperCase()` TextStyle içinde çalışmaz, ikon önerisi doğrulanmamış bir pakete bağlıydı.
7. **Eksikler eklendi.** Koyu mod, odak ve devre dışı durumlar, yazı ölçeği kuralı, grafik renk körlüğü kuralı, beyaz etiket kontrast kuralı.
8. **İki dosya arasındaki çelişkiler kapatıldı.** Brand Guide v2 Inter/Outfit, 16 px kart ve glassmorphism öneriyordu. Tek kaynak bu belgedir.

---

## <a id="ds-1-atmosfer"></a>1. Atmosfer

Sıcak kağıt zemin (#F8F7F5), logodan gelen iki marka rengi ve tek bir uyarı rengi. Arayüz iyi düzenlenmiş bir kira defteri gibi hissettirmeli: sakin, net, süssüz. Veri her ekranın kahramanıdır: tutar, tarih, durum.

Renk rolleri sabittir ve karışmaz:
- **Mavi** = eylem ve marka (butonlar, bağlantılar, aktif sekme)
- **Yeşil** = tamamlandı (ödendi, onaylandı)
- **Kehribar** = bekliyor
- **Kiremit** = dikkat gerekiyor (gecikme, hata, silme)

Rol kimliği (ev sahibi, kiracı, acente) renkle değil ikon ve etiketle gösterilir. Yeşil “kiracı rengi” olursa “ödendi” anlamı bulanır.

## <a id="ds-2-renk-acik-tema"></a>2. Renk (Açık tema)

### Marka (logodan ölçüldü)

| Token | Hex | Kullanım | Kontrast |
| --- | --- | --- | --- |
| `brand` | #1B5888 | Birincil buton, bağlantı, aktif durum | beyaz üstünde 7.5:1 |
| `brandPressed` | #12406A | Pressed | beyaz ile 10.7:1 |
| `brandSurface` | #E5EEF6 | Seçili satır, bilgi zemini | brand metin ile 6.4:1 |
| `logoGreen` | #40945D | Yalnızca ikon, grafik, büyük dolgu | beyaz üstünde 3.7:1 (metin için yetersiz) |

### Durum ve semantik

| Token | Hex | Kullanım | Kontrast |
| --- | --- | --- | --- |
| `successText` | #2A6E43 | Ödendi metni, onay ikonu yanında metin | successSurface üstünde 5.4:1 |
| `successSurface` | #E6F3EA | Ödendi pill zemini |  |
| `alert` | #B5432E | Yıkıcı buton zemini, gecikme çizgisi | beyaz ile 5.5:1 |
| `alertText` | #A33C29 | Gecikti metni | alertSurface üstünde 5.6:1 |
| `alertSurface` | #FBEAE6 | Gecikmiş satır ve pill zemini |  |
| `pendingText` | #8A5206 | Onay bekliyor metni | pendingSurface üstünde 5.7:1 |
| `pendingSurface` | #FBF1DC | Bekleyen pill zemini |  |
| `pendingGraphic` | #E0A63A | Yalnızca grafik dolgusu |  |

### Nötr

| Token | Hex | Kontrast (zemin #F8F7F5) |
| --- | --- | --- |
| `bgPage` | #F8F7F5 |  |
| `bgCard` | #FFFFFF |  |
| `textPrimary` | #1A1A1A | yüksek |
| `textSecondary` | #4A4A4A | 8.3:1 |
| `textTertiary` | #666666 | 5.4:1 |
| `borderDefault` | #E5E3DF | ayırıcı, dekoratif |
| `borderInput` | #8A8A8A | 3.4:1 |
| `focusRing` | brand %35 opaklık, 3 px |  |

### Koyu tema

| Token | Hex | Not |
| --- | --- | --- |
| `bgPage` | #0D1828 |  |
| `bgCard` | #142238 |  |
| `brand` | #6FA6DA | kart üstünde 6.2:1 |
| `successText` | #5DBB7E | kart üstünde 6.8:1 |
| `alertText` | #E5806C | kart üstünde 5.8:1 |
| `pendingText` | #E3B04F | kart üstünde 8.0:1 |
| `textPrimary` | #E8EEF5 | 13.7:1 |
| `textSecondary` | #9DAEC2 | 7.0:1 |
| `borderDefault` | #25374F |  |

Logo koyu zeminde beyaz kapsül içinde durur (wordmark koyu renkli).

## <a id="ds-3-tipografi"></a>3. Tipografi

| Rol | Font | Not |
| --- | --- | --- |
| UI | Nunito (300 ile 900) | Latin, Latin Ext ve Kiril destekler. Tek sans-serif. |
| Para | DM Mono | Yalnızca rakam, nokta, virgül ve Latin para kodu (RSD, EUR). Kiril metin için kullanılmaz. |
| Display | DM Serif Display | Yalnızca web başlıkları ve Latin diller. Kiril arayüzde (СРБ, RU) Nunito 800 kullanılır. Uygulamada onboarding dışında kullanma. |

| Rol | Font | Boyut | Weight | Satır | Not |
| --- | --- | --- | --- | --- | --- |
| Display | DM Serif Display | 32 | 400 | 1.25 | yalnızca web |
| Ekran başlığı | Nunito | 24 | 800 | 1.33 |  |
| Bölüm başlığı | Nunito | 20 | 700 | 1.40 |  |
| Alt başlık | Nunito | 17 | 700 | 1.41 |  |
| **Gövde** | Nunito | **16** | 400 | 1.5 |  |
| Gövde vurgulu | Nunito | 16 | 600 | 1.5 |  |
| Tutar büyük | DM Mono | 28 | 600 | 1.14 |  |
| Tutar | DM Mono | 17 | 500 | 1.41 |  |
| Tutar küçük | DM Mono | 14 | 500 | 1.43 |  |
| Etiket | Nunito | 14 | 600 | 1.4 |  |
| Açıklama | Nunito | 13 | 400 | 1.35 |  |
| Pill | Nunito | 12 | 700 | 1.2 | **cümle düzeni**, tracking 0.2 |

Kurallar:
- **Minimum 12 px.** 10 ve 11 px kaldırıldı.
- Tutar, tarih ve kiracı adı en az 600 weight (tutarlar DM Mono 500).
- Büyük harf yalnızca isteğe bağlı kısa etiketlerde. Durum pill’leri cümle düzeni: “Plaćeno”, “Kasni”.
- Sistem yazı ölçeği 1.3’e kadar desteklenir.
- Sırpça metin İngilizceden %20 ile 30 daha uzun.

## <a id="ds-4-bilesenler"></a>4. Bileşenler

**Buton (birincil):** brand zemin (#1B5888), beyaz metin, Nunito 700 16 px, yükseklik en az 48, radius 10. Pressed `brandPressed` (#12406A). Devre dışı: %38 opaklık.  
**Buton (yıkıcı):** `alert` zemin (#B5432E). Yalnızca geri alınamaz eylemler.  
**İkincil:** 1.5 px brand kenarlık, brand metin.  
**Metin butonu:** zemin yok, brand metin 600, dokunma alanı en az 48 px.  
**FAB:** brand zemin, radius 16 (squircle), 24 px beyaz ikon.

**Durum pill’i** (radius 6, padding 4 x 10, 12 px 700, cümle düzeni):

| Durum | SR | TR | Zemin | Metin |
| --- | --- | --- | --- | --- |
| Ödendi | Plaćeno | Ödendi | successSurface (#E6F3EA) | successText (#2A6E43) |
| Bekliyor | Čeka odobrenje | Onay bekliyor | pendingSurface (#FBF1DC) | pendingText (#8A5206) |
| Gecikti | Kasni | Gecikti | alertSurface (#FBEAE6) | alertText (#A33C29) |
| Kısmi | Delimično | Kısmi ödendi | brandSurface (#E5EEF6) | brand (#1B5888) |

Pill’ler dokunulabilir görünmez: chevron, pressed durumu ve gölge yok.

**Ödeme satırı:** beyaz, yatay 16 dikey 14 padding, alt ayırıcı 1 px. Sol: ay etiketi (14/600 secondary) ve kiracı adı (17/700). Sağ: tutar (DM Mono 17/500) ve pill. Gecikmiş: sol 3 px `alert` çizgi ve `alertSurface` zemin.

**Kart:** beyaz, radius 10, kart gölgesi (`0 1px 0 rgba(0,0,0,.04), 0 2px 8px rgba(0,0,0,.06)`), padding 16.  
**Bottom sheet:** radius 16 üstte.  
**Input:** beyaz, 1.5 px `borderInput` (#8A8A8A), radius 8, yükseklik 52, etiket üstte. Odak: brand kenarlık ve focusRing.  
**AppBar:** beyaz, 56, alt çizgi.  
**Tab bar:** aktif brand ve dolu ikon, pasif textTertiary ve çizgi ikon.

## <a id="ds-5-yerlesim-radius-golge"></a>5. Yerleşim, radius, gölge

- Boşluk: 4, 8, 12, 16, 24, 32, 48. Kenar marjı 16 (mobil), 24 (tablet ve web).
- Radius: 4 etiket, 6 pill, 8 input, 10 kart ve buton, 16 sheet ve FAB, 9999 avatar ve toggle.
- Dokunma hedefi en az 48 x 48.
- Gölge: kart `0 1px 0 rgba(0,0,0,.04)` ve `0 2px 8px rgba(0,0,0,.06)`. Sheet `0 4px 16px rgba(0,0,0,.08)`. Modal `0 16px 40px rgba(0,0,0,.18)`.

## <a id="ds-6-ikonlar"></a>6. İkonlar

Flutter'da `Icons.*_rounded`, web'de Lucide SVG ikonlar. Boyut 24 (liste 20, FAB 24). Renk: varsayılan textPrimary, aktif brand. Tek başına ikon yok, yanında metin veya etiket olur.

## <a id="ds-7-grafik"></a>7. Grafik

- Seri renkleri durum sistemiyle aynı: ödendi `logoGreen` (#40945D), bekleyen `pendingGraphic` (#E0A63A), gecikmiş `alert` (#B5432E), beklenen `brandSurface` dolgu ve brand kenarlık.
- Çubuklar üstünde değer etiketi (DM Mono 13/500). Kılavuz #E5E3DF. Gradient yok.

## <a id="ds-8-yerelleştirme"></a>8. Yerelleştirme

- Biçim pazara göre: `15.000 RSD`, `150,00 EUR`, `DD.MM.YYYY`.
- Ay kısaltmaları Sırpça (Avg, Sep, Okt).
- Resmi hitap (Vi, Vaš).
- Kiril modunda display serif ve mono metin devreye girmez.

## <a id="ds-9-beyaz-etiket-kurallari"></a>9. Beyaz etiket kuralları

- Acente logosu üst barda (en fazla 36 px yükseklik), altta küçük “Powered by Stanomer”.
- Acente birincil rengi yalnızca birincil buton ve üst bar zeminine uygulanır.
- **Durum renkleri sabit.**

## <a id="ds-10-yapma-listesi"></a>10. Yapma listesi

- Metin için `logoGreen` kullanma (3.7:1).
- Mavi ile durum anlatma ya da yeşil ile eylem çağırma.
- 12 px altı yazı, ince weight’te tutar, ellipsis ile kesilmiş tutar.
- Kiril ekranda DM Serif Display ya da DM Mono’da Kiril metin.
- Runtime Google Fonts çağrısı.
- Acente renginin durum renklerini ezmesi.

## <a id="ds-11-flutter-token-lari"></a>11. Flutter token’ları

```dart
// colors.dart
abstract class SColors {
  // Marka (logodan ölçüldü: #1B5888, #40945D)
  static const brand        = Color(0xFF1B5888);
  static const brandPressed = Color(0xFF12406A);
  static const brandSurface = Color(0xFFE5EEF6);
  static const logoGreen    = Color(0xFF40945D); // yalnızca grafik ve ikon

  // Durum
  static const successText    = Color(0xFF2A6E43);
  static const successSurface = Color(0xFFE6F3EA);
  static const alert          = Color(0xFFB5432E);
  static const alertText      = Color(0xFFA33C29);
  static const alertSurface   = Color(0xFFFBEAE6);
  static const pendingText    = Color(0xFF8A5206);
  static const pendingSurface = Color(0xFFFBF1DC);
  static const pendingGraphic = Color(0xFFE0A63A);

  // Nötr
  static const bgPage        = Color(0xFFF8F7F5);
  static const bgCard        = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A4A4A);
  static const textTertiary  = Color(0xFF666666);
  static const borderDefault = Color(0xFFE5E3DF);
  static const borderInput   = Color(0xFF8A8A8A);
}

abstract class SColorsDark {
  static const bgPage = Color(0xFF0D1828);
  static const bgCard = Color(0xFF142238);
  static const brand = Color(0xFF6FA6DA);
  static const successText = Color(0xFF5DBB7E);
  static const alertText = Color(0xFFE5806C);
  static const pendingText = Color(0xFFE3B04F);
  static const textPrimary = Color(0xFFE8EEF5);
  static const textSecondary = Color(0xFF9DAEC2);
  static const borderDefault = Color(0xFF25374F);
}

abstract class SShadows {
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 0, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

abstract class SType {
  static const sans = 'Nunito';
  static const mono = 'DM Mono';
  static const serif = 'DM Serif Display';

  static const body = TextStyle(
      fontFamily: sans, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const label = TextStyle(
      fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);
  static const pill = TextStyle(
      fontFamily: sans, fontSize: 12, fontWeight: FontWeight.w700,
      height: 1.2, letterSpacing: 0.2);
  static const amount = TextStyle(
      fontFamily: mono, fontSize: 17, fontWeight: FontWeight.w500, height: 1.41);
}
```

## <a id="ds-12-agent-prompt-rehberi"></a>12. Agent prompt rehberi

- Zemin #F8F7F5, kart #FFFFFF, metin #1A1A1A, ikincil #4A4A4A.
- Eylem rengi #1B5888. Yeşil sadece “ödendi”, metin için #2A6E43. Kiremit sadece “dikkat”, metin için #A33C29.
- UI fontu Nunito, para DM Mono, Kiril ekranda serif yok.
- Gövde 16, en küçük yazı 12, hedefler en az 48 px.
- Tarih `DD.MM.YYYY`, tutar `15.000 RSD`, pazara göre biçimlendir.
- Pill: cümle düzeni, 12 px 700, dokunulabilir görünmez.
- Kart radius 10, buton radius 10, input radius 8, sheet radius 16.
- Gecikmiş satır: sol 3 px `alert` çizgi ve düz `alertSurface` zemin.
