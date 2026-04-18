// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get appTitle => 'Stanomer';

  @override
  String get login => 'Prijavite se';

  @override
  String get signup => 'Registracija';

  @override
  String get email => 'E-pošta';

  @override
  String get password => 'Lozinka';

  @override
  String get landlord => 'Stanodavac';

  @override
  String get tenant => 'Stanar';

  @override
  String get zzplConsent =>
      'Pristajem na obradu mojih podataka u skladu sa Zakonom o zaštiti podataka o ličnosti (ZZPL) Srbije.';

  @override
  String get selectRole => 'Izaberite svoju ulogu';

  @override
  String get fieldRequired => 'Ovo polje je obavezno';

  @override
  String get consentRequired => 'Morate prihvatiti ZZPL da biste nastavili';

  @override
  String get loginToAccount => 'Prijavite se na svoj nalog';

  @override
  String get createAccount => 'Napravite novi nalog';

  @override
  String get dontHaveAccount => 'Nemate nalog? Registrujte se';

  @override
  String get alreadyHaveAccount => 'Imate nalog? Prijavite se';

  @override
  String get continueWithGoogle => 'Nastavite sa Google-om';

  @override
  String get continueWithApple => 'Nastavite sa Apple-om';

  @override
  String get fullName => 'Ime i prezime';

  @override
  String get errorSelectRole => 'Molimo izaberite svoju ulogu';

  @override
  String get deleteAccount => 'Obriši nalog';

  @override
  String get deleteAccountWarning =>
      'Ova radnja je trajna i ne može se poništiti. Svi vaši podaci će biti obrisani.';

  @override
  String get confirmPasswordForDeletion =>
      'Molimo unesite lozinku da potvrdite brisanje';

  @override
  String get deleteButtonLabel => 'Trajno obriši moj nalog';

  @override
  String get cancel => 'Otkaži';

  @override
  String get invalidPassword => 'Pogrešna lozinka';

  @override
  String get welcomeToStanomer => 'Dobrodošli u Stanomer';

  @override
  String get consentTextFullTitle =>
      'Saglasnost za obradu podataka o ličnosti (ZZPL)';

  @override
  String get profile => 'Profil';

  @override
  String get updateName => 'Ažuriraj ime';

  @override
  String get updatePassword => 'Ažuriraj lozinku';

  @override
  String get oldPassword => 'Trenutna lozinka';

  @override
  String get newPassword => 'Nova lozinka';

  @override
  String get saveChanges => 'Sačuvaj izmene';

  @override
  String get passwordChangedSuccess => 'Lozinka je uspešno promenjena';

  @override
  String get profileUpdatedSuccess => 'Profil je uspešno ažuriran';

  @override
  String get role => 'Uloga';

  @override
  String get roleLandlord => 'Stanodavac';

  @override
  String get roleTenant => 'Stanar';

  @override
  String get logout => 'Odjavi se';

  @override
  String get addProperty => 'Dodaj nekretninu';

  @override
  String get address => 'Adresa';

  @override
  String get monthlyRent => 'Mesečna kirija';

  @override
  String get depositAmount => 'Iznos depozita';

  @override
  String get currency => 'Valuta';

  @override
  String get propertyName => 'Naziv nekretnine';

  @override
  String get propertyNameHint => 'npr. Apartman Beograd';

  @override
  String get propertyAddedSuccess => 'Nekretnina uspešno dodata';

  @override
  String get propertyUpdatedSuccess => 'Nekretnina uspešno ažurirana';

  @override
  String get noProperties => 'Nema pronađenih nekretnina';

  @override
  String get addYourFirstProperty =>
      'Dodajte svoju prvu nekretninu da biste започели praćenje!';

  @override
  String get editProperty => 'Uredi nekretninu';

  @override
  String get delete => 'Obriši';

  @override
  String get confirmDeleteTitle => 'Obriši nekretninu';

  @override
  String get confirmDeleteMessage =>
      'Da li ste sigurni da želite da obrišete ovu nekretninu? Ova radnja se ne može poništiti.';

  @override
  String get propertyDeletedSuccess => 'Nekretnina uspešno obrisana';

  @override
  String get inviteTenant => 'Pozovi stanara';

  @override
  String get emailHint => 'Unesite e-mail stanara';

  @override
  String get inviteCreatedSuccess =>
      'Link za poziv je kreiran! Sada ga možete podeliti.';

  @override
  String get shareInviteLink => 'Podeli link za poziv';

  @override
  String get copyLink => 'Kopiraj link';

  @override
  String get noInvitesYet => 'Još uvek nema poslatih poziva';

  @override
  String get cancelInvitation => 'Otkaži poziv';

  @override
  String get invitationCancelledSuccess => 'Poziv je uspešno otkazan';

  @override
  String get pendingInvite => 'Poziv na čekanju';

  @override
  String get contractSentToTenant => 'Ugovor poslat zakupcu';

  @override
  String get overview => 'Pregled';

  @override
  String get financials => 'Finansije';

  @override
  String get propertySettings => 'Podešavanja';

  @override
  String get invitationHistory => 'Istorija poziva';

  @override
  String get invitationDetails => 'Detalji poziva';

  @override
  String get acceptInvitation => 'Da, iznajmio sam ovo';

  @override
  String get declineInvitation => 'Odbij poziv';

  @override
  String get inviteNotFound => 'Poziv nije pronađen ili je istekao';

  @override
  String get invitationAcceptedSuccess =>
      'Dobrodošli kući! Poziv je prihvaćen.';

  @override
  String pendingInvitationBanner(String property) {
    return 'Imate otvoren poziv za $property';
  }

  @override
  String invitedBy(String name) {
    return 'Pozvao vas je $name';
  }

  @override
  String get yourName => 'Vaše ime';

  @override
  String get yourNameHint => 'Unesite svoje puno ime';

  @override
  String get viewInvite => 'Pogledaj poziv';

  @override
  String get myProperties => 'Moje nekretnine';

  @override
  String get tenantEmptyStateTitle => 'Još uvek nemate dodeljenu nekretninu';

  @override
  String get tenantEmptyStateMessage =>
      'Ako vam je stanodavac poslao poziv, on će se pojaviti ovde. Kliknite na dugme ispod da biste proverili nove pozive.';

  @override
  String get refresh => 'Osveži';

  @override
  String get invitationDeclinedSuccess => 'Poziv je odbijen.';

  @override
  String get confirmDeclineInviteTitle => 'Odbiti poziv?';

  @override
  String get confirmDeclineInviteMessage =>
      'Da li ste sigurni da želite da odbijete ovaj poziv? Biće uklonjen sa vaše liste na čekanju.';

  @override
  String get contractStartDate => 'Datum početka ugovora';

  @override
  String get contractEndDate => 'Datum završetka ugovora';

  @override
  String get uploadContract => 'Otpremi ugovor';

  @override
  String get viewContract => 'Pogledaj ugovor';

  @override
  String get contractFile => 'Datoteka ugovora';

  @override
  String get selectDate => 'Izaberi datum';

  @override
  String get appLanguage => 'Jezik aplikacije';

  @override
  String get english => 'Engleski';

  @override
  String get serbianLatin => 'Srpski (Latinica)';

  @override
  String get serbianCyrillic => 'Srpski (Ćirilica)';

  @override
  String get turkish => 'Turski';

  @override
  String get tenantMode => 'Mod stanara';

  @override
  String get landlordMode => 'Mod stanodavca';

  @override
  String get whatAreYou => 'Kao šta želite da nastavite?';

  @override
  String get selectRoleToContinue =>
      'Izaberite ulogu da biste započeli. Možete je promeniti bilo kada u zaglavlju iznad.';

  @override
  String get consentTextFullBody =>
      'Korišćenjem aplikacije Stanomer, dajete izričitu saglasnost za obradu vaših ličnih podataka u skladu sa Zakonom o zaštiti podataka o ličnosti (ZZPL) Republike Srbije.';

  @override
  String get removeTenant => 'Ukloni stanara';

  @override
  String get removeTenantConfirmation =>
      'Da li ste sigurni da želite da uklonite ovog stanara iz nekretnine? Ovo će raskinuti vezu i obrisati zapis o pozivu.';

  @override
  String get remove => 'Ukloni';

  @override
  String logRentDeclared(String month) {
    return 'Stanar je označio kiriju za $month kao plaćenu.';
  }

  @override
  String logRentApproved(String month) {
    return 'Stanodavac je odobrio kiriju za $month.';
  }

  @override
  String logRentRejected(String month) {
    return 'Stanodavac je odbio kiriju za $month.';
  }

  @override
  String logMarkedAsPaid(String month) {
    return 'Stanodavac je označio $month kao plaćeno.';
  }

  @override
  String logMarkedAsPending(String month) {
    return 'Stanodavac je označio $month na čekanju.';
  }

  @override
  String logAutoApproved(String month) {
    return 'Kirija za $month je automatski odobrena od strane sistema nakon 5 dana.';
  }

  @override
  String get activity => 'Aktivnosti';

  @override
  String get noContractsTitle => 'Još uvek nema ugovora';

  @override
  String get noContractsMessage =>
      'Da biste pratili kiriju i troškove, prvo pozovite stanara unošenjem detalja ugovora.';

  @override
  String get inviteFirstTenant => 'Pozovite prvog zakupca';

  @override
  String get confirmCancelInvitationTitle => 'Otkaži poziv';

  @override
  String get confirmCancelInvitationMessage =>
      'Da li ste sigurni da želite da povučete ovaj poziv? Ova akcija će ga trajno izbrisati.';

  @override
  String get confirmDeclineRevisionTitle => 'Odbij zahtev za reviziju';

  @override
  String get confirmDeclineRevisionMessage =>
      'Da li ste sigurni da želite da odbijete zahtev zakupca za reviziju? Ugovor će ostati na čekanju sa originalnim uslovima.';

  @override
  String get activeContract => 'Aktivni ugovor';

  @override
  String get activeLease => 'AKTIVNI UGOVOR';

  @override
  String get invitationSent => 'Poziv poslat';

  @override
  String get accept => 'Prihvati';

  @override
  String get decline => 'Odbij';

  @override
  String get declineRevisionRequest => 'Odbij zahtev za reviziju';

  @override
  String get pendingHeader => 'NA ČEKANJU';

  @override
  String get awaitingHeader => 'ČEKA ODOBRENJE';

  @override
  String get paidHeader => 'PLAĆENO';

  @override
  String get waitingForTenantPayment => 'Čeka uplatu stanara';

  @override
  String get waitingForYourApproval => 'Čeka vaše odobrenje';

  @override
  String get waitingForOwnerApproval => 'Čeka odobrenje stanodavca';

  @override
  String get waitingForYourPayment => 'Čeka vašu uplatu';

  @override
  String get processCompleted => 'Proces završen';

  @override
  String get declared => 'prijavljeno';

  @override
  String get sent => 'poslato';

  @override
  String get noInvoice => 'Bez računa';

  @override
  String get uploadInvoice => 'Otpremi račun';

  @override
  String get awaitingInvoice => 'Čeka se račun';

  @override
  String get updateLabel => 'Ažuriraj';

  @override
  String get statusVacant => 'Slobodno';

  @override
  String get pendingApproval => 'ČEKA ODOBRENJE';

  @override
  String get targetRent => 'CILJNA KIRIJA';

  @override
  String get contractInfo => 'Podaci o ugovoru';

  @override
  String get term => 'Period';

  @override
  String get dueDay => 'Dan dospeća';

  @override
  String get contractDetails => 'Detalji ugovora';

  @override
  String get pastContracts => 'Prošli ugovori';

  @override
  String previousLeasesCount(int count) {
    return '$count prethodnih ugovora';
  }

  @override
  String get propertySettingsLabel => 'Podešavanja nekretnine';

  @override
  String get propertyActions => 'Akcije nekretnine';

  @override
  String get leavePropertyConfirm =>
      'Da li želite da napustite ovu nekretninu?';

  @override
  String get leaveProperty => 'Napusti nekretninu';

  @override
  String get areYouSure => 'Da li ste sigurni?';

  @override
  String get pendingInvitations => 'Pozivi na čekanju';

  @override
  String get contractSettings => 'Podešavanja ugovora';

  @override
  String get activeContractTermsInfo =>
      'Aktivni uslovi ugovora. Sve izmene ovde stupaju na snagu samo kada se stanar i stanodavac slože.';

  @override
  String get dueDayOfMonth => 'Dan dospeća u mesecu';

  @override
  String get startDate => 'Datum početka';

  @override
  String get endDate => 'Datum kraja';

  @override
  String get taxConfiguration => 'Konfiguracija poreza';

  @override
  String get included => 'Uključeno';

  @override
  String get addedVat => 'Dodato (+15%)';

  @override
  String get expensesHeader => 'TROŠKOVI';

  @override
  String get extraPayment => 'Dodatna uplata';

  @override
  String get utility => 'Komunalno';

  @override
  String get owner => 'Vlasnik';

  @override
  String proposeChangesInfo(String role) {
    return 'Izmene će biti poslate $role na odobrenje. Trenutni uslovi ostaju na snazi do prihvatanja.';
  }

  @override
  String get proposeChanges => 'Predloži izmene';

  @override
  String get declarePayment => 'Prijavi uplatu';

  @override
  String get uploadReceipt => 'Otpremi uplatnicu';

  @override
  String get paidInCash => 'Plaćeno gotovinom';

  @override
  String get noFinancialRecords => 'Još uvek nema finansijskih zapisa';

  @override
  String get noActiveContract => 'Nije pronađen otpremljeni ugovor';

  @override
  String get contractTermsInfo =>
      'Aktivni uslovi ugovora. Sve izmene ovde stupaju na snagu samo kada se stanar i stanodavac slože.';

  @override
  String get send => 'Pošalji';

  @override
  String get totalRent => 'Ukupna kirija';

  @override
  String get infoTooltip =>
      'Pokriva zajedničke komunalne usluge kao što su grejanje, voda i odvoz smeća.';

  @override
  String get electricityTooltip =>
      'Individualni troškovi potrošnje električne energije.';

  @override
  String get internetTooltip => 'Pretplatnički internet i TV paketi.';

  @override
  String get maintenanceTooltip =>
      'Čišćenje zgrade, održavanje lifta i troškovi zajedničkih prostorija.';

  @override
  String get declare => 'Prijavi';

  @override
  String get viewReceipt => 'Vidi uplatnicu';

  @override
  String proposesChanges(String name) {
    return '$name predlaže sledeće izmene:';
  }

  @override
  String get awaitingApprovalInfo =>
      'Vaš predlog izmena čeka odobrenje druge strane.';

  @override
  String get propertyDetails => 'DETALJI NEKRETNINE';

  @override
  String get defaultLeaseTerms => 'PODRAZUMEVANI USLOVI ZAKUPA';

  @override
  String get defaultLeaseTermsSubtitle =>
      'Uslovi koji se koriste kao šablon za nove pozive.';

  @override
  String get invalidNumber => 'Nevažeći broj';

  @override
  String get enterDayBetween1and31 => 'Unesite dan između 1 i 31';

  @override
  String get expenseConfiguration => 'KONFIGURACIJA TROŠKOVA';

  @override
  String get expenseInfostan => 'Infostan';

  @override
  String get expenseElectricity => 'Struja (Električna energija)';

  @override
  String get expenseInternetTV => 'Internet/TV';

  @override
  String get expenseMaintenance => 'Održavanje zgrade';

  @override
  String get expenseTax => 'Porez';

  @override
  String get tenantPaysTo => 'Stanar plaća:';

  @override
  String get fileSelected => 'Fajl izabran';

  @override
  String get selectInvoice => 'Izaberi račun';

  @override
  String get amount => 'Iznos';

  @override
  String get setAmountAndUploadInvoice => 'Podesite iznos i otpremite račun';

  @override
  String get save => 'Sačuvaj';

  @override
  String get paymentDeclared => 'Uplata je uspešno prijavljena.';

  @override
  String get dashboard => 'Kontrolna tabla';

  @override
  String get parties => 'STRANE';

  @override
  String get tenantEmail => 'E-pošta stanara';

  @override
  String get existingContractTermsInfo =>
      'Postojeći dogovoreni uslovi ugovora (kirija, datumi i troškovi) važiće i za ovog stanara.';

  @override
  String get rentAndPayment => 'KIRIJA I PLAĆANJE';

  @override
  String get datesAndContract => 'DATUMI I UGOVOR';

  @override
  String get expenseSettingsHeader => 'PODEŠAVANJE TROŠKOVA';

  @override
  String get editContract => 'Izmeni ugovor';

  @override
  String get sendRevision => 'Pošalji reviziju';

  @override
  String get revisionSent => 'Predlog revizije je poslat';

  @override
  String get existingFileKept => 'Postojeći fajl je zadržan';

  @override
  String get done => 'Gotovo';

  @override
  String get startAndEndDatesMandatory =>
      'Datum početka i završetka su obavezni';

  @override
  String get revisionRequested => 'Tražena revizija';

  @override
  String get statusActive => 'Aktivno';

  @override
  String get statusPending => 'Čeka odobrenje';

  @override
  String get statusDeclined => 'Odbijeno';

  @override
  String get statusExpired => 'Isteklo';

  @override
  String get statusNegotiating => 'U pregovorima';

  @override
  String get tenantPaysLandlord => 'Stanar plaća stanodavcu';

  @override
  String get tenantPaysUtility => 'Stanar plaća komunalijama';

  @override
  String get includedInRent => 'Uključeno u kiriju';

  @override
  String get changesAccepted => 'Promene su prihvaćene';

  @override
  String get changesDeclined => 'Promene su odbijene';

  @override
  String get contractChangeProposal => 'Predlog promene ugovora';

  @override
  String get cancelProposal => 'Otkaži predlog';

  @override
  String get viewInvoice => 'Pogledaj fakturu';

  @override
  String get paymentResponsibility => 'ODGOVORNOST ZA PLAĆANJE';

  @override
  String get tenantPaysDirectlyToUtility =>
      'Stanar plaća direktno komunalnoj službi';

  @override
  String get tenantPaysToLandlord => 'Stanar plaća stanodavcu';

  @override
  String get selectPaymentReceiverWarning =>
      'Molimo izaberite primaoca uplate pre nastavka.';

  @override
  String progressSummary(int completed, int total, int sent) {
    return '$completed / $total plaćeno • $sent poslato';
  }

  @override
  String get maintenance => 'Održavanje';

  @override
  String get issues => 'Problemi';

  @override
  String get newRequest => 'Novi zahtev';

  @override
  String get reportIssue => 'Prijavi kvar';

  @override
  String get issueTitle => 'Naslov';

  @override
  String get issueDescription => 'Opis';

  @override
  String get issueCategory => 'Kategorija';

  @override
  String get issuePriority => 'Prioritet';

  @override
  String get statusInvestigating => 'Na pregledu';

  @override
  String get statusResolved => 'Rešeno';

  @override
  String get priorityNormal => 'Normalno';

  @override
  String get priorityUrgent => 'Hitno';

  @override
  String get categoryPlumbing => 'Vodovod';

  @override
  String get categoryElectrical => 'Električna energija';

  @override
  String get categoryHeating => 'Grejanje';

  @override
  String get categoryInternet => 'Internet';

  @override
  String get categoryOther => 'Ostalo';

  @override
  String get noIssuesTitle => 'Još nema prijavljenih kvarova';

  @override
  String get noIssuesMessage =>
      'Sve je u redu! Nema prijavljenih zahteva za održavanje ove imovine.';

  @override
  String get updateStatus => 'Ažuriraj status';

  @override
  String get issueDetails => 'Detalji kvara';

  @override
  String logMaintenanceCreated(String title) {
    return 'Kreiran zahtev za održavanje: $title';
  }

  @override
  String logMaintenanceStatusUpdated(String status) {
    return 'Status održavanja ažuriran na $status';
  }

  @override
  String get logMaintenanceReopened => 'Zahtev za održavanje ponovo otvoren';

  @override
  String get logMaintenanceMessageAdded =>
      'Dodata nova poruka zahtevu za održavanje';

  @override
  String get notifications => 'Obaveštenja';

  @override
  String get markAllAsRead => 'Označi sve kao pročitano';

  @override
  String get noNotifications => 'Još nema obaveštenja';

  @override
  String get documents => 'Dokumenta';

  @override
  String get mainContract => 'Glavni ugovor';

  @override
  String get addDocument => 'Dodaj dokument';

  @override
  String get enterDocumentName => 'Unesite naziv dokumenta';

  @override
  String get noDocumentsYet => 'Još uvek nema dokumenata';

  @override
  String get additionalDocuments => 'Dodatna dokumenta';

  @override
  String get deleteDocument => 'Obriši dokument';

  @override
  String get deleteDocumentConfirm =>
      'Da li ste sigurni da želite da obrišete ovaj dokument?';

  @override
  String get uploadMainContract => 'Otpremi ugovor';

  @override
  String get manageDocuments => 'Upravljaj dokumentima';

  @override
  String get monthlyCollected => 'Prikupljeno';

  @override
  String get totalRentShort => 'Kira';

  @override
  String get delays => 'Kašnjenja';

  @override
  String get vacant => 'Slobodno';

  @override
  String propertiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nekretnina',
      one: '$count nekretnina',
    );
    return '$_temp0';
  }

  @override
  String get hasDebt => 'Ima dug';

  @override
  String get paymentAwaitingApproval => 'Čeka odobrenje';

  @override
  String get rent => 'Kirija';

  @override
  String get bills => 'Računi';

  @override
  String get waiting => 'Na čekanju';

  @override
  String get debtLabel => 'Dug';

  @override
  String get paidLabel => 'Plaćeno';

  @override
  String get enterBill => 'Unesi račun';

  @override
  String get addContractAndTenant => 'Dodaj ugovor i zakupca';

  @override
  String get approve => 'Potvrdi';

  @override
  String get reject => 'Odbij';

  @override
  String get confirmApprovePaymentTitle => 'Potvrdi uplatu';

  @override
  String get confirmApprovePaymentMessage =>
      'Da li ste sigurni da želite da potvrdite ovu uplatu?';

  @override
  String get confirmRejectPaymentTitle => 'Odbij uplatu';

  @override
  String get confirmRejectPaymentMessage =>
      'Da li želite da odbijete ovu deklaraciju i tražite od zakupca da je ponovo prijavi?';

  @override
  String get confirm => 'Potvrdi';

  @override
  String get terminateContract => 'Raskini ugovor';

  @override
  String get terminationDate => 'Datum raskida';

  @override
  String get confirmTerminationTitle => 'Raskinuti ugovor?';

  @override
  String get confirmTerminationMessage =>
      'Da li ste sigurni da želite da pošaljete zahtev za raskid ugovora na izabrani datum?';

  @override
  String get terminationRequestSent =>
      'Zahtev za raskid ugovora je uspešno poslat.';

  @override
  String get statusInactive => 'Pasivno / Završeno';

  @override
  String get terminationRequested => 'Čeka se raskid';

  @override
  String get approveTermination => 'Potvrdi raskid';

  @override
  String get declineTermination => 'Odbij raskid';

  @override
  String contractTerminatedOn(Object date) {
    return 'Ugovor je raskinut: $date';
  }

  @override
  String contractWillEndOn(String date) {
    return 'Ugovor će se završiti: $date';
  }

  @override
  String get dispute => 'Ospori';

  @override
  String get disputeReason => 'Razlog osporavanja';

  @override
  String get disputeReasonHint => 'Unesite razlog za osporavanje troška...';

  @override
  String get disputedHeader => 'OSPORENO';

  @override
  String logRentDisputed(String month, String reason) {
    return 'Stanar je osporio uplatu za $month: $reason';
  }

  @override
  String get confirmDisputeTitle => 'Ospori uplatu';

  @override
  String get disputeSentSuccess => 'Vaš prigovor je poslat stanodavcu.';

  @override
  String get takeAction => 'Preduzmi akciju';

  @override
  String get ownerNote => 'Vlasnikova beleška';

  @override
  String get explanationOptional => 'Objašnjenje (Opciono)';

  @override
  String get explanationHint => 'npr. Proverio sam brojilo...';

  @override
  String get units => 'Jedinice';

  @override
  String get tenantsLabel => 'Stanari';

  @override
  String get portfolioManagement => 'Upravljanje portfolijom';

  @override
  String get paymentRequests => 'Plaćanja i zahtevi';

  @override
  String get profileSettings => 'Podešavanja profila';

  @override
  String get confirmSignOutMessage =>
      'Da li ste sigurni da želite da se odjavite?';

  @override
  String errorWithDetails(String error) {
    return 'Greška: $error';
  }

  @override
  String syncError(String error) {
    return 'Greška pri sinhronizaciji: $error';
  }

  @override
  String get acceptTermsWarning =>
      'Molimo prihvatite uslove pre nego što nastavite.';

  @override
  String get maintenanceRequestSuccess =>
      'Zahtev za održavanje je uspešno poslat.';

  @override
  String get ok => 'U redu';

  @override
  String get orLabel => 'ILI';

  @override
  String errorUploadingPhoto(String error) {
    return 'Greška pri otpremanju fotografije: $error';
  }

  @override
  String errorUpdatingStatus(String error) {
    return 'Greška pri ažuriranju statusa: $error';
  }

  @override
  String errorReopeningRequest(String error) {
    return 'Greška pri ponovnom otvaranju zahteva: $error';
  }

  @override
  String errorOpeningDetails(String error) {
    return 'Nije moguće otvoriti detalje: $error';
  }

  @override
  String get nextPayment => 'Sledeća uplata';

  @override
  String get payNow => 'Plati odmah';

  @override
  String get upcomingLabel => 'Predstojeće';

  @override
  String get joinPropertyInvitation => 'Poziv za pridruživanje nekretnini';

  @override
  String get feedbackSent => 'Povratne informacije su poslate';

  @override
  String get rentalProposal => 'Predlog zakupa';

  @override
  String get reviewContractTerms => 'Molimo pregledajte uslove ugovora.';

  @override
  String get expenseDistribution => 'Raspodela troškova';

  @override
  String get yourNote => 'Vaša beleška:';

  @override
  String get backToDashboard => 'Nazad na kontrolnu tablu';

  @override
  String get propertyDetailsHeader => 'DETALJI NEKRETNINE';

  @override
  String get defaultLeaseTermsHeader => 'PODRAZUMEVANI USLOVI ZAKUPA';

  @override
  String get proposeRevision => 'Predloži reviziju';

  @override
  String get revisionTermsQuestion =>
      'Koje uslove želite da promenite? (Zakupnina, dan dospeća, troškovi, itd.)';

  @override
  String get enterNotesHint => 'Unesite svoje beleške ovde...';

  @override
  String get submit => 'Pošalji';

  @override
  String invitedToJoinProperty(String property) {
    return 'Pozvani ste da se pridružite nekretnini $property.';
  }

  @override
  String get waitingForLandlord => 'Čeka se odgovor stanodavca...';

  @override
  String get day => 'Dan';

  @override
  String get notSelected => 'Nije izabrano';

  @override
  String get acceptTermsAndDistribution =>
      'Prihvatam uslove ugovora i raspodelu troškova.';

  @override
  String get datesMandatory => 'Datum početka i završetka su obavezni';

  @override
  String get partiesHeader => 'STRANE';

  @override
  String get leaseLockedWarning =>
      'Postojeći dogovoreni uslovi zakupa (zakupnina, datumi i troškovi) će se primenjivati i na ovog zakupca.';

  @override
  String get rentPaymentHeader => 'ZAKUP I PLAĆANJE';

  @override
  String get loadingPlaceholder => 'Učitavanje...';

  @override
  String get photos => 'Fotografije';

  @override
  String get add => 'Dodaj';

  @override
  String get paymentHistory => 'Istorija plaćanja';

  @override
  String get viewAll => 'Pogledaj sve';

  @override
  String get ended => 'Završeno';

  @override
  String plannedEnd(String date) {
    return 'Planirani završetak: $date';
  }

  @override
  String get yourApartment => 'Vaš stan';

  @override
  String get commentHint => 'Dodajte komentar...';

  @override
  String get issueResolvedStatus => 'Ovaj kvara je označen kao rešen.';

  @override
  String get reopenIssue => 'Još uvek postoji problem (Ponovo otvori)';

  @override
  String get deleteRequest => 'Obriši zahtev';

  @override
  String get terminationApproved => 'Raskid odobren';

  @override
  String get paymentDeclaredHand =>
      'Plaćanje je prijavljeno kao lična dostava.';

  @override
  String get fileUnreadable => 'Nije moguće pročitati datoteku.';

  @override
  String paymentDeclaredSuccess(String title) {
    return 'Uplata $title je prijavljena.';
  }

  @override
  String get setAmountUploadInvoice => 'Podesite iznos i otpremite račun';

  @override
  String get yourMessage => 'Vaša poruka:';

  @override
  String get revisionRequestLabel => 'Zahtev za reviziju:';

  @override
  String get noActivityLogs => 'Još nema prijavljenih aktivnosti';

  @override
  String get landlordProposedChanges =>
      'Stanodavac je predložio izmene ugovora. Dodirnite da pregledate.';

  @override
  String get tenantProposedChanges =>
      'Stanar je predložio izmene ugovora. Dodirnite da pregledate.';

  @override
  String dueOn(String date) {
    return 'Dospeva: $date';
  }

  @override
  String get item => 'stavka';

  @override
  String get items => 'stavke';

  @override
  String get waitingForOtherParty => 'Čeka se odobrenje druge strane...';

  @override
  String get awaitingApproval => 'Čeka se odobrenje...';

  @override
  String get contract => 'Ugovor';

  @override
  String paidOn(Object date) {
    return 'Plaćeno: $date';
  }

  @override
  String get cannotInviteSelf => 'Ne možete pozvati sebe kao stanara.';

  @override
  String get paywallTitle => 'Stanomer Premium';

  @override
  String get paywallSubtitle =>
      'Uklonite ograničenja u upravljanju nekretninama.';

  @override
  String get unlimitedProperties =>
      'Neograničeno dodavanje i upravljanje nekretninama';

  @override
  String get detailedReporting => 'Brže i detaljnije izveštavanje';

  @override
  String get extraStorage => 'Više prostora za skladištenje';

  @override
  String get pdfContracts => 'Generisanje PDF ugovora (Uskoro)';

  @override
  String get automatedRenewal => 'Automatski obračun i obnova kirije (Uskoro)';

  @override
  String get restorePurchases => 'Povrati kupovine';

  @override
  String get limitReachedTitle => 'Dostigli ste besplatni limit';

  @override
  String get limitReachedSubtitle =>
      'Pređite na Stanomer Premium za upravljanje sa više nekretnina.';

  @override
  String get discoverPremium => 'Istražite Premium';

  @override
  String get optionsLoadFailed => 'Nije moguće učitati opcije pretplate.';

  @override
  String get manageSubscription => 'Upravljaj pretplatom';
}

