"use client";

import { LanguageProvider, useLanguage } from "../../components/LanguageProvider";
import { LegalLayout } from "../../components/LegalLayout";
import { Shield, Smartphone, Building2, Lock, Settings, BarChart3 } from "lucide-react";

const changelogTranslations: Record<string, Record<string, string>> = {
  TR: {
    title: "Sürüm Geçmişi & Değişiklik Günlüğü",
    subtitle: "Platform gelişim süreci, stabilite güncellemeleri ve gizlilik altyapısı",
    latest: "En Yeni",
    stable: "Kararlı",
    initial: "İlk Lansman",
    changelog_badge: "STANOMER CHANGELOG",
    v2_0_4_date: "Kasım 2026",
    v2_0_0_date: "Ağustos 2026",
    v1_3_0_date: "Haziran 2026",
    v1_2_0_date: "Mayıs 2026",
    v1_1_0_date: "Nisan 2026",
    v1_0_0_date: "Mart 2026",
    mockup_header: "Arayüz Göstergesi Önizleme",
    mockup_preview_text: "Yerel Mod: Belge sadece bu cihazda saklanacak ve çevrimdışı kalacaktır.",
    
    // v2.0.4
    v204_i1_title: "Acenteler İçin Toplu Ödeme & Makbuz Yükleme",
    v204_i1_desc: "Acenteler birden fazla ödemeyi tek seferde kaydedebilir; makbuz yükleme penceresi daha anlaşılır hale getirildi.",
    v204_i1_li1: "Toplu ödeme: Sadece acente hesaplarında, bir mülkün birden fazla kira ve fatura kalemi tek işlemde ödendi olarak işaretlenir.",
    v204_i1_li2: "Makbuz yükleme penceresi: Dosya seçimi, önizleme ve onay adımları sadeleştirildi.",
    v204_i1_li3: "Daha hızlı liste: Mülk ekranındaki sözleşme listesi açılışta hemen yüklenir.",

    v204_i2_title: "Sözleşme Daveti & Ev Sahibi Sahiplik Davetleri",
    v204_i2_desc: "Davet bağlantıları artık daha güvenilir çalışıyor, mülk detay ekranı tüm dillerde tam çevrildi.",
    v204_i2_li1: "Tekrarlanabilir kabul: Kiracı sözleşme davetini tekrar açarsa hata almaz; zaten kabul edilmişse işlem başarıyla tamamlanır, başka bir kiracının sözleşmesi ise üzerine yazılmaz.",
    v204_i2_li2: "Ev sahibi daveti: Acente, sahiplik davet e-postasını istediği zaman yeniden gönderebilir veya bağlantıyı kopyalayabilir; paylaşım penceresi kabul sonrası kendiliğinden kapanmaz.",
    v204_i2_li3: "Eksik e-posta koruması: Ev sahibi e-postası boşsa davet kabulü başlatılmaz. Mülk detay ekranındaki metinler TR, EN, SR ve RU dillerinde eksiksiz.",

    v204_i3_title: "Hesap Güvenliği & Web Sitesi",
    v204_i3_desc: "E-posta ile giriş yapan kullanıcılar şifresini uygulama içinden değiştirebiliyor; web sitesi menüsü yenilendi.",
    v204_i3_li1: "Şifre değiştirme: Profil ekranına, e-posta ile giriş yapan kullanıcılar için yeni şifre belirleme penceresi eklendi.",
    v204_i3_li2: "Yeni üst menü: Bireyler ve Acenteler menüleri sadeleştirildi, alt menülere ikon ve Demo Talep Et bağlantısı eklendi.",
    v204_i3_li3: "Emlak acentesi dizini: 'Emlak Acentesi Bul' sayfasına doğrudan üst menüden ulaşılır; acente kartları yeni menü tasarımıyla uyumlu.",

    v204_i4_title: "Sözleşme Yenileme",
    v204_i4_desc: "Biten bir sözleşme yeni dönem için rol bazlı onayla yenilenebilir; yenilenen sözleşme başlangıç tarihine kadar 'yaklaşan sözleşme' olarak bekler.",
    v204_i4_li1: "Rol bazlı onay: Yenileme teklifi ev sahibi, kiracı ve acente rollerine göre ilgili tarafın onayına gider.",
    v204_i4_li2: "Yaklaşan sözleşme: Mülk detayında yürürlükteki sözleşmenin yanında, başlangıç tarihi gelmemiş yenilenmiş sözleşme ayrıca görünür.",
    v204_i4_li3: "Tarih duyarlı kira üretimi: Aylık kira kayıtları yalnızca yürürlükteki sözleşmeden oluşturulur; yenilenen sözleşme başlamadan kira satırı üretmez.",

    v204_i5_title: "Manuel Notlar (Faaliyet Kaydı)",
    v204_i5_desc: "Mülkün faaliyet kaydına elle not eklenebilir ve kayıtlar not tipine göre filtrelenebilir.",
    v204_i5_li1: "Not ekleme ve düzenleme: Notlar faaliyet kaydında diğer kayıtlarla birlikte listelenir; eklenen not sonradan düzenlenebilir veya silinebilir.",
    v204_i5_li2: "Filtre: Faaliyet kaydına, manuel notları ayırt etmek için filtre eklendi.",
    v204_i5_li3: "Erişim kuralı: Manuel notların görüntülenmesi, eklenmesi, düzenlenmesi ve silinmesi mülkün acentesi veya notu yazan kullanıcıyla sınırlandırıldı.",

    // v2.0.0 Item 1
    v200_i1_title: "Emlak Ofisleri İçin Acente Profili & White-Label Altyapısı",
    v200_i1_desc: "Mülk yönetimini profesyonel boyuta taşımak isteyen emlak ofisleri için özel Acente Profili ve White-Label marka özelleştirme mimarisi yayına alındı.",
    v200_i1_li1: "Tam Yetkili Yönetim: Kiracı veya ev sahibinin onay kuyruğunda beklemeden kira, fatura ve kontrat işlemlerini doğrudan acente yetkisiyle yürütme imkanı.",
    v200_i1_li2: "White-Label Branding: Acentenin kendi logosu, kurumsal renkleri ve özel lansman arayüzü ile müşterilerine hizmet sunma altyapısı.",
    v200_i1_li3: "Tek Tıkla Davet & Senkronizasyon: Kiracı ve ev sahiplerini e-posta ile davet etme ve şeffaf rol bazlı erişim yönetimi.",

    // v1.3.0 Item 1
    v130_i1_title: "Bulut Yükleme / Yerel Depolama Seçeneği (Privacy-First)",
    v130_i1_desc: "Kullanıcıların mülk yönetim belgelerini (sözleşmeler, faturalar, fişler) nerede saklayacağını tamamen kendilerinin belirleyebileceği esnek bir güvenlik altyapısı entegre edildi.",
    v130_i1_li1: "Gizlilik Öncelikli Varsayılan Ayar: Kullanıcı güvenliği için depolama tercihi varsayılan olarak kapalı (false) gelir. Kullanıcı aksini seçmedikçe tüm dokümanlar internete sızma riskine karşı tamamen lokalde kalır.",
    v130_i1_li2: "Yerel Depolama Klasörü: Bulut yüklemelerine izin verilmediğinde, dosyalar uygulamanın doküman dizinindeki izole bir alt klasörde (/stored_documents) kopyalanarak fiziksel korumaya alınır.",
    v130_i1_li3: "Güvenli Bulut Protokolü: Ayar isteğe bağlı açıldığında dosyalar, belirlenen bulut sunucusuna (https://cloud-storage.stanomer.com/...) uçtan uca şifreli olarak yedeklenir.",

    // v1.3.0 Item 2
    v130_i2_title: "Profil Ayarları Kontrolü ve Dinamik Bilgi Bandı",
    v130_i2_desc: "Profil sekmesindeki Ayarlar bölümüne yerelleştirilmiş (TR: 'BULUT YÜKLEMELERİ', EN: 'CLOUD UPLOADS') bir Switch anahtarı eklendi. Duruma göre alt başlıklar dinamik olarak değişerek anlık bilgi verir.",
    v130_i2_li1: "Dinamik Bilgi Bandı (property_detail_screen.dart): Doküman ekleme ekranlarının en üstüne renkli durum barları yerleştirildi. Bulut aktifken yeşil arka plan ve shieldCheck ikonu, Yerel Modda ise sarı arka plan ve smartphone ikonu ile belgenin nerede tutulacağı kullanıcıya anlık doğrulanır.",

    // v1.3.0 Item 3
    v130_i3_title: "Yenilenen Mülk Kartı Tasarımı & UX Koruyucuları",
    v130_i3_desc: "Finansal durumların tek bakışta anlaşılması ve işletim sistemi seviyesindeki hareket çakışmalarının önlenmesi için arayüz kökten optimize edildi.",
    v130_i3_li1: "Mülk Kartı Geliştirmeleri: Ödenen kalemleri gösteren dinamik renk değiştiren ilerleme barları, kira/fatura durumları için renk kodlu hap etiketler (Borç: Kırmızı, Onay Bekliyor: Kehribar, Ödendi: Yeşil) ve temiz konumlandırılmış aksiyon butonları eklendi.",
    v130_i3_li2: "Kapanma Korumalı Alt Sayfalar (bottom_sheet_wrapper.dart): Tabletlerde veya OS gesture hareketlerinde yaşanan çift dokunma çakışmalarını önlemek için ResilientBottomSheetWrapper geliştirildi. Alt sayfa açıldıktan sonraki ilk 500ms boyunca dış alan dokunmalarını yoksayarak kazara kapanmaları sıfırlar.",

    // v1.2.0
    v120_desc: "Platform altyapısının optimize edilmesine ve mobil veri tasarrufu önlemlerine odaklanılan stabilite sürümü.",
    v120_li1: "Yerel Veri Tabanı ve Önbellek (Cache) Optimizasyonu: Çevrimdışı (offline) çalışma modu kararlılığı artırıldı. İnternet kesintilerinde veri kaybı yaşanması engellendi.",
    v120_li2: "Görsel ve Dosya Sıkıştırma Motoru: Fatura, fiş veya makbuz yükleme anında arka planda çalışan akıllı sıkıştırma (compression) algoritmaları devreye alındı. Kalite kaybı olmadan dosya boyutları %60 düşürüldü.",
    v120_li3: "API İstek Yönetimi: Sunucu ile olan veri alışverişi minimize edilerek ağ istekleri optimize edildi, böylece mobil veri tüketimi önemli ölçüde azaltıldı.",

    // v1.1.0
    v110_desc: "İlk lansman sonrası kullanıcılardan gelen geri bildirimler doğrultusunda arka plan süreçlerinin iyileştirildiği performans sürümü.",
    v110_li1: "Veri Tabanı İndeksleme Çalışmaları: Dashboard ve mülk listeleme ekranlarındaki veritabanı sorguları optimize edildi. Sayfa açılış hızları ve listeleme performansları %40 artırıldı.",
    v110_li2: "Bellek Yönetimi (Memory Management): Flutter durum yönetimi (state management) katmanındaki bellek sızıntıları (memory leaks) tespit edilerek temizlendi, uygulamanın uzun süreli kullanımlarda cihazı yorması engellendi.",
    v110_li3: "Anlık Bildirim (Push Notification) Sistemi: Fatura ve kira hatırlatıcı bildirimlerinin arka planda gecikmesiz çalışması için senkronizasyon motoru güncellendi.",

    // v1.0.0
    v100_desc: "Stanomer Dijital Mülk ve Rental Yönetim Platformu'nun resmi ilk sürümü yayınlandı.",
    v100_li1: "Mülk ve Kontrat Yönetimi: Ev sahipleri ve kiracılar için mülk tanımlama, kira başlangıç/bitiş takibi ve sözleşme detayları yönetimi mimarisi kuruldu.",
    v100_li2: "Çift Taraflı Onay Mekanizması (Handshake): Bir tarafın girdiğini (fatura, ödeme kaydı, değişiklik) diğer tarafın onaylamasını zorunlu kılan yasal ve güvenli doğrulama altyapısı yayına alındı.",
    v100_li3: "Yerelleştirilmiş Altyapı: Sırbistan pazarı öncelikli olmak üzere yerel para birimi (RSD) desteği ve çok dilli (TR, EN, SR) lokalizasyon sistemi başarıyla entegre edildi."
  },
  EN: {
    title: "Version History & Changelog",
    subtitle: "Platform development updates, stability improvements, and privacy infrastructure",
    latest: "Latest",
    stable: "Stable",
    initial: "Initial Launch",
    changelog_badge: "STANOMER CHANGELOG",
    v2_0_4_date: "November 2026",
    v2_0_0_date: "August 2026",
    v1_3_0_date: "June 2026",
    v1_2_0_date: "May 2026",
    v1_1_0_date: "April 2026",
    v1_0_0_date: "March 2026",
    mockup_header: "UI Indicator Preview",
    mockup_preview_text: "Local Mode: Document will be stored on this device only and will remain offline.",
    
    // v2.0.4
    v204_i1_title: "Bulk Payments for Agencies & Receipt Upload",
    v204_i1_desc: "Agencies can record several payments at once, and the receipt upload dialog is now clearer.",
    v204_i1_li1: "Bulk payments: Available to agency accounts only, mark several rent and bill items of a property as paid in one step.",
    v204_i1_li2: "Receipt upload dialog: File selection, preview and confirmation steps were simplified.",
    v204_i1_li3: "Faster lists: The contract list on the property screen loads immediately.",

    v204_i2_title: "Contract Invites & Landlord Ownership Invites",
    v204_i2_desc: "Invite links are more reliable, and the property detail screen is fully translated in all languages.",
    v204_i2_li1: "Repeatable acceptance: If a tenant opens a contract invite again it no longer fails; an already accepted contract completes normally, and another tenant's contract is never overwritten.",
    v204_i2_li2: "Landlord invite: Agencies can resend the ownership invite email or copy the link at any time, and the share sheet no longer closes by itself after acceptance.",
    v204_i2_li3: "Missing email guard: Acceptance is blocked when the landlord email is empty. All texts on the property detail screen are complete in TR, EN, SR and RU.",

    v204_i3_title: "Account Security & Website",
    v204_i3_desc: "Email users can change their password inside the app, and the website navigation was redesigned.",
    v204_i3_li1: "Password change: A new password sheet in the Profile screen for users who sign in with email.",
    v204_i3_li2: "New header menu: Individuals and Agencies menus were simplified, with icons in the submenus and a Request Demo link.",
    v204_i3_li3: "Agency directory: The Find Real Estate Agency page is one click from the header, and its agency cards match the new menu design.",

    v204_i4_title: "Contract Renewal",
    v204_i4_desc: "An expiring contract can be renewed for a new term with role-based approval; the renewed contract waits as an upcoming contract until its start date.",
    v204_i4_li1: "Role-based approval: The renewal proposal goes to the right party for approval depending on landlord, tenant and agency roles.",
    v204_i4_li2: "Upcoming contract: The property screen shows the renewed contract separately next to the current one until it starts.",
    v204_i4_li3: "Date-aware rent generation: Monthly rent rows are created only from the currently effective contract, so a renewed contract creates no rows before it starts.",

    v204_i5_title: "Manual Notes (Activity Log)",
    v204_i5_desc: "Notes can be added by hand to a property's activity log, and entries can be filtered by type.",
    v204_i5_li1: "Add and edit: Notes appear in the activity log with other entries, and an added note can be edited or deleted later.",
    v204_i5_li2: "Filter: The activity log has a filter to tell manual notes apart.",
    v204_i5_li3: "Access rule: Viewing, adding, editing and deleting manual notes is limited to the property's agency or the user who wrote the note.",

    // v2.0.0 Item 1
    v200_i1_title: "Agency Profile & White-Label Infrastructure for Real Estate Offices",
    v200_i1_desc: "Launched a dedicated Agency Profile and White-Label branding architecture for real estate offices seeking professional property management.",
    v200_i1_li1: "Full Authority Management: Directly execute rent, utility bill, and contract workflows under agency authority without waiting in tenant or landlord approval queues.",
    v200_i1_li2: "White-Label Branding: Serve clients with custom agency logo, corporate brand colors, and tailored presentation interfaces.",
    v200_i1_li3: "One-Click Invite & Sync: Invite tenants and landlords via email with transparent role-based access control.",

    // v1.3.0 Item 1
    v130_i1_title: "Cloud Upload / Local Storage Option (Privacy-First)",
    v130_i1_desc: "A flexible security infrastructure has been integrated, allowing users to determine exactly where to store their property management documents (contracts, invoices, receipts).",
    v130_i1_li1: "Privacy-First Default: For user security, the storage preference defaults to disabled (false). Unless chosen otherwise, all documents remain offline on the device to prevent cloud leak risks.",
    v130_i1_li2: "Local Storage Directory: When cloud uploads are disabled, files are physically protected by copying them to an isolated subdirectory (/stored_documents) in the app's documents folder.",
    v130_i1_li3: "Secure Cloud Protocol: When the setting is optionally enabled, files are backed up end-to-end encrypted to the designated cloud storage (https://cloud-storage.stanomer.com/...).",

    // v1.3.0 Item 2
    v130_i2_title: "Profile Settings Control & Dynamic Info Banner",
    v130_i2_desc: "A localized Switch toggle (TR: 'BULUT YÜKLEMELERİ', EN: 'CLOUD UPLOADS') has been added to the Settings section in the Profile tab. Subtitles change dynamically based on the state to provide instant information.",
    v130_i2_li1: "Dynamic Info Banner (property_detail_screen.dart): Colored status bars have been placed at the top of document upload screens. When cloud is active, a green background and shieldCheck icon are shown; in Local Mode, a yellow background and smartphone icon verify where the document will be stored.",

    // v1.3.0 Item 3
    v130_i3_title: "Redesigned Property Card & UX Safeguards",
    v130_i3_desc: "The user interface has been fully optimized to allow financial statuses to be understood at a glance and to prevent operating system-level gesture conflicts.",
    v130_i3_li1: "Property Card Enhancements: Dynamic color-changing progress bars indicating paid items, color-coded status pills for rent/invoice states (Debt: Red, Awaiting Approval: Amber, Paid: Green), and cleanly positioned action buttons have been added.",
    v130_i3_li2: "Accidental Dismissal Protection (bottom_sheet_wrapper.dart): To prevent double-tap conflicts on tablets or OS gestures, ResilientBottomSheetWrapper has been developed. It ignores clicks outside the bottom sheet during the first 500ms after opening, reducing accidental closures to zero.",

    // v1.2.0
    v120_desc: "A stability release focused on optimizing the platform infrastructure and mobile data saving measures.",
    v120_li1: "Local Database & Cache Optimization: Improved offline mode stability, preventing data loss during network interruptions.",
    v120_li2: "Visual and File Compression Engine: Smart background compression algorithms are now active during invoice and receipt uploads, reducing file sizes by 60% with no loss in quality.",
    v120_li3: "API Request Management: Minimized data exchange with the server, significantly reducing mobile data usage.",

    // v1.1.0
    v110_desc: "A performance release improving background processes based on user feedback received after the initial launch.",
    v110_li1: "Database Indexing: Optimized database queries on the dashboard and property list screens, increasing loading speeds by 40%.",
    v110_li2: "Memory Management: Identified and cleared memory leaks in the Flutter state management layer, preventing device lag during prolonged use.",
    v110_li3: "Push Notification System: Updated synchronization engine for delayed-free background delivery of invoice and rent reminder notifications.",

    // v1.0.0
    v100_desc: "The official first version of the Stanomer Digital Property & Rental Management Platform was published.",
    v100_li1: "Property and Contract Management: Established the core architecture for landlords and tenants to define properties, track lease start/end dates, and manage contract details.",
    v100_li2: "Double-Sided Approval (Handshake): Launched a secure and legally compliant validation system requiring one party's entries (invoice, payment record, changes) to be approved by the other.",
    v100_li3: "Localized Infrastructure: Successfully integrated local currency (RSD) support and a multilingual (TR, EN, SR) localization system, prioritizing the Serbian market."
  },
  SR_LAT: {
    title: "Istorija verzija i beleške o promenama",
    subtitle: "Ažuriranja platforme, poboljšanja stabilnosti i infrastruktura privatnosti",
    latest: "Najnovije",
    stable: "Stabilno",
    initial: "Prvo lansiranje",
    changelog_badge: "STANOMER CHANGELOG",
    v2_0_4_date: "Novembar 2026",
    v2_0_0_date: "Avgust 2026",
    v1_3_0_date: "Jun 2026",
    v1_2_0_date: "Maj 2026",
    v1_1_0_date: "April 2026",
    v1_0_0_date: "Mart 2026",
    mockup_header: "Pregled interfejsa",
    mockup_preview_text: "Lokalni režim: Dokument se čuva samo na uređaju i ostaje van mreže.",

    // v2.0.4
    v204_i1_title: "Grupna plaćanja za agencije i otpremanje potvrda",
    v204_i1_desc: "Agencije mogu da evidentiraju više uplata odjednom, a prozor za otpremanje potvrde je jasniji.",
    v204_i1_li1: "Grupna plaćanja: Dostupno samo agencijskim nalozima, više stavki kirije i računa jedne nekretnine označava se kao plaćeno u jednom koraku.",
    v204_i1_li2: "Prozor za otpremanje potvrde: Koraci biranja fajla, pregleda i potvrde su pojednostavljeni.",
    v204_i1_li3: "Brže liste: Lista ugovora na ekranu nekretnine učitava se odmah.",

    v204_i2_title: "Pozivi za ugovor i pozivi vlasnicima",
    v204_i2_desc: "Linkovi za pozivanje rade pouzdanije, a ekran nekretnine je u potpunosti preveden na sve jezike.",
    v204_i2_li1: "Ponovljivo prihvatanje: Ako zakupac ponovo otvori poziv za ugovor, više ne dolazi do greške; već prihvaćen ugovor se uspešno završava, a ugovor drugog zakupca se nikad ne prepisuje.",
    v204_i2_li2: "Poziv vlasniku: Agencija u svakom trenutku može ponovo da pošalje e-poštu sa pozivom ili da kopira link, a prozor za deljenje se ne zatvara sam posle prihvatanja.",
    v204_i2_li3: "Zaštita od prazne e-pošte: Prihvatanje je blokirano ako je e-pošta vlasnika prazna. Svi tekstovi na ekranu nekretnine su kompletni na TR, EN, SR i RU.",

    v204_i3_title: "Bezbednost naloga i veb sajt",
    v204_i3_desc: "Korisnici koji se prijavljuju e-poštom mogu da promene lozinku u aplikaciji, a meni veb sajta je redizajniran.",
    v204_i3_li1: "Promena lozinke: Na ekranu profila dodat je prozor za novu lozinku za korisnike koji se prijavljuju e-poštom.",
    v204_i3_li2: "Novi gornji meni: Meniji za pojedince i agencije su pojednostavljeni, podmeniji imaju ikone, a dodat je link Zatražite demo.",
    v204_i3_li3: "Imenik agencija: Stranica Pronađi agenciju za nekretnine dostupna je jednim klikom iz zaglavlja, a kartice agencija prate novi dizajn menija.",

    v204_i4_title: "Obnova ugovora",
    v204_i4_desc: "Ugovor koji ističe može se obnoviti za novi period uz odobrenje prema ulozi; obnovljeni ugovor čeka kao nadolazeći ugovor do datuma početka.",
    v204_i4_li1: "Odobrenje prema ulozi: Predlog obnove ide na odobrenje odgovarajućoj strani, zavisno od uloga vlasnika, zakupca i agencije.",
    v204_i4_li2: "Nadolazeći ugovor: Ekran nekretnine prikazuje obnovljeni ugovor odvojeno, pored važećeg, dok ne počne.",
    v204_i4_li3: "Generisanje kirije prema datumu: Mesečne stavke kirije prave se samo iz važećeg ugovora, pa obnovljeni ugovor ne pravi stavke pre početka.",

    v204_i5_title: "Ručne beleške (dnevnik aktivnosti)",
    v204_i5_desc: "U dnevnik aktivnosti nekretnine mogu se ručno dodati beleške, a unosi se mogu filtrirati po tipu.",
    v204_i5_li1: "Dodavanje i izmena: Beleške se prikazuju u dnevniku zajedno sa ostalim unosima, a dodata beleška se kasnije može izmeniti ili obrisati.",
    v204_i5_li2: "Filter: Dnevnik aktivnosti ima filter za izdvajanje ručnih beleški.",
    v204_i5_li3: "Pravilo pristupa: Pregled, dodavanje, izmena i brisanje ručnih beleški ograničeni su na agenciju nekretnine ili korisnika koji je napisao belešku.",

    // v2.0.0 Item 1
    v200_i1_title: "Agencijski Profil i White-Label Infrastruktura za Agencije za Nekretnine",
    v200_i1_desc: "Pokrenut je namenski Agencijski Profil i White-Label arhitektura brendiranja za agencije koje žele profesionalno upravljanje nekretninama.",
    v200_i1_li1: "Potpuno Ovlašćeno Upravljanje: Direktno izvršavanje procesa kirije, računa i ugovora uz agencijska ovlašćenja bez čekanja na odobrenja.",
    v200_i1_li2: "White-Label Brending: Pružanje usluga klijentima sa sopstvenim logotipom agencije, korporativnim bojama i prilagođenim interfejsom.",
    v200_i1_li3: "Poziv i Sinhronizacija Jednim Klikom: Pozovite zakupce i vlasnike putem imejla sa transparentnim upravljanjem ulogama.",

    // v1.3.0 Item 1
    v130_i1_title: "Opcija otpremanja u oblak / Lokalnog skladištenja (Najpre privatnost)",
    v130_i1_desc: "Integrisana je fleksibilna bezbednosna infrastruktura koja omogućava korisnicima da sami odrede gde će čuvati svoje dokumente o upravljanju nekretninama (ugovori, fakture, priznanice).",
    v130_i1_li1: "Podrazumevano podešavanje prioriteta privatnosti: Radi bezbednosti korisnika, opcija otpremanja je podrazumevano isključena (false). Dokumenti ostaju lokalno na uređaju.",
    v130_i1_li2: "Lokalni direktorijum za skladištenje: Kada je otpremanje u oblak onemogućeno, datoteke se kopiraju u izolovani direktorijum (/stored_documents) na uređaju.",
    v130_i1_li3: "Bezbedan protokol oblaka: Kada se opcija uključi, datoteke se bezbedno i šifrovano čuvaju na oblaku (https://cloud-storage.stanomer.com/...).",

    // v1.3.0 Item 2
    v130_i2_title: "Kontrola podešavanja profila i dinamički info baner",
    v130_i2_desc: "Dodat je lokalizovani Switch prekidač u sekciju Podešavanja na profilu. Podnaslovi se dinamički menjaju u zavisnosti od stanja da bi pružili trenutne informacije.",
    v130_i2_li1: "Dinamički info baner (property_detail_screen.dart): Obojene statusne trake su postavljene na vrh ekrana za otpremanje dokumenata. Kada je oblak aktivan prikazuje se zelena pozadina, a u lokalnom režimu žuta pozadina.",

    // v1.3.0 Item 3
    v130_i3_title: "Redizajnirani izgled kartice nekretnine i UX zaštita",
    v130_i3_desc: "Korisnički interfejs je potpuno optimizovan kako bi se finansijski statusi razumeli na prvi pogled i sprečili konflikti sistemskih gestova.",
    v130_i3_li1: "Poboljšanja kartice nekretnine: Dodate su dinamičke trake napretka, statusne oznake u boji za kiriju/fakture (Dug: crveno, Na čekanju: žuto, Plaćeno: zeleno) i jasni tasteri za akcije.",
    v130_i3_li2: "Zaštita od slučajnog zatvaranja (bottom_sheet_wrapper.dart): ResilientBottomSheetWrapper zanemaruje klikove van donjeg ekrana tokom prvih 500 ms kako bi se sprečila slučajna zatvaranja.",

    // v1.2.0
    v120_desc: "Stabilno izdanje fokusirano na optimizaciju infrastrukture platforme i mere uštede mobilnih podataka.",
    v120_li1: "Optimizacija lokalne baze podataka i keša: Poboljšana stabilnost režima rada van mreže, sprečavajući gubitak podataka.",
    v120_li2: "Kompresija datoteka: Pametni algoritmi u pozadini kompresuju fakture i priznanice tokom otpremanja, smanjujući veličinu datoteka za 60% bez gubitka kvaliteta.",
    v120_li3: "Upravljanje API zahtevima: Minimizovana razmena podataka sa serverom, značajno smanjujući potrošnju mobilnog interneta.",

    // v1.1.0
    v110_desc: "Izdanje sa poboljšanjima performansi pozadinskih procesa na osnovu povratnih informacija korisnika nakon lansiranja.",
    v110_li1: "Indeksiranje baze podataka: Optimizovani upiti na kontrolnoj tabli i ekranima liste nekretnina, povećavajući brzinu učitavanja za 40%.",
    v110_li2: "Upravljanje memorijom: Otkrivena i rešena curenja memorije u Flutter sloju upravljanja stanjem, sprečavajući usporavanje uređaja.",
    v110_li3: "Sistem obaveštenja (Push Notifications): Ažuriran mehanizam sinhronizacije za blagovremenu isporuku obaveštenja o kiriji i računima.",

    // v1.0.0
    v100_desc: "Objavljena je zvanična prva verzija Stanomer digitalne platforme za upravljanje nekretninama i zakupom.",
    v100_li1: "Upravljanje nekretninama i ugovorima: Uspostavljena je osnovna arhitektura za definisanje nekretnina, praćenje datuma zakupa i upravljanje ugovorima.",
    v100_li2: "Dvostrano odobrenje (Handshake): Pokrenut je bezbedan sistem verifikacije koji zahteva da unose jedne strane odobri druga strana.",
    v100_li3: "Lokalizovana infrastruktura: Uspešno integrisana podrška za lokalnu valutu (RSD) i višejezični sistem (TR, EN, SR) sa fokusom na tržište Srbije."
  },
  SR_CYR: {
    title: "Историја верзија и белешке о променама",
    subtitle: "Ажурирања платформе, побољшања стабилности и инфраструктура приватности",
    latest: "Најновије",
    stable: "Стабилно",
    initial: "Прво лансирање",
    changelog_badge: "STANOMER CHANGELOG",
    v2_0_4_date: "Новембар 2026",
    v2_0_0_date: "Август 2026",
    v1_3_0_date: "Јун 2026",
    v1_2_0_date: "Мај 2026",
    v1_1_0_date: "Април 2026",
    v1_0_0_date: "Март 2026",
    mockup_header: "Преглед интерфејса",
    mockup_preview_text: "Локални режим: Документ се чува само на уређају и остаје ван мреже.",

    // v2.0.4
    v204_i1_title: "Групна плаћања за агенције и отпремање потврда",
    v204_i1_desc: "Агенције могу да евидентирају више уплата одједном, а прозор за отпремање потврде је јаснији.",
    v204_i1_li1: "Групна плаћања: Доступно само агенцијским налозима, више ставки кирије и рачуна једне некретнине означава се као плаћено у једном кораку.",
    v204_i1_li2: "Прозор за отпремање потврде: Кораци бирања фајла, прегледа и потврде су поједностављени.",
    v204_i1_li3: "Брже листе: Листа уговора на екрану некретнине учитава се одмах.",

    v204_i2_title: "Позиви за уговор и позиви власницима",
    v204_i2_desc: "Линкови за позивање раде поузданије, а екран некретнине је у потпуности преведен на све језике.",
    v204_i2_li1: "Поновљиво прихватање: Ако закупац поново отвори позив за уговор, више не долази до грешке; већ прихваћен уговор се успешно завршава, а уговор другог закупца се никад не преписује.",
    v204_i2_li2: "Позив власнику: Агенција у сваком тренутку може поново да пошаље е-пошту са позивом или да копира линк, а прозор за дељење се не затвара сам после прихватања.",
    v204_i2_li3: "Заштита од празне е-поште: Прихватање је блокирано ако је е-пошта власника празна. Сви текстови на екрану некретнине су комплетни на ТР, ЕН, СР и РУ.",

    v204_i3_title: "Безбедност налога и веб сајт",
    v204_i3_desc: "Корисници који се пријављују е-поштом могу да промене лозинку у апликацији, а мени веб сајта је редизајниран.",
    v204_i3_li1: "Промена лозинке: На екрану профила додат је прозор за нову лозинку за кориснике који се пријављују е-поштом.",
    v204_i3_li2: "Нови горњи мени: Менији за појединце и агенције су поједностављени, подменији имају иконе, а додат је линк Затражите демо.",
    v204_i3_li3: "Именик агенција: Страница Пронађи агенцију за некретнине доступна је једним кликом из заглавља, а картице агенција прате нови дизајн менија.",

    v204_i4_title: "Обнова уговора",
    v204_i4_desc: "Уговор који истиче може се обновити за нови период уз одобрење према улози; обновљени уговор чека као надолазећи уговор до датума почетка.",
    v204_i4_li1: "Одобрење према улози: Предлог обнове иде на одобрење одговарајућој страни, зависно од улога власника, закупца и агенције.",
    v204_i4_li2: "Надолазећи уговор: Екран некретнине приказује обновљени уговор одвојено, поред важећег, док не почне.",
    v204_i4_li3: "Генерисање кирије према датуму: Месечне ставке кирије праве се само из важећег уговора, па обновљени уговор не прави ставке пре почетка.",

    v204_i5_title: "Ручне белешке (дневник активности)",
    v204_i5_desc: "У дневник активности некретнине могу се ручно додати белешке, а уноси се могу филтрирати по типу.",
    v204_i5_li1: "Додавање и измена: Белешке се приказују у дневнику заједно са осталим уносима, а додата белешка се касније може изменити или обрисати.",
    v204_i5_li2: "Филтер: Дневник активности има филтер за издвајање ручних белешки.",
    v204_i5_li3: "Правило приступа: Преглед, додавање, измена и брисање ручних белешки ограничени су на агенцију некретнине или корисника који је написао белешку.",

    // v2.0.0 Item 1
    v200_i1_title: "Агенцијски Профил и White-Label Инфраструктура за Агенције за Некретнине",
    v200_i1_desc: "Покренут је наменски Агенцијски Профил и White-Label архитектура брендирања за агенције које желе професионално управљање некретнинама.",
    v200_i1_li1: "Потпуно Овлашћено Управљање: Директно извршавање процеса кирије, рачуна и уговора уз агенцијска овлашћења без чекања на одобрења.",
    v200_i1_li2: "White-Label Брендинг: Пружање услуга клијентима са сопственим логотипом агенције, корпоративним бојама и прилагођеним интерфејсом.",
    v200_i1_li3: "Позив и Синхронизација Једним Кликом: Позовите закупце и власнике путем имејла са транспарентним управљањем улогама.",

    // v1.3.0 Item 1
    v130_i1_title: "Опција отпремања у облак / Локалног складиштења (Најпре приватност)",
    v130_i1_desc: "Интегрисана је флексибилна безбедносна инфраструктура која омогућава корисницима да сами одреде гле ће чувати своје документе о управљању некретнинама (уговори, фактуре, признанице).",
    v130_i1_li1: "Подразумевано подешавање приоритета приватности: Ради безбедности корисника, опција отпремања је подразумевано искључена (false). Документи остају локално на уређају.",
    v130_i1_li2: "Локални директоријум за складиштење: Када је отпремање у облак онемогућено, датотеке се копирају у изоловани директоријум (/stored_documents) на уређају.",
    v130_i1_li3: "Безбедан протокол облака: Када се опција укључи, датотеке се безбедно и шифровано чувају на облаку (https://cloud-storage.stanomer.com/...).",

    // v1.3.0 Item 2
    v130_i2_title: "Контрола подешавања профила и динамички инфо банер",
    v130_i2_desc: "Додат је локализовани Switch прекидач у секцију Подешавања на профилу. Поднаслови се динамички мењају у зависности од стања да би пружили тренутне информације.",
    v130_i2_li1: "Динамички инфо банер (property_detail_screen.dart): Обојене статусне траке су постављене на врх екрана за опремање докумената. Када је облак активан приказује се зелена позадина, а у локалном режиму жута позадина.",

    // v1.3.0 Item 3
    v130_i3_title: "Редизајнирани изглед картице некретнине и UX заштита",
    v130_i3_desc: "Кориснички интерфејс је потпуно оптимизован како би се финансијски статуси разумели на први поглед и спречили конфликти системских гестова.",
    v130_i3_li1: "Побољшања картице некретнине: Додате су динамичке траке напретка, статусне ознаке у боји за кирију/фактуре (Дуг: црвено, На чекању: жуто, Плаћено: зелено) и јасни тастери за акције.",
    v130_i3_li2: "Заштита од случајног затварања (bottom_sheet_wrapper.dart): ResilientBottomSheetWrapper занемарује кликове ван доњег екрана током првих 500 ms како би се спречила случајна затварања.",

    // v1.2.0
    v120_desc: "Стабилно издање фокусирано на оптимизацију инфраструктуре платформе и мере уштеде мобилних података.",
    v120_li1: "Оптимизација локалне базе података и кеша: Побољшана стабилност режима рада ван мреже, спречавајући губитак података.",
    v120_li2: "Компресија датотека: Паметни алгоритми у позадини компресују фактуре и признанице током отпремања, смањујући величину датотека за 60% без губитка квалитета.",
    v120_li3: "Управљање API захтевима: Минимизована размена података са сервером, значајно смањујући потрошњу мобилног интернета.",

    // v1.1.0
    v110_desc: "Издање са побољшањима перформанси позадинских процеса на основу повратних informacija корисника након лансирања.",
    v110_li1: "Индексирање базе података: Оптимизовани упити на контролној табли и екранима листе некретнина, повећавајући брзину учитававања за 40%.",
    v110_li2: "Управљање меморијом: Откривена и решена цурења меморије у Flutter слоју управљања стањем, спречавајући успоравање уређаја.",
    v110_li3: "Систем обавештења (Push Notifications): Ажуриран механизам синхронизације за благовремену испоруку обавештења о кирији и рачунима.",

    // v1.0.0
    v100_desc: "Објављена је званична прва верзија Stanomer дигиталне платформе за управљање некретнинама и закупом.",
    v100_li1: "Управљање некретнинама и уговорима: Успостављена је основна архитектура за дефинисање некретнина, праћење датума закупа и управљање уговорима.",
    v100_li2: "Двострано одобрење (Handshake): Покренут је безбедан систем верификације који захтева да уносе једне стране одобри друга страна.",
    v100_li3: "Локализована инфраструктура: Успешно интегрисана подршка за локалну валуту (RSD) и вишејезични систем (TR, EN, SR) са фокусом на тржиште Србије."
  },
  RU: {
    title: "История версий & Изменения",
    subtitle: "Обновления платформы, повышение стабильности и инфраструктура конфиденциальности",
    latest: "Новое",
    stable: "Стабильно",
    initial: "Первый запуск",
    changelog_badge: "STANOMER CHANGELOG",
    v2_0_4_date: "Ноябрь 2026",
    v2_0_0_date: "Август 2026",
    v1_3_0_date: "Июнь 2026",
    v1_2_0_date: "Май 2026",
    v1_1_0_date: "Апрель 2026",
    v1_0_0_date: "Март 2026",
    mockup_header: "Предварительный просмотр",
    mockup_preview_text: "Локальный режим: Документ сохраняется только на устройстве и остается офлайн.",

    // v2.0.4
    v204_i1_title: "Массовые платежи для агентств и загрузка квитанций",
    v204_i1_desc: "Агентства могут вносить несколько платежей сразу, а окно загрузки квитанции стало понятнее.",
    v204_i1_li1: "Массовые платежи: Доступно только агентским аккаунтам, несколько позиций аренды и счетов объекта отмечаются оплаченными за один шаг.",
    v204_i1_li2: "Окно загрузки квитанции: Шаги выбора файла, предпросмотра и подтверждения упрощены.",
    v204_i1_li3: "Быстрые списки: Список договоров на экране объекта загружается сразу.",

    v204_i2_title: "Приглашения по договору и приглашения владельцев",
    v204_i2_desc: "Ссылки-приглашения работают надёжнее, а экран объекта полностью переведён на все языки.",
    v204_i2_li1: "Повторное принятие: Если арендатор снова откроет приглашение по договору, ошибки не будет; уже принятый договор завершается нормально, а договор другого арендатора не перезаписывается.",
    v204_i2_li2: "Приглашение владельца: Агентство в любой момент может повторно отправить письмо-приглашение или скопировать ссылку, а окно «Поделиться» больше не закрывается само после принятия.",
    v204_i2_li3: "Защита от пустого email: Принятие блокируется, если email владельца пуст. Все тексты на экране объекта полные на TR, EN, SR и RU.",

    v204_i3_title: "Безопасность аккаунта и сайт",
    v204_i3_desc: "Пользователи, входящие по email, могут менять пароль в приложении, а меню сайта обновлено.",
    v204_i3_li1: "Смена пароля: В профиле добавлено окно нового пароля для пользователей, входящих по email.",
    v204_i3_li2: "Новое верхнее меню: Меню для частных лиц и агентств упрощены, у подменю появились иконки и ссылка «Запросить демо».",
    v204_i3_li3: "Каталог агентств: Страница «Найти агентство недвижимости» доступна в один клик из шапки, карточки агентств соответствуют новому дизайну меню.",

    v204_i4_title: "Продление договора",
    v204_i4_desc: "Истекающий договор можно продлить на новый срок с подтверждением по ролям; продлённый договор ожидает как предстоящий до даты начала.",
    v204_i4_li1: "Подтверждение по ролям: Предложение о продлении отправляется на подтверждение нужной стороне в зависимости от ролей владельца, арендатора и агентства.",
    v204_i4_li2: "Предстоящий договор: Экран объекта показывает продлённый договор отдельно рядом с действующим, пока он не начался.",
    v204_i4_li3: "Начисление аренды по датам: Ежемесячные записи создаются только по действующему договору, поэтому продлённый договор не создаёт записей до начала.",

    v204_i5_title: "Ручные заметки (журнал действий)",
    v204_i5_desc: "В журнал действий объекта можно вручную добавлять заметки, а записи можно фильтровать по типу.",
    v204_i5_li1: "Добавление и правка: Заметки отображаются в журнале вместе с другими записями, добавленную заметку можно позже изменить или удалить.",
    v204_i5_li2: "Фильтр: В журнале действий добавлен фильтр для выделения ручных заметок.",
    v204_i5_li3: "Правило доступа: Просмотр, добавление, изменение и удаление ручных заметок доступны только агентству объекта или автору заметки.",

    // v2.0.0 Item 1
    v200_i1_title: "Агентский Профиль и White-Label Инфраструктура для Агентств Недвижимости",
    v200_i1_desc: "Запущен персональный Агентский Профиль и White-Label архитектура брендинга для агентств недвижимости.",
    v200_i1_li1: "Полные Полномочия: Прямое проведение платежей, счетов и договоров с правами агентства без ожидания в очередях согласования.",
    v200_i1_li2: "White-Label Брендинг: Обслуживание клиентов с собственным логотипом агентства, фирменными цветами и адаптивным интерфейсом.",
    v200_i1_li3: "Приглашения в Один Клик: Быстрое добавление арендаторов и собственников по email с прозрачным контролем доступа.",

    // v1.3.0 Item 1
    v130_i1_title: "Облачная загрузка / Локальное хранение (Приоритет приватности)",
    v130_i1_desc: "Интегрирована гибкая инфраструктура безопасности, позволяющая пользователям точно определять, где хранить свои документы по управлению недвижимостью (договоры, счета, квитанции).",
    v130_i1_li1: "Конфиденциальность по умолчанию: Для безопасности пользователей выбор хранилища по умолчанию отключен (false). Все документы остаются на устройстве.",
    v130_i1_li2: "Локальное хранилище: Когда загрузка в облако отключена, файлы копируются в изолированную подпапку (/stored_documents) на устройстве.",
    v130_i1_li3: "Безопасный облачный протокол: При включении настройки файлы шифруются и загружаются в облако (https://cloud-storage.stanomer.com/...).",

    // v1.3.0 Item 2
    v130_i2_title: "Настройки профиля и динамический инфо-баннер",
    v130_i2_desc: "В настройки профиля добавлен переключатель облачной загрузки. Подзаголовки динамически меняются в зависимости от состояния.",
    v130_i2_li1: "Динамический баннер (property_detail_screen.dart): В верхней части экранов загрузки документов размещены цветные полосы статуса. Зеленый фон для облака, желтый — для локального режима.",

    // v1.3.0 Item 3
    v130_i3_title: "Обновленный дизайн карточки недвижимости и защита UX",
    v130_i3_desc: "Интерфейс оптимизирован для быстрого понимания финансового статуса и предотвращения конфликтов системных жестов.",
    v130_i3_li1: "Улучшения карточки недвижимости: Добавлены динамические индикаторы выполнения, цветные метки статуса (Долг: красный, Ожидание: желтый, Оплачено: зеленый) и четкие кнопки действий.",
    v130_i3_li2: "Защита от случайного закрытия (bottom_sheet_wrapper.dart): ResilientBottomSheetWrapper игнорирует клики вне области экрана в первые 500 мс после открытия.",

    // v1.2.0
    v120_desc: "Стабильный релиз, ориентированный на оптимизацию инфраструктуры платформы и экономию мобильного трафика.",
    v120_li1: "Оптимизация локальной БД и кэша: Повышена стабильность работы в автономном режиме.",
    v120_li2: "Сжатие файлов: Умные алгоритмы сжимают счета и квитанции при загрузке на 60% без потери качества.",
    v120_li3: "Управление API-запросами: Минимизирован обмен данными с сервером, что снижает расход мобильного интернета.",

    // v1.1.0
    v110_desc: "Релиз производительности с улучшениями фоновых процессов на основе отзывов пользователей.",
    v110_li1: "Индексация базы данных: Оптимизированы запросы к БД, скорость загрузки экранов выросла на 40%.",
    v110_li2: "Управление памятью: Исправлены утечки памяти в слое управления состоянием Flutter.",
    v110_li3: "Система push-уведомлений: Обновлен механизм синхронизации для своевременной доставки уведомлений.",

    // v1.0.0
    v100_desc: "Опубликована официальная первая версия цифровой платформы управления арендой Stanomer.",
    v100_li1: "Управление недвижимостью и договорами: Базовая архитектура для отслеживания дат аренды и деталей контракта.",
    v100_li2: "Двустороннее подтверждение (Handshake): Запущена безопасная система проверки, требующая подтверждения записей второй стороной.",
    v100_li3: "Локализация: Интегрирована поддержка динаров (RSD) и многоязычный интерфейс (TR, EN, SR) с фокусом на рынок Сербии."
  }
};

