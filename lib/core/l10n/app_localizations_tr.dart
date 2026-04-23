// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Stanomer';

  @override
  String get login => 'Giriş Yap';

  @override
  String get signup => 'Kayıt Ol';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get landlord => 'Ev Sahibi';

  @override
  String get tenant => 'Kiracı';

  @override
  String get zzplConsent =>
      'Kişisel verilerimin Sırbistan Kişisel Verilerin Korunması Kanunu (ZZPL) uyarınca işlenmesini kabul ediyorum.';

  @override
  String get selectRole => 'Rolünüzü seçin';

  @override
  String get fieldRequired => 'Bu alan zorunludur';

  @override
  String get consentRequired =>
      'Devam etmek için ZZPL onayını kabul etmelisiniz';

  @override
  String get loginToAccount => 'Hesabınıza giriş yapın';

  @override
  String get createAccount => 'Yeni hesap oluştur';

  @override
  String get dontHaveAccount => 'Hesabınız yok mu? Kayıt olun';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı? Giriş yapın';

  @override
  String get continueWithGoogle => 'Google ile Devam Et';

  @override
  String get continueWithApple => 'Apple ile Devam Et';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get errorSelectRole => 'Lütfen rolünüzü seçin';

  @override
  String get deleteAccount => 'Hesabı Sil';

  @override
  String get deleteAccountWarning =>
      'Bu işlem kalıcıdır ve geri alınamaz. Tüm verileriniz silinecektir.';

  @override
  String get confirmPasswordForDeletion =>
      'Silme işlemini onaylamak için lütfen şifrenizi girin';

  @override
  String get deleteButtonLabel => 'Hesabımı Kalıcı Olarak Sil';

  @override
  String get cancel => 'İptal';

  @override
  String get invalidPassword => 'Geçersiz şifre';

  @override
  String get welcomeToStanomer => 'Stanomer\'e Hoş Geldiniz';

  @override
  String get consentTextFullTitle => 'Kişisel Verilerin İşlenmesi Onayı (ZZPL)';

  @override
  String get profile => 'Profil';

  @override
  String get updateName => 'Adı Güncelle';

  @override
  String get updatePassword => 'Şifreyi Güncelle';

  @override
  String get oldPassword => 'Mevcut Şifre';

  @override
  String get newPassword => 'Yeni Şifre';

  @override
  String get saveChanges => 'Değişiklikleri Kaydet';

  @override
  String get passwordChangedSuccess => 'Şifre başarıyla güncellendi';

  @override
  String get profileUpdatedSuccess => 'Profil başarıyla güncellendi';

  @override
  String get role => 'Rol';

  @override
  String get roleLandlord => 'Ev Sahibi';

  @override
  String get roleTenant => 'Kiracı';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get addProperty => 'Mülk Ekle';

  @override
  String get address => 'Adres';

  @override
  String get monthlyRent => 'Aylık Kira';

  @override
  String get depositAmount => 'Depozito Tutarı';

  @override
  String get currency => 'Para Birimi';

  @override
  String get propertyName => 'Mülk Adı';

  @override
  String get propertyNameHint => 'ör. Belgrad Dairesi';

  @override
  String get propertyAddedSuccess => 'Mülk başarıyla eklendi';

  @override
  String get propertyUpdatedSuccess => 'Mülk başarıyla güncellendi';

  @override
  String get noProperties => 'Mülk bulunamadı';

  @override
  String get addYourFirstProperty =>
      'Takibe başlamak için ilk mülkünüzü ekleyin!';

  @override
  String get editProperty => 'Mülkü Düzenle';

  @override
  String get delete => 'Sil';

  @override
  String get confirmDeleteTitle => 'Mülkü Sil';

  @override
  String get confirmDeleteMessage =>
      'Bu mülkü silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get propertyDeletedSuccess => 'Mülk başarıyla silindi';

  @override
  String get inviteTenant => 'Kiracı Davet Et';

  @override
  String get emailHint => 'Kiracının e-posta adresini girin';

  @override
  String get inviteCreatedSuccess =>
      'Davet bağlantısı oluşturuldu! Artık paylaşabilirsiniz.';

  @override
  String get shareInviteLink => 'Davet Bağlantısını Paylaş';

  @override
  String get copyLink => 'Bağlantıyı Kopyala';

  @override
  String get noInvitesYet => 'Henüz gönderilmiş davet yok';

  @override
  String get cancelInvitation => 'Daveti İptal Et';

  @override
  String get invitationCancelledSuccess => 'Davet başarıyla iptal edildi';

  @override
  String get pendingInvite => 'Bekleyen Davet';

  @override
  String get contractSentToTenant => 'Kiracıya kontrat gönderildi';

  @override
  String get overview => 'Genel Bakış';

  @override
  String get financials => 'Finansallar';

  @override
  String get propertySettings => 'Ayarlar';

  @override
  String get invitationHistory => 'Davet Geçmişi';

  @override
  String get invitationDetails => 'Davet Detayları';

  @override
  String get acceptInvitation => 'Evet, burayı kiraladım';

  @override
  String get declineInvitation => 'Daveti Reddet';

  @override
  String get inviteNotFound => 'Davet bulunamadı veya süresi dolmuş';

  @override
  String get invitationAcceptedSuccess =>
      'Eve hoş geldiniz! Davet kabul edildi.';

  @override
  String pendingInvitationBanner(String property) {
    return '$property için bekleyen bir davetiniz var';
  }

  @override
  String invitedBy(String name) {
    return '$name tarafından davet edildiniz';
  }

  @override
  String get yourName => 'Adınız';

  @override
  String get yourNameHint => 'Adınızı ve soyadınızı girin';

  @override
  String get viewInvite => 'Daveti Görüntüle';

  @override
  String get myProperties => 'Mülklerim';

  @override
  String get tenantEmptyStateTitle => 'Henüz atanmış bir mülk yok';

  @override
  String get tenantEmptyStateMessage =>
      'Ev sahibiniz size bir davet gönderdiyse burada görünecektir. Yeni davetleri kontrol etmek için aşağıdaki düğmeye dokunun.';

  @override
  String get refresh => 'Yenile';

  @override
  String get invitationDeclinedSuccess => 'Davet reddedildi.';

  @override
  String get confirmDeclineInviteTitle => 'Daveti Reddet?';

  @override
  String get confirmDeclineInviteMessage =>
      'Bu daveti reddetmek istediğinizden emin misiniz? Bekleyenler listenizden kaldırılacaktır.';

  @override
  String get contractStartDate => 'Sözleşme Başlangıç Tarihi';

  @override
  String get contractEndDate => 'Sözleşme Bitiş Tarihi';

  @override
  String get uploadContract => 'Sözleşme Yükle';

  @override
  String get viewContract => 'Sözleşmeyi Görüntüle';

  @override
  String get contractFile => 'Sözleşme Dosyası';

  @override
  String get selectDate => 'Tarih Seç';

  @override
  String get appLanguage => 'Uygulama Dili';

  @override
  String get english => 'İngilizce';

  @override
  String get serbianLatin => 'Sırpça (Latin)';

  @override
  String get serbianCyrillic => 'Sırpça (Kiril)';

  @override
  String get turkish => 'Türkçe';

  @override
  String get tenantMode => 'Kiracı Modu';

  @override
  String get landlordMode => 'Ev Sahibi Modu';

  @override
  String get whatAreYou => 'Ne olarak devam etmek istersiniz?';

  @override
  String get selectRoleToContinue =>
      'Başlamak için bir rol seçin. İstediğiniz zaman yukarıdan değiştirebilirsiniz.';

  @override
  String get consentTextFullBody =>
      'Stanomer uygulamasını kullanarak, kişisel verilerinizin Sırbistan Cumhuriyeti Kişisel Verilerin Korunması Kanunu (ZZPL) uyarınca işlenmesi için açık onay veriyorsunuz.';

  @override
  String get removeTenant => 'Kiracıyı Kaldır';

  @override
  String get removeTenantConfirmation =>
      'Bu kiracıyı mülkten kaldırmak istediğinizden emin misiniz? Bu işlem bağlantıyı keser ve davet kaydını siler.';

  @override
  String get remove => 'Kaldır';

  @override
  String logRentDeclared(String month) {
    return 'Kiracı $month kirasını ödedi olarak işaretledi.';
  }

  @override
  String logRentApproved(String month) {
    return 'Ev sahibi $month kirasını onayladı.';
  }

  @override
  String logRentRejected(String month) {
    return 'Ev sahibi $month kirasını reddetti.';
  }

  @override
  String logMarkedAsPaid(String month) {
    return 'Ev sahibi $month kirasını ödendi yaptı.';
  }

  @override
  String logMarkedAsPending(String month) {
    return 'Ev sahibi $month kirasını beklemede yaptı.';
  }

  @override
  String logAutoApproved(String month) {
    return '$month kirası 5 gün geçtiği için sistem tarafından otomatik onaylandı.';
  }

  @override
  String get activity => 'Aktivite';

  @override
  String get noContractsTitle => 'Henüz kontrat yok';

  @override
  String get noContractsMessage =>
      'Kiraladığınız mülkün kira ve masraf takibini yapmak için önce kontrat bilgilerini girerek bir kiracı davet etmelisiniz.';

  @override
  String get inviteFirstTenant => 'İlk Kiracıyı Davet Et';

  @override
  String get confirmCancelInvitationTitle => 'Daveti İptal Et';

  @override
  String get confirmCancelInvitationMessage =>
      'Bu daveti geri çekmek istediğinizden emin misiniz? Bu işlem daveti kalıcı olarak siler.';

  @override
  String get confirmDeclineRevisionTitle => 'Değişiklik Talebini Reddet';

  @override
  String get confirmDeclineRevisionMessage =>
      'Kiracının değişiklik talebini reddetmek istediğinizden emin misiniz? Kontrat orijinal şartlarıyla onay beklemeye devam edecektir.';

  @override
  String get activeContract => 'Aktif Kontrat';

  @override
  String get activeLease => 'AKTİF KONTRAT';

  @override
  String get invitationSent => 'Davet Gönderildi';

  @override
  String get accept => 'Kabul Et';

  @override
  String get decline => 'Reddet';

  @override
  String get declineRevisionRequest => 'Değişiklik talebini reddet';

  @override
  String get pendingHeader => 'BEKLEYEN';

  @override
  String get awaitingHeader => 'ONAY BEKLİYOR';

  @override
  String get paidHeader => 'ÖDENDİ';

  @override
  String get waitingForTenantPayment => 'Kiracı ödemesi bekleniyor';

  @override
  String get waitingForYourApproval => 'Onayınız bekleniyor';

  @override
  String get waitingForOwnerApproval => 'Ev sahibi onayı bekleniyor';

  @override
  String get waitingForYourPayment => 'Ödeme yapmanız bekleniyor';

  @override
  String get processCompleted => 'İşlem tamamlandı';

  @override
  String get declared => 'bildirildi';

  @override
  String get sent => 'gönderildi';

  @override
  String get noInvoice => 'Fatura Yok';

  @override
  String get uploadInvoice => 'Fatura Yükle';

  @override
  String get awaitingInvoice => 'Fatura bekleniyor';

  @override
  String get updateLabel => 'Güncelle';

  @override
  String get statusVacant => 'Boş';

  @override
  String get overdueReceivables => 'Vadesi Geçmiş';

  @override
  String get collectedByType => 'Tahsil Edilenler';

  @override
  String get pendingApproval => 'ONAY BEKLİYOR';

  @override
  String get targetRent => 'HEDEF KİRA';

  @override
  String get contractInfo => 'Kontrat Bilgisi';

  @override
  String get term => 'Süre';

  @override
  String get dueDay => 'Ödeme Günü';

  @override
  String get contractDetails => 'Kontrat Detayları';

  @override
  String get pastContracts => 'Geçmiş kontratlar';

  @override
  String previousLeasesCount(int count) {
    return '$count önceki kontrat';
  }

  @override
  String get propertySettingsLabel => 'Mülk ayarları';

  @override
  String get propertyActions => 'Mülk İşlemleri';

  @override
  String get leavePropertyConfirm => 'Bu mülkten ayrılmak istiyor musunuz?';

  @override
  String get leaveProperty => 'Mülkü Bırak';

  @override
  String get areYouSure => 'Emin misiniz?';

  @override
  String get pendingInvitations => 'Bekleyen Davetler';

  @override
  String get contractSettings => 'Kontrat Ayarları';

  @override
  String get activeContractTermsInfo =>
      'Aktif kontrat şartları. Burada yapılan tüm değişiklikler yalnızca kiracı ve ev sahibi mutabık kaldığında geçerli olur.';

  @override
  String get dueDayOfMonth => 'Ayın Ödeme Günü';

  @override
  String get startDate => 'Başlangıç Tarihi';

  @override
  String get endDate => 'Bitiş Tarihi';

  @override
  String get taxConfiguration => 'Vergi Durumu';

  @override
  String get included => 'Dahil';

  @override
  String get addedVat => 'Eklenir (+%15)';

  @override
  String get expensesHeader => 'GİDERLER';

  @override
  String get extraPayment => 'Ek ödeme';

  @override
  String get utility => 'Kuruma';

  @override
  String get owner => 'Ev Sahibine';

  @override
  String proposeChangesInfo(String role) {
    return 'Değişiklikler $role onayı için gönderilecektir. Mevcut şartlar kabul edilene kadar geçerli kalır.';
  }

  @override
  String get proposeChanges => 'Değişiklik Öner';

  @override
  String get declarePayment => 'Ödeme Bildir';

  @override
  String get uploadReceipt => 'Dekont Yükle';

  @override
  String get paidInCash => 'Nakit Ödendi';

  @override
  String get noFinancialRecords => 'Henüz finansal kayıt bulunamadı';

  @override
  String get noActiveContract => 'Yüklenmiş kontrat bulunamadı';

  @override
  String get contractTermsInfo =>
      'Aktif kontrat şartları. Burada yapılan tüm değişiklikler yalnızca kiracı ve ev sahibi mutabık kaldığında geçerli olur.';

  @override
  String get send => 'Gönder';

  @override
  String get totalRent => 'Toplam Kira';

  @override
  String get infoTooltip =>
      'Isınma, su ve çöp toplama gibi toplu kamu hizmetlerini kapsar.';

  @override
  String get electricityTooltip => 'Bireysel elektrik tüketim bedeli.';

  @override
  String get internetTooltip => 'Abonelik bazlı internet ve TV paketleri.';

  @override
  String get maintenanceTooltip =>
      'Bina temizliği, asansör bakımı ve ortak alan giderleri.';

  @override
  String get declare => 'Bildir';

  @override
  String get viewReceipt => 'Dekontu Gör';

  @override
  String proposesChanges(String name) {
    return '$name aşağıdaki değişiklikleri teklif ediyor:';
  }

  @override
  String get awaitingApprovalInfo =>
      'Değişiklik teklifiniz diğer tarafın onayını bekliyor.';

  @override
  String get propertyDetails => 'MÜLK BİLGİLERİ';

  @override
  String get defaultLeaseTerms => 'VARSAYILAN KONTRAT ŞARTLARI';

  @override
  String get defaultLeaseTermsSubtitle =>
      'Yeni kiracı davet ederken kullanılacak taslak bilgiler.';

  @override
  String get invalidNumber => 'Geçersiz sayı';

  @override
  String get enterDayBetween1and31 => '1-31 arası bir gün girin';

  @override
  String get expenseConfiguration => 'GİDER KALEMLERİ';

  @override
  String get expenseInfostan => 'Infostan';

  @override
  String get expenseElectricity => 'Elektrik';

  @override
  String get expenseInternetTV => 'İnternet/TV';

  @override
  String get expenseMaintenance => 'Bina Bakımı';

  @override
  String get expenseTax => 'Vergi';

  @override
  String get tenantPaysTo => 'Kiracı kime ödeyecek?';

  @override
  String get fileSelected => 'Dosya Seçildi';

  @override
  String get selectInvoice => 'Fatura Seç';

  @override
  String get amount => 'Tutar';

  @override
  String get setAmountAndUploadInvoice => 'Tutar Belirle & Fatura Yükle';

  @override
  String get save => 'Kaydet';

  @override
  String get paymentDeclared => 'Ödeme başarıyla beyan edildi.';

  @override
  String get dashboard => 'Kontrol Paneli';

  @override
  String get parties => 'TARAFLAR';

  @override
  String get tenantEmail => 'Kiracı E-postası';

  @override
  String get existingContractTermsInfo =>
      'Lehterdeki mevcut uzaşılmış kontrat şartları (kira bedeli, tarihler ve masraf dağılımı) bu kiracı için de geçerli olacaktır.';

  @override
  String get rentAndPayment => 'KİRA VE ÖDEME';

  @override
  String get datesAndContract => 'TARİHLER VE KONTRAT';

  @override
  String get expenseSettingsHeader => 'GİDER AYARLARI';

  @override
  String get editContract => 'Kontratı Düzenle';

  @override
  String get sendRevision => 'Revize Gönder';

  @override
  String get revisionSent => 'Revize teklif gönderildi';

  @override
  String get existingFileKept => 'Mevcut Dosya Korunuyor';

  @override
  String get done => 'Tamam';

  @override
  String get startAndEndDatesMandatory =>
      'Başlangıç ve bitiş tarihleri zorunludur';

  @override
  String get revisionRequested => 'Revize İstendi';

  @override
  String get statusActive => 'Aktif';

  @override
  String get statusPending => 'Onay Bekliyor';

  @override
  String get statusDeclined => 'Reddedildi';

  @override
  String get statusExpired => 'Süresi Doldu';

  @override
  String get statusNegotiating => 'Görüşülüyor';

  @override
  String get tenantPaysLandlord => 'Kiracı ev sahibine öder';

  @override
  String get tenantPaysUtility => 'Kiracı kuruma öder';

  @override
  String get includedInRent => 'Kiraya dahil';

  @override
  String get changesAccepted => 'Değişiklikler kabul edildi';

  @override
  String get changesDeclined => 'Değişiklikler reddedildi';

  @override
  String get contractChangeProposal => 'Kontrat Değişikliği Teklifi';

  @override
  String get cancelProposal => 'Teklifi İptal Et';

  @override
  String get viewInvoice => 'Faturayı Gör';

  @override
  String get paymentResponsibility => 'ÖDEME SORUMLULUĞU';

  @override
  String get tenantPaysDirectlyToUtility =>
      'Kiracı ödemeyi doğrudan kuruma yapar';

  @override
  String get tenantPaysToLandlord => 'Kiracı ödemeyi ev sahibine yapar';

  @override
  String get selectPaymentReceiverWarning =>
      'Devam etmeden önce ödeme yapılacak tarafı seçin.';

  @override
  String progressSummary(int completed, int total, int sent) {
    return '$completed / $total ödendi • $sent gönderildi';
  }

  @override
  String get maintenance => 'Bakım / Arıza';

  @override
  String get issues => 'Arızalar';

  @override
  String get newRequest => 'Yeni Talep';

  @override
  String get reportIssue => 'Arıza Bildir';

  @override
  String get issueTitle => 'Başlık';

  @override
  String get issueDescription => 'Açıklama';

  @override
  String get issueCategory => 'Kategori';

  @override
  String get issuePriority => 'Öncelik';

  @override
  String get statusInvestigating => 'İnceleniyor';

  @override
  String get statusResolved => 'Çözüldü';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityUrgent => 'Acil';

  @override
  String get categoryPlumbing => 'Tesisat';

  @override
  String get categoryElectrical => 'Elektrik';

  @override
  String get categoryHeating => 'Isınma';

  @override
  String get categoryInternet => 'İnternet';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get noIssuesTitle => 'Henüz arıza bildirimi yok';

  @override
  String get noIssuesMessage =>
      'Her şey yolunda! Bu mülk için bildirilen bir arıza bulunmuyor.';

  @override
  String get updateStatus => 'Durum Güncelle';

  @override
  String get issueDetails => 'Arıza Detayları';

  @override
  String logMaintenanceCreated(String title) {
    return '$title başlıklı arıza kaydı oluşturuldu.';
  }

  @override
  String logMaintenanceStatusUpdated(String status) {
    return 'Arıza kaydı durumu $status olarak güncellendi.';
  }

  @override
  String get logMaintenanceReopened => 'Arıza kaydı tekrar açıldı.';

  @override
  String get logMaintenanceMessageAdded => 'Arıza kaydına yeni mesaj eklendi.';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get markAllAsRead => 'Tümünü okundu işaretle';

  @override
  String get noNotifications => 'Henüz bildirim yok';

  @override
  String get documents => 'Belgeler';

  @override
  String get mainContract => 'Ana Sözleşme';

  @override
  String get addDocument => 'Belge Ekle';

  @override
  String get enterDocumentName => 'Belge adı girin';

  @override
  String get noDocumentsYet => 'Henüz belge yok';

  @override
  String get additionalDocuments => 'Ek Belgeler';

  @override
  String get deleteDocument => 'Belgeyi Sil';

  @override
  String get deleteDocumentConfirm =>
      'Bu belgeyi silmek istediğinizden emin misiniz?';

  @override
  String get uploadMainContract => 'Sözleşmeyi Yükle';

  @override
  String get manageDocuments => 'Dokümanları Yönet';

  @override
  String get monthlyCollected => 'Toplanan';

  @override
  String get totalRentShort => 'Kira';

  @override
  String get delays => 'Gecikme';

  @override
  String get vacant => 'Boş';

  @override
  String propertiesCount(int count) {
    return 'Emlak';
  }

  @override
  String get hasDebt => 'Borcu Var';

  @override
  String get paymentAwaitingApproval => 'Onay Bekliyor';

  @override
  String get rent => 'Kira';

  @override
  String get bills => 'Faturalar';

  @override
  String get waiting => 'Bekleniyor';

  @override
  String get debtLabel => 'Borç';

  @override
  String get paidLabel => 'Ödendi';

  @override
  String get enterBill => 'Fatura Gir';

  @override
  String get addContractAndTenant => 'Kontrat ve Kiracı Ekle';

  @override
  String get approve => 'Onayla';

  @override
  String get reject => 'Reddet';

  @override
  String get confirmApprovePaymentTitle => 'Ödemeyi Onayla';

  @override
  String get confirmApprovePaymentMessage =>
      'Bu ödemeyi onaylamak istiyor musunuz?';

  @override
  String get confirmRejectPaymentTitle => 'Ödemeyi Reddet';

  @override
  String get confirmRejectPaymentMessage =>
      'Bu ödemeyi reddetmek ve kiracıdan tekrar bildirmesini istemek mi istiyorsunuz?';

  @override
  String get confirm => 'Onayla';

  @override
  String get terminateContract => 'Kontratı Feshet';

  @override
  String get terminationDate => 'Fesih Tarihi';

  @override
  String get confirmTerminationTitle => 'Kontratı Feshet?';

  @override
  String get confirmTerminationMessage =>
      'Bu kontratı seçilen tarihte bitirmek için bir fesih talebi göndermek istediğinizden emin misiniz?';

  @override
  String get terminationRequestSent => 'Fesih talebi başarıyla gönderildi.';

  @override
  String get statusInactive => 'Pasif / Bitti';

  @override
  String get terminationRequested => 'Fesih Bekleniyor';

  @override
  String get approveTermination => 'Feshi Onayla';

  @override
  String get declineTermination => 'Feshi Reddet';

  @override
  String contractTerminatedOn(Object date) {
    return 'Sözleşme feshedildi: $date';
  }

  @override
  String contractWillEndOn(String date) {
    return 'Kontrat şu tarihte sona erecek: $date';
  }

  @override
  String get dispute => 'İtiraz Et';

  @override
  String get disputeReason => 'İtiraz Nedeni';

  @override
  String get disputeReasonHint => 'Neden itiraz ettiğinizi açıklayın...';

  @override
  String get disputedHeader => 'İTİRAZ EDİLDİ';

  @override
  String logRentDisputed(String month, String reason) {
    return 'Kiracı $month ödemesine itiraz etti: $reason';
  }

  @override
  String get confirmDisputeTitle => 'Ödemeye İtiraz Et';

  @override
  String get disputeSentSuccess => 'İtirazınız ev sahibine iletildi.';

  @override
  String get takeAction => 'İşlem Yap';

  @override
  String get ownerNote => 'Ev Sahibi Notu';

  @override
  String get explanationOptional => 'Açıklama (İsteğe bağlı)';

  @override
  String get explanationHint => 'Örn: Sayacı kontrol ettim...';

  @override
  String get units => 'Birimler';

  @override
  String get tenantsLabel => 'Kiracılar';

  @override
  String get portfolioManagement => 'Portföy Yönetimi';

  @override
  String get paymentRequests => 'Ödeme ve Talepler';

  @override
  String get profileSettings => 'Profil Ayarları';

  @override
  String get confirmSignOutMessage =>
      'Çıkış yapmak istediğinizden emin misiniz?';

  @override
  String errorWithDetails(String error) {
    return 'Hata: $error';
  }

  @override
  String syncError(String error) {
    return 'Senkronizasyon Hatası: $error';
  }

  @override
  String get acceptTermsWarning =>
      'Devam etmek için lütfen şartları kabul edin.';

  @override
  String get maintenanceRequestSuccess =>
      'Arıza bildirimi başarıyla gönderildi.';

  @override
  String get ok => 'Tamam';

  @override
  String get orLabel => 'VEYA';

  @override
  String errorUploadingPhoto(String error) {
    return 'Fotoğraf yüklenirken hata oluştu: $error';
  }

  @override
  String errorUpdatingStatus(String error) {
    return 'Durum güncellenirken hata oluştu: $error';
  }

  @override
  String errorReopeningRequest(String error) {
    return 'Talep tekrar açılırken hata oluştu: $error';
  }

  @override
  String errorOpeningDetails(String error) {
    return 'Detaylar açılamadı: $error';
  }

  @override
  String get nextPayment => 'Gelecek Ödeme';

  @override
  String get payNow => 'Hemen Öde';

  @override
  String get upcomingLabel => 'Beklemede';

  @override
  String get joinPropertyInvitation => 'Mülke Katılma Daveti';

  @override
  String get feedbackSent => 'Geri Bildirim Gönderildi';

  @override
  String get rentalProposal => 'Kira Teklifi';

  @override
  String get reviewContractTerms => 'Lütfen kontrat şartlarını inceleyin.';

  @override
  String get expenseDistribution => 'Giderlerin Durumu';

  @override
  String get yourNote => 'Sizin Notunuz:';

  @override
  String get backToDashboard => 'Ana Sayfaya Dön';

  @override
  String get propertyDetailsHeader => 'MÜLK BİLGİLERİ';

  @override
  String get defaultLeaseTermsHeader => 'VARSAYILAN KONTRAT ŞARTLARI';

  @override
  String get proposeRevision => 'Revize Öner';

  @override
  String get revisionTermsQuestion =>
      'Hangi şartları değiştirmek istiyorsunuz? (Kira bedeli, ödeme günü, giderler vb.)';

  @override
  String get enterNotesHint => 'Notunuzu buraya yazın...';

  @override
  String get submit => 'Gönder';

  @override
  String invitedToJoinProperty(String property) {
    return '$property mülküne katılmaya davet edildiniz.';
  }

  @override
  String get waitingForLandlord => 'Ev sahibinin yanıtı bekleniyor...';

  @override
  String get day => 'Gün';

  @override
  String get notSelected => 'Seçilmedi';

  @override
  String get acceptTermsAndDistribution =>
      'Kontrat şartlarını ve gider dağılımını kabul ediyorum.';

  @override
  String get datesMandatory => 'Başlangıç ve bitiş tarihleri zorunludur';

  @override
  String get partiesHeader => 'TARAFLAR';

  @override
  String get leaseLockedWarning =>
      'Lehterdeki mevcut uzaşılmış kontrat şartları (kira bedeli, tarihler ve masraf dağılımı) bu kiracı için de geçerli olacaktır.';

  @override
  String get rentPaymentHeader => 'KİRA VE ÖDEME';

  @override
  String get loadingPlaceholder => 'Yükleniyor...';

  @override
  String get photos => 'Fotoğraflar';

  @override
  String get add => 'Ekle';

  @override
  String get paymentHistory => 'Ödeme Geçmişi';

  @override
  String get viewAll => 'Tümünü Gör';

  @override
  String get ended => 'Bitti';

  @override
  String plannedEnd(String date) {
    return 'Planlanan Bitiş: $date';
  }

  @override
  String get yourApartment => 'Oturduğunuz Daire';

  @override
  String get commentHint => 'Yorum yazın...';

  @override
  String get issueResolvedStatus => 'Arıza giderildi olarak işaretlendi.';

  @override
  String get reopenIssue => 'Hala Sorun Var (Tekrar Aç)';

  @override
  String get deleteRequest => 'Kaydı Sil';

  @override
  String get terminationApproved => 'Fesih Onaylandı';

  @override
  String get paymentDeclaredHand => 'Ödeme elden yapıldı olarak beyan edildi.';

  @override
  String get fileUnreadable => 'Dosya okunamadı.';

  @override
  String paymentDeclaredSuccess(String title) {
    return '$title ödemesi beyan edildi.';
  }

  @override
  String get setAmountUploadInvoice => 'Tutar Belirle & Fatura Yükle';

  @override
  String get yourMessage => 'Mesajınız:';

  @override
  String get revisionRequestLabel => 'Revizyon Talebi:';

  @override
  String get noActivityLogs => 'Henüz işlem kaydı bulunamadı';

  @override
  String get landlordProposedChanges =>
      'Ev sahibi kontrat değişikliği önerdi. İncelemek için dokun.';

  @override
  String get tenantProposedChanges =>
      'Kiracı kontrat değişikliği önerdi. İncelemek için dokun.';

  @override
  String dueOn(String date) {
    return 'Ödeme tarihi: $date';
  }

  @override
  String get item => 'kalem';

  @override
  String get items => 'kalem';

  @override
  String get waitingForOtherParty => 'Karşı tarafın onayı bekleniyor...';

  @override
  String get awaitingApproval => 'Onay bekleniyor...';

  @override
  String get contract => 'Sözleşme';

  @override
  String paidOn(Object date) {
    return '$date tarihinde ödendi';
  }

  @override
  String get cannotInviteSelf =>
      'Kendi e-posta adresinizi kiracı olarak davet edemezsiniz.';

  @override
  String get paywallTitle => 'Stanomer Premium';

  @override
  String get paywallSubtitle => 'Mülk yönetiminde sınırları kaldırın.';

  @override
  String get unlimitedProperties => 'Sınırsız mülk ekleme ve yönetimi';

  @override
  String get detailedReporting => 'Daha hızlı ve detaylı raporlama';

  @override
  String get extraStorage => 'Daha fazla depolama alanı';

  @override
  String get pdfContracts => 'PDF kontrat üretme (Yakında)';

  @override
  String get automatedRenewal =>
      'Otomatik kira hesaplama ve yenileme (Yakında)';

  @override
  String get restorePurchases => 'Satın Alımları Geri Yükle';

  @override
  String get limitReachedTitle => 'Ücretsiz limitinize ulaştınız';

  @override
  String get limitReachedSubtitle =>
      'Birden fazla mülk yönetmek için Stanomer Premium\'a geçiş yapın.';

  @override
  String get discoverPremium => 'Premium\'u Keşfet';

  @override
  String get optionsLoadFailed => 'Satın alma seçenekleri yüklenemedi.';

  @override
  String get manageSubscription => 'Aboneliği Yönet';

  @override
  String get premiumMobileOnly => 'Mobil Uygulama Gerekli';

  @override
  String get premiumMobileOnlyDesc => 'Stanomer Premium aboneliği yalnızca mobil uygulama üzerinden satın alınabilir. Aşağıdaki bağlantılardan uygulamayı indirerek Premium\'a geçiş yapabilirsiniz.';

  @override
  String get downloadOnAppStore => 'App Store\'dan İndir';

  @override
  String get downloadOnPlayStore => 'Google Play\'den İndir';

  @override
  String get premiumFeatures => 'Premium Özellikler';

  @override
  String get premiumFeature1 => 'Sınırsız mülk yönetimi';

  @override
  String get premiumFeature2 => 'Gelişmiş finansal raporlama';

  @override
  String get premiumFeature3 => 'Öncelikli destek';

  @override
  String get premiumFeature4 => 'Tüm platformlarda erişim';
}