/// The translations for Serbian, using the Cyrillic script (`sr_Cyrl`).
class AppLocalizationsSrCyrl extends AppLocalizationsSr {
  AppLocalizationsSrCyrl() : super('sr_Cyrl');

  @override
  String get appTitle => 'Stanomer';

  @override
  String get login => 'Пријавите се';

  @override
  String get signup => 'Регистрација';

  @override
  String get email => 'Е-пошта';

  @override
  String get password => 'Лозинка';

  @override
  String get landlord => 'Станодавац';

  @override
  String get tenant => 'Станар';

  @override
  String get zzplConsent =>
      'Пристајем на обраду мојих података у складу са Законом о заштити података о личности (ЗЗПЛ) Србије.';

  @override
  String get selectRole => 'Изаберите своју улогу';

  @override
  String get fieldRequired => 'Ово поље је обавезно';

  @override
  String get consentRequired => 'Морате прихватити ЗЗПЛ да бисте наставили';

  @override
  String get loginToAccount => 'Пријавите се на свој налог';

  @override
  String get createAccount => 'Направите нови налог';

  @override
  String get dontHaveAccount => 'Немате налог? Региструјте се';

  @override
  String get alreadyHaveAccount => 'Имате налог? Пријавите се';

  @override
  String get continueWithGoogle => 'Наставите са Google-ом';