function ChangelogContent() {
  const { lang } = useLanguage();
  
  // Fallback to EN if language is not supported or missing
  const localLang = changelogTranslations[lang] ? lang : "EN";
  const tLocal = (key: string) => changelogTranslations[localLang][key] || key;

  return (
    <div className="text-gray-800 font-sans max-w-none">
      <header className="mb-12 border-b-2 border-gray-100 pb-8 text-left">
        <span className="inline-block bg-brand-blue/10 text-brand-blue px-4 py-1.5 rounded-full text-xs font-bold tracking-wider mb-4">
          {tLocal("changelog_badge")}
        </span>
        <h1 className="text-3xl sm:text-4xl font-semibold text-gray-900 tracking-tight mb-2">
          {tLocal("title")}
        </h1>
        <div className="text-gray-500 text-[15px] sm:text-[17px] font-light leading-relaxed">
          {tLocal("subtitle")}
        </div>
      </header>

      <div className="relative pl-6 sm:pl-8 border-l border-gray-200 ml-1 sm:ml-2">
        {/* SÜRÜM 2.0.4 */}
        <div className="relative mb-16">
          {/* dot */}
          <div className="absolute -left-[34px] sm:-left-[42px] top-1.5 w-5 h-5 rounded-full bg-blue-600 border-4 border-white shadow-[0_0_0_6px_rgba(37,99,235,0.2)]"></div>
          
          <div className="flex flex-wrap items-center gap-3 mb-6">
            <span className="text-2xl font-bold text-gray-900">v2.0.4</span>
            <span className="text-[13px] text-gray-600 bg-gray-100 px-3 py-1 rounded-full font-semibold">
              {tLocal("v2_0_4_date")}
            </span>
            <span className="text-xs font-bold uppercase tracking-wider bg-blue-50 text-blue-700 border border-blue-200 px-3 py-1 rounded-full">
              {tLocal("latest")}
            </span>
          </div>

          <div className="space-y-6">
            {/* Item 1 */}
            <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm transition-all hover:border-gray-300">
              <div className="flex items-center gap-3 mb-3">
                <BarChart3 className="w-5 h-5 text-blue-600 flex-shrink-0" />
                <h3 className="text-[16px] sm:text-[17px] font-bold text-gray-900">
                  {tLocal("v204_i1_title")}
                </h3>
                <span className="font-mono bg-blue-50 text-blue-700 text-[10px] sm:text-[11px] px-2 py-0.5 rounded-md ml-auto hidden sm:inline-block">
                  property_detail_screen.dart
                </span>
              </div>
              <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-4 leading-relaxed">
                {tLocal("v204_i1_desc")}
              </p>
              <ul className="space-y-2 list-none pl-0">
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i1_li1")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i1_li2")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i1_li3")}
                </li>
              </ul>
            </div>
            {/* Item 2 */}
            <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm transition-all hover:border-gray-300">
              <div className="flex items-center gap-3 mb-3">
                <Smartphone className="w-5 h-5 text-blue-600 flex-shrink-0" />
                <h3 className="text-[16px] sm:text-[17px] font-bold text-gray-900">
                  {tLocal("v204_i2_title")}
                </h3>
                <span className="font-mono bg-blue-50 text-blue-700 text-[10px] sm:text-[11px] px-2 py-0.5 rounded-md ml-auto hidden sm:inline-block">
                  ownership_share_sheet.dart
                </span>
              </div>
              <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-4 leading-relaxed">
                {tLocal("v204_i2_desc")}
              </p>
              <ul className="space-y-2 list-none pl-0">
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i2_li1")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i2_li2")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i2_li3")}
                </li>
              </ul>
            </div>
            {/* Item 3 */}
            <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm transition-all hover:border-gray-300">
              <div className="flex items-center gap-3 mb-3">
                <Shield className="w-5 h-5 text-blue-600 flex-shrink-0" />
                <h3 className="text-[16px] sm:text-[17px] font-bold text-gray-900">
                  {tLocal("v204_i3_title")}
                </h3>
                <span className="font-mono bg-blue-50 text-blue-700 text-[10px] sm:text-[11px] px-2 py-0.5 rounded-md ml-auto hidden sm:inline-block">
                  profile_screen.dart
                </span>
              </div>
              <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-4 leading-relaxed">
                {tLocal("v204_i3_desc")}
              </p>
              <ul className="space-y-2 list-none pl-0">
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i3_li1")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i3_li2")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i3_li3")}
                </li>
              </ul>
            </div>
            {/* Item 4 */}
            <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm transition-all hover:border-gray-300">
              <div className="flex items-center gap-3 mb-3">
                <Settings className="w-5 h-5 text-blue-600 flex-shrink-0" />
                <h3 className="text-[16px] sm:text-[17px] font-bold text-gray-900">
                  {tLocal("v204_i4_title")}
                </h3>
                <span className="font-mono bg-blue-50 text-blue-700 text-[10px] sm:text-[11px] px-2 py-0.5 rounded-md ml-auto hidden sm:inline-block">
                  property_detail_screen.dart
                </span>
              </div>
              <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-4 leading-relaxed">
                {tLocal("v204_i4_desc")}
              </p>
              <ul className="space-y-2 list-none pl-0">
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i4_li1")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i4_li2")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i4_li3")}
                </li>
              </ul>
            </div>
            {/* Item 5 */}
            <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm transition-all hover:border-gray-300">
              <div className="flex items-center gap-3 mb-3">
                <Lock className="w-5 h-5 text-blue-600 flex-shrink-0" />
                <h3 className="text-[16px] sm:text-[17px] font-bold text-gray-900">
                  {tLocal("v204_i5_title")}
                </h3>
                <span className="font-mono bg-blue-50 text-blue-700 text-[10px] sm:text-[11px] px-2 py-0.5 rounded-md ml-auto hidden sm:inline-block">
                  activity_logs
                </span>
              </div>
              <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-4 leading-relaxed">
                {tLocal("v204_i5_desc")}
              </p>
              <ul className="space-y-2 list-none pl-0">
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i5_li1")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i5_li2")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v204_i5_li3")}
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* SÜRÜM 2.0 */}
        <div className="relative mb-16">
          {/* dot */}
          <div className="absolute -left-[34px] sm:-left-[42px] top-1.5 w-5 h-5 rounded-full bg-gray-400 border-4 border-white shadow-sm"></div>
          
          <div className="flex flex-wrap items-center gap-3 mb-6">
            <span className="text-2xl font-bold text-gray-900">v2.0.0</span>
            <span className="text-[13px] text-gray-600 bg-gray-100 px-3 py-1 rounded-full font-semibold">
              {tLocal("v2_0_0_date")}
            </span>
            <span className="text-xs font-bold uppercase tracking-wider bg-emerald-50 text-emerald-700 border border-emerald-200 px-3 py-1 rounded-full">
              {tLocal("stable")}
            </span>
          </div>

          <div className="space-y-6">
            {/* Item 1 */}
            <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm transition-all hover:border-gray-300">
              <div className="flex items-center gap-3 mb-3">
                <Building2 className="w-5 h-5 text-blue-600 flex-shrink-0" />
                <h3 className="text-[16px] sm:text-[17px] font-bold text-gray-900">
                  {tLocal("v200_i1_title")}
                </h3>
                <span className="font-mono bg-blue-50 text-blue-700 text-[10px] sm:text-[11px] px-2 py-0.5 rounded-md ml-auto hidden sm:inline-block">
                  agency_profile
                </span>
              </div>
              <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-4 leading-relaxed">
                {tLocal("v200_i1_desc")}
              </p>
              <ul className="space-y-2 list-none pl-0">
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v200_i1_li1")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v200_i1_li2")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-blue-600 before:font-bold">
                  {tLocal("v200_i1_li3")}
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* SÜRÜM 1.3 */}
        <div className="relative mb-16">
          {/* dot */}
          <div className="absolute -left-[34px] sm:-left-[42px] top-1.5 w-5 h-5 rounded-full bg-gray-400 border-4 border-white shadow-sm"></div>
          
          <div className="flex flex-wrap items-center gap-3 mb-6">
            <span className="text-2xl font-bold text-gray-900">v1.3.0</span>
            <span className="text-[13px] text-gray-600 bg-gray-100 px-3 py-1 rounded-full font-semibold">
              {tLocal("v1_3_0_date")}
            </span>
            <span className="text-xs font-bold uppercase tracking-wider bg-emerald-50 text-emerald-700 border border-emerald-200 px-3 py-1 rounded-full">
              {tLocal("stable")}
            </span>
          </div>

          <div className="space-y-6">
            {/* Item 1 */}
            <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm transition-all hover:border-gray-300">
              <div className="flex items-center gap-3 mb-3">
                <Lock className="w-5 h-5 text-slate-700 flex-shrink-0" />
                <h3 className="text-[16px] sm:text-[17px] font-bold text-gray-900">
                  {tLocal("v130_i1_title")}
                </h3>
                <span className="font-mono bg-gray-100 text-[10px] sm:text-[11px] text-gray-500 px-2 py-0.5 rounded-md ml-auto hidden sm:inline-block">
                  document_storage_service.dart
                </span>
              </div>
              <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-4 leading-relaxed">
                {tLocal("v130_i1_desc")}
              </p>
              <ul className="space-y-2 list-none pl-0">
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-brand-blue before:font-bold">
                  {tLocal("v130_i1_li1")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-brand-blue before:font-bold">
                  {tLocal("v130_i1_li2")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-brand-blue before:font-bold">
                  {tLocal("v130_i1_li3")}
                </li>
              </ul>
            </div>

            {/* Item 2 */}
            <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm transition-all hover:border-gray-300">
              <div className="flex items-center gap-3 mb-3">
                <Settings className="w-5 h-5 text-slate-700 flex-shrink-0" />
                <h3 className="text-[16px] sm:text-[17px] font-bold text-gray-900">
                  {tLocal("v130_i2_title")}
                </h3>
                <span className="font-mono bg-gray-100 text-[10px] sm:text-[11px] text-gray-500 px-2 py-0.5 rounded-md ml-auto hidden sm:inline-block">
                  profile_screen.dart
                </span>
              </div>
              <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-4 leading-relaxed">
                {tLocal("v130_i2_desc")}
              </p>
              <ul className="space-y-2 list-none pl-0">
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-brand-blue before:font-bold">
                  {tLocal("v130_i2_li1")}
                </li>
              </ul>

              <div className="bg-gray-50/50 border border-gray-200/60 rounded-xl p-4 mt-5">
                <div className="text-[10px] text-gray-400 font-bold uppercase tracking-wider mb-2">
                  {tLocal("mockup_header")}
                </div>
                <div className="bg-[#fffbeb] border border-[#fde68a] text-[#92400e] text-[12px] font-medium py-2 px-3 rounded-lg flex items-center gap-2">
                  <Smartphone className="w-4 h-4 flex-shrink-0" />
                  <span>{tLocal("mockup_preview_text")}</span>
                </div>
              </div>
            </div>

            {/* Item 3 */}
            <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm transition-all hover:border-gray-300">
              <div className="flex items-center gap-3 mb-3">
                <BarChart3 className="w-5 h-5 text-blue-600 flex-shrink-0" />
                <h3 className="text-[16px] sm:text-[17px] font-bold text-gray-900">
                  {tLocal("v130_i3_title")}
                </h3>
                <span className="font-mono bg-gray-100 text-[10px] sm:text-[11px] text-gray-500 px-2 py-0.5 rounded-md ml-auto hidden sm:inline-block">
                  dashboard_screen.dart
                </span>
              </div>
              <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-4 leading-relaxed">
                {tLocal("v130_i3_desc")}
              </p>
              <ul className="space-y-2 list-none pl-0">
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-brand-blue before:font-bold">
                  {tLocal("v130_i3_li1")}
                </li>
                <li className="relative pl-5 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['•'] before:absolute before:left-1.5 before:text-brand-blue before:font-bold">
                  {tLocal("v130_i3_li2")}
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* SÜRÜM 1.2 */}
        <div className="relative mb-16">
          <div className="absolute -left-[34px] sm:-left-[42px] top-1.5 w-5 h-5 rounded-full bg-white border-4 border-gray-300 shadow-[0_0_0_4px_#ffffff]"></div>
          
          <div className="flex flex-wrap items-center gap-3 mb-6">
            <span className="text-2xl font-bold text-gray-900">v1.2.0</span>
            <span className="text-[13px] text-gray-650 bg-gray-100 px-3 py-1 rounded-full font-semibold">
              {tLocal("v1_2_0_date")}
            </span>
            <span className="text-xs font-bold uppercase tracking-wider bg-gray-100 text-gray-600 px-3 py-1 rounded-full">
              {tLocal("stable")}
            </span>
          </div>

          <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm">
            <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-5 leading-relaxed">
              {tLocal("v120_desc")}
            </p>
            <ul className="bg-gray-50/70 border border-gray-100 rounded-2xl p-6 space-y-4 list-none pl-0">
              <li className="relative pl-7 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['✓'] before:absolute before:left-1 before:text-emerald-500 before:font-bold">
                {tLocal("v120_li1")}
              </li>
              <li className="relative pl-7 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['✓'] before:absolute before:left-1 before:text-emerald-500 before:font-bold">
                {tLocal("v120_li2")}
              </li>
              <li className="relative pl-7 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['✓'] before:absolute before:left-1 before:text-emerald-500 before:font-bold">
                {tLocal("v120_li3")}
              </li>
            </ul>
          </div>
        </div>

        {/* SÜRÜM 1.1 */}
        <div className="relative mb-16">
          <div className="absolute -left-[34px] sm:-left-[42px] top-1.5 w-5 h-5 rounded-full bg-white border-4 border-gray-300 shadow-[0_0_0_4px_#ffffff]"></div>
          
          <div className="flex flex-wrap items-center gap-3 mb-6">
            <span className="text-2xl font-bold text-gray-900">v1.1.0</span>
            <span className="text-[13px] text-gray-650 bg-gray-100 px-3 py-1 rounded-full font-semibold">
              {tLocal("v1_1_0_date")}
            </span>
            <span className="text-xs font-bold uppercase tracking-wider bg-gray-100 text-gray-600 px-3 py-1 rounded-full">
              {tLocal("stable")}
            </span>
          </div>

          <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm">
            <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-5 leading-relaxed">
              {tLocal("v110_desc")}
            </p>
            <ul className="bg-gray-50/70 border border-gray-100 rounded-2xl p-6 space-y-4 list-none pl-0">
              <li className="relative pl-7 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['✓'] before:absolute before:left-1 before:text-emerald-500 before:font-bold">
                {tLocal("v110_li1")}
              </li>
              <li className="relative pl-7 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['✓'] before:absolute before:left-1 before:text-emerald-500 before:font-bold">
                {tLocal("v110_li2")}
              </li>
              <li className="relative pl-7 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['✓'] before:absolute before:left-1 before:text-emerald-500 before:font-bold">
                {tLocal("v110_li3")}
              </li>
            </ul>
          </div>
        </div>

        {/* SÜRÜM 1.0 */}
        <div className="relative">
          <div className="absolute -left-[34px] sm:-left-[42px] top-1.5 w-5 h-5 rounded-full bg-white border-4 border-gray-300 shadow-[0_0_0_4px_#ffffff]"></div>
          
          <div className="flex flex-wrap items-center gap-3 mb-6">
            <span className="text-2xl font-bold text-gray-900">v1.0.0</span>
            <span className="text-[13px] text-gray-650 bg-gray-100 px-3 py-1 rounded-full font-semibold">
              {tLocal("v1_0_0_date")}
            </span>
            <span className="text-xs font-bold uppercase tracking-wider bg-gray-100 text-gray-600 px-3 py-1 rounded-full">
              {tLocal("initial")}
            </span>
          </div>

          <div className="bg-white border border-gray-200 rounded-2xl p-6 sm:p-7 shadow-sm">
            <p className="text-[13.5px] sm:text-[14.5px] text-gray-600 mb-5 leading-relaxed">
              {tLocal("v100_desc")}
            </p>
            <ul className="bg-gray-50/70 border border-gray-100 rounded-2xl p-6 space-y-4 list-none pl-0">
              <li className="relative pl-7 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['✓'] before:absolute before:left-1 before:text-emerald-500 before:font-bold">
                {tLocal("v100_li1")}
              </li>
              <li className="relative pl-7 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['✓'] before:absolute before:left-1 before:text-emerald-500 before:font-bold">
                {tLocal("v100_li2")}
              </li>
              <li className="relative pl-7 text-[13px] sm:text-[14px] text-gray-650 leading-relaxed before:content-['✓'] before:absolute before:left-1 before:text-emerald-500 before:font-bold">
                {tLocal("v100_li3")}
              </li>
            </ul>
          </div>
        </div>

      </div>
    </div>
  );
}

export default function ChangelogPage() {
  return (
    <LegalLayout activeTab="changelog">
      <ChangelogContent />
    </LegalLayout>
  );
}