  @override
  String get continueWithApple => 'Наставите са Аппле-ом';

  @override
  String get fullName => 'Име и презиме';

  @override
  String get errorSelectRole => 'Молимо изаберите своју улогу';

  @override
  String get deleteAccount => 'Обриши налог';

  @override
  String get deleteAccountWarning =>
      'Ова радња је трајна и не може се поништити. Сви ваши подаци ће бити обрисани.';

  @override
  String get confirmPasswordForDeletion =>
      'Молимо унесите лозинку да потврдите брисање';

  @override
  String get deleteButtonLabel => 'Трајно обриши мој налог';

  @override
  String get cancel => 'Откажи';

  @override
  String get invalidPassword => 'Погрешна лозинка';

  @override
  String get welcomeToStanomer => 'Добродошли у Станомер';

  @override
  String get consentTextFullTitle =>
      'Сагласност за обраду података о личности (ЗЗПЛ)';

  @override
  String get profile => 'Профил';

  @override
  String get updateName => 'Ажурирај име';

  @override
  String get updatePassword => 'Ажурирај лозинку';

  @override
  String get oldPassword => 'Тренутна лозинка';

  @override
  String get newPassword => 'Нова лозинка';

  @override
  String get saveChanges => 'Сачувај измене';

  @override
  String get passwordChangedSuccess => 'Лозинка је успешно промењена';

  @override
  String get profileUpdatedSuccess => 'Профил је успешно ажуриран';

  @override
  String get role => 'Улога';

  @override
  String get roleLandlord => 'Станодавац';

  @override
  String get roleTenant => 'Станар';

  @override
  String get logout => 'Одјави се';

  @override
  String get addProperty => 'Додај некретнину';

  @override
  String get address => 'Адреса';

  @override
  String get monthlyRent => 'Месечна кирија';

  @override
  String get depositAmount => 'Износ депозита';

  @override
  String get currency => 'Валута';

  @override
  String get propertyName => 'Назив некретнине';

  @override
  String get propertyNameHint => 'нпр. Апартман Београд';

  @override
  String get propertyAddedSuccess => 'Некретнина успешно додата';

  @override
  String get propertyUpdatedSuccess => 'Некретнина успешно ажурирана';

  @override
  String get noProperties => 'Нема пронађених некретнина';

  @override
  String get addYourFirstProperty =>
      'Додајте своју прву некретнину да бисте започели праћење!';

  @override
  String get editProperty => 'Уреди некретнину';

  @override
  String get delete => 'Обриши';

  @override
  String get confirmDeleteTitle => 'Обриши некретнину';

  @override
  String get confirmDeleteMessage =>
      'Да ли сте сигурни да желите да обришете ову некретнину? Ова радња се не може поништити.';

  @override
  String get propertyDeletedSuccess => 'Некретнина успешно обрисана';

  @override
  String get inviteTenant => 'Позови станара';

  @override
  String get emailHint => 'Унесите е-маил станара';

  @override
  String get inviteCreatedSuccess =>
      'Линк за позив је креиран! Сада га можете поделити.';

  @override
  String get shareInviteLink => 'Подели линк за позив';

  @override
  String get copyLink => 'Копирај линк';

  @override
  String get noInvitesYet => 'Још увек нема послатих позива';

  @override
  String get cancelInvitation => 'Откажи позив';

  @override
  String get invitationCancelledSuccess => 'Позив је успешно отказан';

  @override
  String get pendingInvite => 'Позив на чекању';

  @override
  String get contractSentToTenant => 'Уговор послат закупцу';

  @override
  String get overview => 'Преглед';

  @override
  String get financials => 'Финансије';

  @override
  String get propertySettings => 'Подешавања';

  @override
  String get invitationHistory => 'Историја позива';

  @override
  String get invitationDetails => 'Детаљи позива';

  @override
  String get acceptInvitation => 'Да, изнајмио сам ово';

  @override
  String get declineInvitation => 'Одбиј позив';

  @override
  String get inviteNotFound => 'Позив није пронађен или је истекао';

  @override
  String get invitationAcceptedSuccess =>
      'Добродошли кући! Позив је прихваћен.';

  @override
  String pendingInvitationBanner(String property) {
    return 'Имате отворен позив за $property';
  }

  @override
  String invitedBy(String name) {
    return 'Позвао вас је $name';
  }

  @override
  String get yourName => 'Ваше име';

  @override
  String get yourNameHint => 'Унесите своје пуно име';

  @override
  String get viewInvite => 'Погледај позив';

  @override
  String get myProperties => 'Моје некретнине';

  @override
  String get tenantEmptyStateTitle => 'Још увек немате додељену некретнину';

  @override
  String get tenantEmptyStateMessage =>
      'Ако вам је станодавац послао позив, он ће се појавити овде. Кликните на дугме испод да бисте проверили нове позиве.';

  @override
  String get refresh => 'Освежи';

  @override
  String get invitationDeclinedSuccess => 'Позив је одбијен.';

  @override
  String get confirmDeclineInviteTitle => 'Одбити позив?';

  @override
  String get confirmDeclineInviteMessage =>
      'Да ли сте сигурни да желите да одбијете овај позив? Биће уклоњен са ваше листе на чекању.';

  @override
  String get contractStartDate => 'Датум почетка уговора';

  @override
  String get contractEndDate => 'Датум завршетка уговора';

  @override
  String get uploadContract => 'Отпреми уговор';

  @override
  String get viewContract => 'Погледај уговор';

  @override
  String get contractFile => 'Датотека уговора';

  @override
  String get selectDate => 'Изабери датум';

  @override
  String get appLanguage => 'Језик апликације';

  @override
  String get english => 'Енглески';

  @override
  String get serbianLatin => 'Српски (Латиница)';

  @override
  String get serbianCyrillic => 'Српски (Ћирилица)';

  @override
  String get turkish => 'Турски';

  @override
  String get tenantMode => 'Мод станара';

  @override
  String get landlordMode => 'Мод станодавца';

  @override
  String get whatAreYou => 'Као шта желите да наставите?';

  @override
  String get selectRoleToContinue =>
      'Изаберите улогу да бисте започели. Можете је променити било када у заглављу изнад.';

  @override
  String get consentTextFullBody =>
      'Коришћењем апликације Станомер, дајете изричиту сагласност за обраду ваших личних података у складу са Законом о заштити података о личности (ЗЗПЛ) Републике Србије.';

  @override
  String get removeTenant => 'Уклони станара';

  @override
  String get removeTenantConfirmation =>
      'Да ли сте сигурни да желите да уклоните овог станара из некретнине? Ово ће раскинути везу и обрисати запис о позиву.';

  @override
  String get remove => 'Уклони';

  @override
  String logRentDeclared(String month) {
    return 'Станар је означио кирију за $month као плаћену.';
  }

  @override
  String logRentApproved(String month) {
    return 'Станодавац је одобрио кирију за $month.';
  }

  @override
  String logRentRejected(String month) {
    return 'Станодавац је одбио кирију за $month.';
  }

  @override
  String logMarkedAsPaid(String month) {
    return 'Станодавац је означио $month као плаћено.';
  }

  @override
  String logMarkedAsPending(String month) {
    return 'Станодавац је означио $month на чекању.';
  }

  @override
  String logAutoApproved(String month) {
    return 'Кирија за $month је аутоматски одобрена од стране система након 5 дана.';
  }

  @override
  String get activity => 'Активности';

  @override
  String get noContractsTitle => 'Још увек нема уговора';

  @override
  String get noContractsMessage =>
      'Да бисте пратили кирију и трошкове, прво позовите станара уношењем детаља уговора.';

  @override
  String get inviteFirstTenant => 'Позовите првог станара';

  @override
  String get confirmCancelInvitationTitle => 'Откажи позив';

  @override
  String get confirmCancelInvitationMessage =>
      'Да ли сте сигурни да желите да повучете овај позив? Ова акција ће га трајно избрисати.';

  @override
  String get confirmDeclineRevisionTitle => 'Одбиј захтев за ревизију';

  @override
  String get confirmDeclineRevisionMessage =>
      'Да ли сте сигурни да желите да одбијете захтев закупца за ревизију? Уговор ће остати на чекању са оригиналним условима.';

  @override
  String get activeContract => 'Активни закуп';

  @override
  String get activeLease => 'АКТИВНИ УГОВОР';

  @override
  String get invitationSent => 'Позив послат';

  @override
  String get accept => 'Прихвати';

  @override
  String get decline => 'Одбиј';

  @override
  String get declineRevisionRequest => 'Одбиј захтев за ревизију';

  @override
  String get pendingHeader => 'НА ЧЕКАЊУ';

  @override
  String get awaitingHeader => 'ЧЕКА ОДОБРЕЊЕ';

  @override
  String get paidHeader => 'ПЛАЋЕНО';

  @override
  String get waitingForTenantPayment => 'Чека уплату станара';

  @override
  String get waitingForYourApproval => 'Чека ваше одобрење';

  @override
  String get waitingForOwnerApproval => 'Чека одобрење станодавца';

  @override
  String get waitingForYourPayment => 'Чека вашу уплату';

  @override
  String get processCompleted => 'Процес завршен';

  @override
  String get declared => 'пријављено';

  @override
  String get sent => 'послато';

  @override
  String get noInvoice => 'Без рачуна';

  @override
  String get uploadInvoice => 'Отпреми рачун';

  @override
  String get awaitingInvoice => 'Чека се рачун';

  @override
  String get updateLabel => 'Ажурирај';

  @override
  String get statusVacant => 'Слободно';

  @override
  String get pendingApproval => 'ЧЕКА ОДОБРЕЊЕ';

  @override
  String get targetRent => 'ЦИЉНА КИРИЈА';

  @override
  String get contractInfo => 'Подаци о уговору';

  @override
  String get term => 'Период';

  @override
  String get dueDay => 'Дан доспећа';

  @override
  String get contractDetails => 'Детаљи уговора';

  @override
  String get pastContracts => 'Прошли уговори';

  @override
  String previousLeasesCount(int count) {
    return '$count претходних уговора';
  }

  @override
  String get propertySettingsLabel => 'Подешавања некретнине';

  @override
  String get propertyActions => 'Акције некретнине';

  @override
  String get leavePropertyConfirm =>
      'Да ли желите да напустите ову некретнину?';

  @override
  String get leaveProperty => 'Напусти некретнину';

  @override
  String get areYouSure => 'Да ли сте сигурни?';

  @override
  String get pendingInvitations => 'Позиви на чекању';

  @override
  String get contractSettings => 'Подешавања уговора';

  @override
  String get activeContractTermsInfo =>
      'Активни услови уговора. Све измене овде ступају на снагу само када се станар и станодавац сложе.';

  @override
  String get dueDayOfMonth => 'Дан доспећа у месецу';

  @override
  String get startDate => 'Датум почетка';

  @override
  String get endDate => 'Датум краја';

  @override
  String get taxConfiguration => 'Конфигурација пореза';

  @override
  String get included => 'Укључено';

  @override
  String get addedVat => 'Додато (+15%)';

  @override
  String get expensesHeader => 'ТРОШКОВИ';

  @override
  String get extraPayment => 'Додатна уплата';

  @override
  String get utility => 'Комунално';

  @override
  String get owner => 'Власник';

  @override
  String proposeChangesInfo(String role) {
    return 'Измене ће бити послате станару на одобрење. Тренутни услови остају на снази до прихватања.';
  }

  @override
  String get proposeChanges => 'Предложи измене';

  @override
  String get declarePayment => 'Пријави уплату';

  @override
  String get uploadReceipt => 'Отпреми уплатницу';

  @override
  String get paidInCash => 'Плаћено готовином';

  @override
  String get noFinancialRecords => 'Још увек нема финансијских записа';

  @override
  String get noActiveContract => 'Није пронађен отпремљени уговор';

  @override
  String get contractTermsInfo =>
      'Активни услови уговора. Све измене овде ступају на снагу само када се станар и станодавац сложе.';

  @override
  String get send => 'Пошаљи';

  @override
  String get totalRent => 'Укупна кирија';

  @override
  String get infoTooltip =>
      'Покрива заједничке комуналне услуге као што су грејање, вода и одвоз смећа.';

  @override
  String get electricityTooltip =>
      'Индивидуални трошкови потрошње електричне енергије.';

  @override
  String get internetTooltip => 'Претплатнички интернет и ТВ пакети.';

  @override
  String get maintenanceTooltip =>
      'Чишћење зграде, одржавање лифта и трошкови заједничких просторија.';

  @override
  String get declare => 'Пријави';

  @override
  String get viewReceipt => 'Види уплатницу';

  @override
  String proposesChanges(String name) {
    return '$name предлаже следеће измене:';
  }

  @override
  String get awaitingApprovalInfo =>
      'Ваш предлог измена чека одобрење друге стране.';

  @override
  String get propertyDetails => 'ДЕТАЉИ НЕКРЕТНИНЕ';

  @override
  String get defaultLeaseTerms => 'ПОДРАЗУМЕВАНИ УСЛОВИ ЗАКУПА';

  @override
  String get defaultLeaseTermsSubtitle =>
      'Услови који се користе као шаблон за нове позиве.';

  @override
  String get invalidNumber => 'Неважећи број';

  @override
  String get enterDayBetween1and31 => 'Унесите дан између 1 и 31';

  @override
  String get expenseConfiguration => 'КОНФИГУРАЦИЈА ТРОШКОВА';

  @override
  String get expenseInfostan => 'Инфостан';

  @override
  String get expenseElectricity => 'Струја (Електрична енергија)';

  @override
  String get expenseInternetTV => 'Интернет/ТВ';

  @override
  String get expenseMaintenance => 'Одржавање зграде';

  @override
  String get expenseTax => 'Порез';

  @override
  String get tenantPaysTo => 'Станар плаћа:';

  @override
  String get fileSelected => 'Фајл изабран';

  @override
  String get selectInvoice => 'Изабери рачун';

  @override
  String get amount => 'Износ';

  @override
  String get setAmountAndUploadInvoice => 'Подесите износ и отпремите рачун';

  @override
  String get save => 'Сачувај';

  @override
  String get paymentDeclared => 'Уплата је успешно пријављена.';

  @override
  String get dashboard => 'Контролна табла';

  @override
  String get parties => 'СТРАНЕ';

  @override
  String get tenantEmail => 'Е-пошта станара';

  @override
  String get existingContractTermsInfo =>
      'Постојећи договорени услови уговора (кирија, датуми и трошкови) важиће и за овог станара.';

  @override
  String get rentAndPayment => 'КИРИЈА И ПЛАЋАЊЕ';

  @override
  String get datesAndContract => 'ДАТУМИ И УГОВОР';

  @override
  String get expenseSettingsHeader => 'ПОДЕШАВАЊЕ ТРОШКОВА';

  @override
  String get editContract => 'Измени уговор';

  @override
  String get sendRevision => 'Пошаљи ревизију';

  @override
  String get revisionSent => 'Предлог ревизије је послат';

  @override
  String get existingFileKept => 'Постојећи фајл је задржан';

  @override
  String get done => 'Готово';

  @override
  String get startAndEndDatesMandatory =>
      'Датум почетка и завршетка су обавезни';

  @override
  String get revisionRequested => 'Тражена ревизија';

  @override
  String get statusActive => 'Активно';

  @override
  String get statusPending => 'Чека одобрење';

  @override
  String get statusDeclined => 'Одбијено';

  @override
  String get statusExpired => 'Истекло';

  @override
  String get statusNegotiating => 'У преговорима';

  @override
  String get tenantPaysLandlord => 'Станар плаћа станодавцу';

  @override
  String get tenantPaysUtility => 'Станар плаћа комуналијама';

  @override
  String get includedInRent => 'Укључено у кирију';

  @override
  String get changesAccepted => 'Промене су прихваћене';

  @override
  String get changesDeclined => 'Промене су одбијене';

  @override
  String get contractChangeProposal => 'Предлог промене уговора';

  @override
  String get cancelProposal => 'Откажи предлог';

  @override
  String get viewInvoice => 'Погледај фактуру';

  @override
  String get paymentResponsibility => 'ОДГОВОРНОСТ ЗА ПЛАЋАЊЕ';

  @override
  String get tenantPaysDirectlyToUtility =>
      'Станар плаћа директно комуналној служби';

  @override
  String get tenantPaysToLandlord => 'Станар плаћа станодавцу';

  @override
  String get selectPaymentReceiverWarning =>
      'Молимо изаберите примаоца уплате пре наставка.';

  @override
  String progressSummary(int completed, int total, int sent) {
    return '$completed / $total плаћено • $sent послато';
  }

  @override
  String get maintenance => 'Одржавање';

  @override
  String get issues => 'Проблеми';

  @override
  String get newRequest => 'Нови захтев';

  @override
  String get reportIssue => 'Пријави квар';

  @override
  String get issueTitle => 'Наслов';

  @override
  String get issueDescription => 'Опис';

  @override
  String get issueCategory => 'Категорија';

  @override
  String get issuePriority => 'Приоритет';

  @override
  String get statusInvestigating => 'На прегледу';

  @override
  String get statusResolved => 'Решено';

  @override
  String get priorityNormal => 'Нормално';

  @override
  String get priorityUrgent => 'Хитно';

  @override
  String get categoryPlumbing => 'Водовод';

  @override
  String get categoryElectrical => 'Електрична енергија';

  @override
  String get categoryHeating => 'Грејање';

  @override
  String get categoryInternet => 'Интернет';

  @override
  String get categoryOther => 'Остало';

  @override
  String get noIssuesTitle => 'Још нема пријављених кварова';

  @override
  String get noIssuesMessage =>
      'Све је у реду! Нема пријављених захтева за одржавање ове имовине.';

  @override
  String get updateStatus => 'Ажурирај статус';

  @override
  String get issueDetails => 'Детаљи квара';

  @override
  String logMaintenanceCreated(String title) {
    return 'Креиран захтев за одржавање: $title';
  }

  @override
  String logMaintenanceStatusUpdated(String status) {
    return 'Статус одржавања ажуриран на $status';
  }

  @override
  String get logMaintenanceReopened => 'Захтев за одржавање поново отворен';

  @override
  String get logMaintenanceMessageAdded =>
      'Додата нова порука захтеву за одржавање';

  @override
  String get notifications => 'Обавештења';

  @override
  String get markAllAsRead => 'Означи све као прочитано';

  @override
  String get noNotifications => 'Још нема обавештења';

  @override
  String get documents => 'Документа';

  @override
  String get mainContract => 'Главни уговор';

  @override
  String get addDocument => 'Додај документ';

  @override
  String get enterDocumentName => 'Унесите назив документа';

  @override
  String get noDocumentsYet => 'Још увек нема докумената';

  @override
  String get additionalDocuments => 'Додатна документа';

  @override
  String get deleteDocument => 'Обриши документ';

  @override
  String get deleteDocumentConfirm =>
      'Да ли сте сигурни да желите да обришете овај документ?';

  @override
  String get uploadMainContract => 'Отпреми уговор';

  @override
  String get manageDocuments => 'Управљај документима';

  @override
  String get monthlyCollected => 'Прикупљено';

  @override
  String get totalRentShort => 'Кирија';

  @override
  String get delays => 'Кашњења';

  @override
  String get vacant => 'Слободно';

  @override
  String propertiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count некретнина',
      one: '$count некретнина',
    );
    return '$_temp0';
  }

  @override
  String get hasDebt => 'Има дуг';

  @override
  String get paymentAwaitingApproval => 'Чека одобрење';

  @override
  String get rent => 'Кирија';

  @override
  String get bills => 'Рачуни';

  @override
  String get waiting => 'На чекању';

  @override
  String get debtLabel => 'Дуг';

  @override
  String get paidLabel => 'Плаћено';

  @override
  String get enterBill => 'Унеси рачун';

  @override
  String get addContractAndTenant => 'Додај уговор и закупца';

  @override
  String get approve => 'Потврди';

  @override
  String get reject => 'Одбиј';

  @override
  String get confirmApprovePaymentTitle => 'Потврди уплату';

  @override
  String get confirmApprovePaymentMessage =>
      'Да ли сте сигурни да желите да потврдите ову уплату?';

  @override
  String get confirmRejectPaymentTitle => 'Одбиј уплату';

  @override
  String get confirmRejectPaymentMessage =>
      'Да ли желите да одбијете ову декларацију и тражите од закупца да је поново пријави?';

  @override
  String get confirm => 'Потврти';

  @override
  String get terminateContract => 'Раскини уговор';

  @override
  String get terminationDate => 'Датум раскида';

  @override
  String get confirmTerminationTitle => 'Раскинути уговор?';

  @override
  String get confirmTerminationMessage =>
      'Да ли сте сигурни да желите да пошаљете захтев за раскид уговора на изабрани датум?';

  @override
  String get terminationRequestSent =>
      'Захтев за раскид уговора је успешно послат.';

  @override
  String get statusInactive => 'Пасивно / Завршено';

  @override
  String get terminationRequested => 'Чека се раскид';

  @override
  String get approveTermination => 'Потврди раскид';

  @override
  String get declineTermination => 'Одбиј раскид';

  @override
  String contractTerminatedOn(Object date) {
    return 'Уговор је раскинут: $date';
  }

  @override
  String contractWillEndOn(String date) {
    return 'Уговор ће се завршити: $date';
  }

  @override
  String get dispute => 'Оспори';

  @override
  String get disputeReason => 'Разлог оспоравања';

  @override
  String get disputeReasonHint => 'Унесите разлог за оспоравање трошка...';

  @override
  String get disputedHeader => 'ОСПОРЕНО';

  @override
  String logRentDisputed(String month, String reason) {
    return 'Станар је оспорио уплату за $month: $reason';
  }

  @override
  String get confirmDisputeTitle => 'Оспори уплату';

  @override
  String get disputeSentSuccess => 'Ваш приговор је послат станодавцу.';

  @override
  String get takeAction => 'Предузми акцију';

  @override
  String get ownerNote => 'Власникова белешка';

  @override
  String get explanationOptional => 'Објашњење (Опционо)';

  @override
  String get explanationHint => 'нпр. Проверио сам бројило...';

  @override
  String get units => 'Јединице';

  @override
  String get tenantsLabel => 'Станари';

  @override
  String get portfolioManagement => 'Управљање портфолијом';

  @override
  String get paymentRequests => 'Плаћања и захтеви';

  @override
  String get profileSettings => 'Подешавања профила';

  @override
  String get confirmSignOutMessage =>
      'Да ли сте сигурни да желите да се одјавите?';

  @override
  String errorWithDetails(String error) {
    return 'Грешка: $error';
  }

  @override
  String syncError(String error) {
    return 'Грешка при синхронизацији: $error';
  }

  @override
  String get acceptTermsWarning =>
      'Молимо прихватите услове пре него што наставите.';

  @override
  String get maintenanceRequestSuccess =>
      'Захтев за одржавање је успешно послат.';

  @override
  String get ok => 'У реду';

  @override
  String get orLabel => 'ИЛИ';

  @override
  String errorUploadingPhoto(String error) {
    return 'Грешка при отпремању фотографије: $error';
  }

  @override
  String errorUpdatingStatus(String error) {
    return 'Грешка при ажурирању статуса: $error';
  }

  @override
  String errorReopeningRequest(String error) {
    return 'Грешка при поновном отварању захтева: $error';
  }

  @override
  String errorOpeningDetails(String error) {
    return 'Није могуће отворити детаље: $error';
  }

  @override
  String get nextPayment => 'Следећа уплата';

  @override
  String get payNow => 'Плати одмах';

  @override
  String get upcomingLabel => 'Предстојеће';

  @override
  String get joinPropertyInvitation => 'Позив за придруживање некретнини';

  @override
  String get feedbackSent => 'Повратне информације су послате';

  @override
  String get rentalProposal => 'Предлог закупа';

  @override
  String get reviewContractTerms => 'Молимо прегледајте услове уговора.';

  @override
  String get expenseDistribution => 'Расподела трошкова';

  @override
  String get yourNote => 'Ваша белешка:';

  @override
  String get backToDashboard => 'Назад на контролну таблу';

  @override
  String get propertyDetailsHeader => 'ДЕТАЉИ НЕКРЕТНИНЕ';

  @override
  String get defaultLeaseTermsHeader => 'ПОДРАЗУМЕВАНИ УСЛОВИ ЗАКУПА';

  @override
  String get proposeRevision => 'Предложи ревизију';

  @override
  String get revisionTermsQuestion =>
      'Које услове желите да промените? (Закупнина, дан доспећа, трошкови, итд.)';

  @override
  String get enterNotesHint => 'Унесите своје белешке овде...';

  @override
  String get submit => 'Пошаљи';

  @override
  String invitedToJoinProperty(String property) {
    return 'Позвани сте да се придружите некретнини $property.';
  }

  @override
  String get waitingForLandlord => 'Чека се одговор станодавца...';

  @override
  String get day => 'Дан';

  @override
  String get notSelected => 'Није изабрано';

  @override
  String get acceptTermsAndDistribution =>
      'Прихватам услове уговора и расподелу трошкова.';

  @override
  String get datesMandatory => 'Датум почетка и завршетка су обавезни';

  @override
  String get partiesHeader => 'СТРАНЕ';

  @override
  String get leaseLockedWarning =>
      'Постојећи договорени услови закупа (закупнина, датуми и трошкови) ће се примењивати и на овог закупца.';

  @override
  String get rentPaymentHeader => 'ЗАКУП И ПЛАЋАЊЕ';

  @override
  String get loadingPlaceholder => 'Учитавање...';

  @override
  String get photos => 'Фотографије';

  @override
  String get add => 'Додај';

  @override
  String get paymentHistory => 'Историја плаћања';

  @override
  String get viewAll => 'Погледај све';

  @override
  String get ended => 'Завршено';

  @override
  String plannedEnd(String date) {
    return 'Планирани завршетак: $date';
  }

  @override
  String get yourApartment => 'Ваш стан';

  @override
  String get commentHint => 'Додајте коментар...';

  @override
  String get issueResolvedStatus => 'Овај квара је означен као решен.';

  @override
  String get reopenIssue => 'Још увек постоји проблем (Поново отвори)';

  @override
  String get deleteRequest => 'Обриши захтев';

  @override
  String get terminationApproved => 'Раскид одобрен';

  @override
  String get paymentDeclaredHand => 'Плаћање је пријављено као лична достава.';

  @override
  String get fileUnreadable => 'Није могуће прочитати датотеку.';

  @override
  String paymentDeclaredSuccess(String title) {
    return 'Уплата $title је пријављена.';
  }

  @override
  String get setAmountUploadInvoice => 'Подесите износ и отпремите рачун';

  @override
  String get yourMessage => 'Ваша порука:';

  @override
  String get revisionRequestLabel => 'Захтев за ревизију:';

  @override
  String get noActivityLogs => 'Још нема пријављених активности';

  @override
  String get landlordProposedChanges =>
      'Станодавац је предложио измене уговора. Додирните да прегледате.';

  @override
  String get tenantProposedChanges =>
      'Станар је предложио измене уговора. Додирните да прегледате.';

  @override
  String dueOn(String date) {
    return 'Доспева: $date';
  }

  @override
  String get item => 'ставка';

  @override
  String get items => 'ставке';

  @override
  String get waitingForOtherParty => 'Чека се одобрење друге стране...';

  @override
  String get awaitingApproval => 'Чека се одобрење...';

  @override
  String get contract => 'Уговор';

  @override
  String paidOn(Object date) {
    return 'Плаћено: $date';
  }

  @override
  String get cannotInviteSelf => 'Не можете позвати себе као станара.';

  @override
  String get paywallTitle => 'Stanomer Premium';

  @override
  String get paywallSubtitle => 'Уклоните ограничења у управљању некретнинама.';

  @override
  String get unlimitedProperties =>
      'Неограничено додавање и управљање некретнинама';

  @override
  String get detailedReporting => 'Брже и детаљније извештавање';

  @override
  String get extraStorage => 'Више простора за складиштење';

  @override
  String get pdfContracts => 'Генерисање ПДФ уговора (Ускоро)';

  @override
  String get automatedRenewal => 'Аутоматски обрачун и обнова кирије (Ускоро)';

  @override
  String get restorePurchases => 'Поврати куповине';

  @override
  String get limitReachedTitle => 'Достигли сте бесплатни лимит';

  @override
  String get limitReachedSubtitle =>
      'Пређите на Stanomer Premium за управљање са више некретнина.';

  @override
  String get discoverPremium => 'Истражите Premium';

  @override
  String get optionsLoadFailed => 'Није могуће учитати опције претплате.';

  @override
  String get manageSubscription => 'Управљај претплатом';
}
