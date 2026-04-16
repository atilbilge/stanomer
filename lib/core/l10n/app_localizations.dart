import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sr.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sr'),
    Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In sr, this message translates to:
  /// **'Stanomer'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In sr, this message translates to:
  /// **'Prijavite se'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In sr, this message translates to:
  /// **'Registracija'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In sr, this message translates to:
  /// **'E-pošta'**
  String get email;

  /// No description provided for @password.
  ///
  /// In sr, this message translates to:
  /// **'Lozinka'**
  String get password;

  /// No description provided for @landlord.
  ///
  /// In sr, this message translates to:
  /// **'Stanodavac'**
  String get landlord;

  /// No description provided for @tenant.
  ///
  /// In sr, this message translates to:
  /// **'Stanar'**
  String get tenant;

  /// No description provided for @zzplConsent.
  ///
  /// In sr, this message translates to:
  /// **'Pristajem na obradu mojih podataka u skladu sa Zakonom o zaštiti podataka o ličnosti (ZZPL) Srbije.'**
  String get zzplConsent;

  /// No description provided for @selectRole.
  ///
  /// In sr, this message translates to:
  /// **'Izaberite svoju ulogu'**
  String get selectRole;

  /// No description provided for @fieldRequired.
  ///
  /// In sr, this message translates to:
  /// **'Ovo polje je obavezno'**
  String get fieldRequired;

  /// No description provided for @consentRequired.
  ///
  /// In sr, this message translates to:
  /// **'Morate prihvatiti ZZPL da biste nastavili'**
  String get consentRequired;

  /// No description provided for @loginToAccount.
  ///
  /// In sr, this message translates to:
  /// **'Prijavite se na svoj nalog'**
  String get loginToAccount;

  /// No description provided for @createAccount.
  ///
  /// In sr, this message translates to:
  /// **'Napravite novi nalog'**
  String get createAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In sr, this message translates to:
  /// **'Nemate nalog? Registrujte se'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In sr, this message translates to:
  /// **'Imate nalog? Prijavite se'**
  String get alreadyHaveAccount;

  /// No description provided for @continueWithGoogle.
  ///
  /// In sr, this message translates to:
  /// **'Nastavite sa Google-om'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In sr, this message translates to:
  /// **'Nastavite sa Apple-om'**
  String get continueWithApple;

  /// No description provided for @fullName.
  ///
  /// In sr, this message translates to:
  /// **'Ime i prezime'**
  String get fullName;

  /// No description provided for @errorSelectRole.
  ///
  /// In sr, this message translates to:
  /// **'Molimo izaberite svoju ulogu'**
  String get errorSelectRole;

  /// No description provided for @deleteAccount.
  ///
  /// In sr, this message translates to:
  /// **'Obriši nalog'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In sr, this message translates to:
  /// **'Ova radnja je trajna i ne može se poništiti. Svi vaši podaci će biti obrisani.'**
  String get deleteAccountWarning;

  /// No description provided for @confirmPasswordForDeletion.
  ///
  /// In sr, this message translates to:
  /// **'Molimo unesite lozinku da potvrdite brisanje'**
  String get confirmPasswordForDeletion;

  /// No description provided for @deleteButtonLabel.
  ///
  /// In sr, this message translates to:
  /// **'Trajno obriši moj nalog'**
  String get deleteButtonLabel;

  /// No description provided for @cancel.
  ///
  /// In sr, this message translates to:
  /// **'Otkaži'**
  String get cancel;

  /// No description provided for @invalidPassword.
  ///
  /// In sr, this message translates to:
  /// **'Pogrešna lozinka'**
  String get invalidPassword;

  /// No description provided for @welcomeToStanomer.
  ///
  /// In sr, this message translates to:
  /// **'Dobrodošli u Stanomer'**
  String get welcomeToStanomer;

  /// No description provided for @consentTextFullTitle.
  ///
  /// In sr, this message translates to:
  /// **'Saglasnost za obradu podataka o ličnosti (ZZPL)'**
  String get consentTextFullTitle;

  /// No description provided for @profile.
  ///
  /// In sr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @updateName.
  ///
  /// In sr, this message translates to:
  /// **'Ažuriraj ime'**
  String get updateName;

  /// No description provided for @updatePassword.
  ///
  /// In sr, this message translates to:
  /// **'Ažuriraj lozinku'**
  String get updatePassword;

  /// No description provided for @oldPassword.
  ///
  /// In sr, this message translates to:
  /// **'Trenutna lozinka'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In sr, this message translates to:
  /// **'Nova lozinka'**
  String get newPassword;

  /// No description provided for @saveChanges.
  ///
  /// In sr, this message translates to:
  /// **'Sačuvaj izmene'**
  String get saveChanges;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Lozinka je uspešno promenjena'**
  String get passwordChangedSuccess;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Profil je uspešno ažuriran'**
  String get profileUpdatedSuccess;

  /// No description provided for @role.
  ///
  /// In sr, this message translates to:
  /// **'Uloga'**
  String get role;

  /// No description provided for @roleLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Stanodavac'**
  String get roleLandlord;

  /// No description provided for @roleTenant.
  ///
  /// In sr, this message translates to:
  /// **'Stanar'**
  String get roleTenant;

  /// No description provided for @logout.
  ///
  /// In sr, this message translates to:
  /// **'Odjavi se'**
  String get logout;

  /// No description provided for @addProperty.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj nekretninu'**
  String get addProperty;

  /// No description provided for @address.
  ///
  /// In sr, this message translates to:
  /// **'Adresa'**
  String get address;

  /// No description provided for @monthlyRent.
  ///
  /// In sr, this message translates to:
  /// **'Mesečna kirija'**
  String get monthlyRent;

  /// No description provided for @depositAmount.
  ///
  /// In sr, this message translates to:
  /// **'Iznos depozita'**
  String get depositAmount;

  /// No description provided for @currency.
  ///
  /// In sr, this message translates to:
  /// **'Valuta'**
  String get currency;

  /// No description provided for @propertyName.
  ///
  /// In sr, this message translates to:
  /// **'Naziv nekretnine'**
  String get propertyName;

  /// No description provided for @propertyNameHint.
  ///
  /// In sr, this message translates to:
  /// **'npr. Apartman Beograd'**
  String get propertyNameHint;

  /// No description provided for @propertyAddedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Nekretnina uspešno dodata'**
  String get propertyAddedSuccess;

  /// No description provided for @propertyUpdatedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Nekretnina uspešno ažurirana'**
  String get propertyUpdatedSuccess;

  /// No description provided for @noProperties.
  ///
  /// In sr, this message translates to:
  /// **'Nema pronađenih nekretnina'**
  String get noProperties;

  /// No description provided for @addYourFirstProperty.
  ///
  /// In sr, this message translates to:
  /// **'Dodajte svoju prvu nekretninu da biste започели praćenje!'**
  String get addYourFirstProperty;

  /// No description provided for @editProperty.
  ///
  /// In sr, this message translates to:
  /// **'Uredi nekretninu'**
  String get editProperty;

  /// No description provided for @delete.
  ///
  /// In sr, this message translates to:
  /// **'Obriši'**
  String get delete;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In sr, this message translates to:
  /// **'Obriši nekretninu'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni da želite da obrišete ovu nekretninu? Ova radnja se ne može poništiti.'**
  String get confirmDeleteMessage;

  /// No description provided for @propertyDeletedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Nekretnina uspešno obrisana'**
  String get propertyDeletedSuccess;

  /// No description provided for @inviteTenant.
  ///
  /// In sr, this message translates to:
  /// **'Pozovi stanara'**
  String get inviteTenant;

  /// No description provided for @emailHint.
  ///
  /// In sr, this message translates to:
  /// **'Unesite e-mail stanara'**
  String get emailHint;

  /// No description provided for @inviteCreatedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Link za poziv je kreiran! Sada ga možete podeliti.'**
  String get inviteCreatedSuccess;

  /// No description provided for @shareInviteLink.
  ///
  /// In sr, this message translates to:
  /// **'Podeli link za poziv'**
  String get shareInviteLink;

  /// No description provided for @copyLink.
  ///
  /// In sr, this message translates to:
  /// **'Kopiraj link'**
  String get copyLink;

  /// No description provided for @noInvitesYet.
  ///
  /// In sr, this message translates to:
  /// **'Još uvek nema poslatih poziva'**
  String get noInvitesYet;

  /// No description provided for @cancelInvitation.
  ///
  /// In sr, this message translates to:
  /// **'Otkaži poziv'**
  String get cancelInvitation;

  /// No description provided for @invitationCancelledSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Poziv je uspešno otkazan'**
  String get invitationCancelledSuccess;

  /// No description provided for @pendingInvite.
  ///
  /// In sr, this message translates to:
  /// **'Poziv na čekanju'**
  String get pendingInvite;

  /// No description provided for @contractSentToTenant.
  ///
  /// In sr, this message translates to:
  /// **'Ugovor poslat zakupcu'**
  String get contractSentToTenant;

  /// No description provided for @overview.
  ///
  /// In sr, this message translates to:
  /// **'Pregled'**
  String get overview;

  /// No description provided for @financials.
  ///
  /// In sr, this message translates to:
  /// **'Finansije'**
  String get financials;

  /// No description provided for @propertySettings.
  ///
  /// In sr, this message translates to:
  /// **'Podešavanja'**
  String get propertySettings;

  /// No description provided for @invitationHistory.
  ///
  /// In sr, this message translates to:
  /// **'Istorija poziva'**
  String get invitationHistory;

  /// No description provided for @invitationDetails.
  ///
  /// In sr, this message translates to:
  /// **'Detalji poziva'**
  String get invitationDetails;

  /// No description provided for @acceptInvitation.
  ///
  /// In sr, this message translates to:
  /// **'Da, iznajmio sam ovo'**
  String get acceptInvitation;

  /// No description provided for @declineInvitation.
  ///
  /// In sr, this message translates to:
  /// **'Odbij poziv'**
  String get declineInvitation;

  /// No description provided for @inviteNotFound.
  ///
  /// In sr, this message translates to:
  /// **'Poziv nije pronađen ili je istekao'**
  String get inviteNotFound;

  /// No description provided for @invitationAcceptedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Dobrodošli kući! Poziv je prihvaćen.'**
  String get invitationAcceptedSuccess;

  /// No description provided for @pendingInvitationBanner.
  ///
  /// In sr, this message translates to:
  /// **'Imate otvoren poziv za {property}'**
  String pendingInvitationBanner(String property);

  /// No description provided for @invitedBy.
  ///
  /// In sr, this message translates to:
  /// **'Pozvao vas je {name}'**
  String invitedBy(String name);

  /// No description provided for @yourName.
  ///
  /// In sr, this message translates to:
  /// **'Vaše ime'**
  String get yourName;

  /// No description provided for @yourNameHint.
  ///
  /// In sr, this message translates to:
  /// **'Unesite svoje puno ime'**
  String get yourNameHint;

  /// No description provided for @viewInvite.
  ///
  /// In sr, this message translates to:
  /// **'Pogledaj poziv'**
  String get viewInvite;

  /// No description provided for @myProperties.
  ///
  /// In sr, this message translates to:
  /// **'Moje nekretnine'**
  String get myProperties;

  /// No description provided for @tenantEmptyStateTitle.
  ///
  /// In sr, this message translates to:
  /// **'Još uvek nemate dodeljenu nekretninu'**
  String get tenantEmptyStateTitle;

  /// No description provided for @tenantEmptyStateMessage.
  ///
  /// In sr, this message translates to:
  /// **'Ako vam je stanodavac poslao poziv, on će se pojaviti ovde. Kliknite na dugme ispod da biste proverili nove pozive.'**
  String get tenantEmptyStateMessage;

  /// No description provided for @refresh.
  ///
  /// In sr, this message translates to:
  /// **'Osveži'**
  String get refresh;

  /// No description provided for @invitationDeclinedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Poziv je odbijen.'**
  String get invitationDeclinedSuccess;

  /// No description provided for @confirmDeclineInviteTitle.
  ///
  /// In sr, this message translates to:
  /// **'Odbiti poziv?'**
  String get confirmDeclineInviteTitle;

  /// No description provided for @confirmDeclineInviteMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni da želite da odbijete ovaj poziv? Biće uklonjen sa vaše liste na čekanju.'**
  String get confirmDeclineInviteMessage;

  /// No description provided for @contractStartDate.
  ///
  /// In sr, this message translates to:
  /// **'Datum početka ugovora'**
  String get contractStartDate;

  /// No description provided for @contractEndDate.
  ///
  /// In sr, this message translates to:
  /// **'Datum završetka ugovora'**
  String get contractEndDate;

  /// No description provided for @uploadContract.
  ///
  /// In sr, this message translates to:
  /// **'Otpremi ugovor'**
  String get uploadContract;

  /// No description provided for @viewContract.
  ///
  /// In sr, this message translates to:
  /// **'Pogledaj ugovor'**
  String get viewContract;

  /// No description provided for @contractFile.
  ///
  /// In sr, this message translates to:
  /// **'Datoteka ugovora'**
  String get contractFile;

  /// No description provided for @selectDate.
  ///
  /// In sr, this message translates to:
  /// **'Izaberi datum'**
  String get selectDate;

  /// No description provided for @appLanguage.
  ///
  /// In sr, this message translates to:
  /// **'Jezik aplikacije'**
  String get appLanguage;

  /// No description provided for @english.
  ///
  /// In sr, this message translates to:
  /// **'Engleski'**
  String get english;

  /// No description provided for @serbianLatin.
  ///
  /// In sr, this message translates to:
  /// **'Srpski (Latinica)'**
  String get serbianLatin;

  /// No description provided for @serbianCyrillic.
  ///
  /// In sr, this message translates to:
  /// **'Srpski (Ćirilica)'**
  String get serbianCyrillic;

  /// No description provided for @turkish.
  ///
  /// In sr, this message translates to:
  /// **'Turski'**
  String get turkish;

  /// No description provided for @tenantMode.
  ///
  /// In sr, this message translates to:
  /// **'Mod stanara'**
  String get tenantMode;

  /// No description provided for @landlordMode.
  ///
  /// In sr, this message translates to:
  /// **'Mod stanodavca'**
  String get landlordMode;

  /// No description provided for @whatAreYou.
  ///
  /// In sr, this message translates to:
  /// **'Kao šta želite da nastavite?'**
  String get whatAreYou;

  /// No description provided for @selectRoleToContinue.
  ///
  /// In sr, this message translates to:
  /// **'Izaberite ulogu da biste započeli. Možete je promeniti bilo kada u zaglavlju iznad.'**
  String get selectRoleToContinue;

  /// No description provided for @consentTextFullBody.
  ///
  /// In sr, this message translates to:
  /// **'Korišćenjem aplikacije Stanomer, dajete izričitu saglasnost za obradu vaših ličnih podataka u skladu sa Zakonom o zaštiti podataka o ličnosti (ZZPL) Republike Srbije.'**
  String get consentTextFullBody;

  /// No description provided for @removeTenant.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni stanara'**
  String get removeTenant;

  /// No description provided for @removeTenantConfirmation.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni da želite da uklonite ovog stanara iz nekretnine? Ovo će raskinuti vezu i obrisati zapis o pozivu.'**
  String get removeTenantConfirmation;

  /// No description provided for @remove.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni'**
  String get remove;

  /// No description provided for @logRentDeclared.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je označio kiriju za {month} kao plaćenu.'**
  String logRentDeclared(String month);

  /// No description provided for @logRentApproved.
  ///
  /// In sr, this message translates to:
  /// **'Stanodavac je odobrio kiriju za {month}.'**
  String logRentApproved(String month);

  /// No description provided for @logRentRejected.
  ///
  /// In sr, this message translates to:
  /// **'Stanodavac je odbio kiriju za {month}.'**
  String logRentRejected(String month);

  /// No description provided for @logMarkedAsPaid.
  ///
  /// In sr, this message translates to:
  /// **'Stanodavac je označio {month} kao plaćeno.'**
  String logMarkedAsPaid(String month);

  /// No description provided for @logMarkedAsPending.
  ///
  /// In sr, this message translates to:
  /// **'Stanodavac je označio {month} na čekanju.'**
  String logMarkedAsPending(String month);

  /// No description provided for @logAutoApproved.
  ///
  /// In sr, this message translates to:
  /// **'Kirija za {month} je automatski odobrena od strane sistema nakon 5 dana.'**
  String logAutoApproved(String month);

  /// No description provided for @activity.
  ///
  /// In sr, this message translates to:
  /// **'Aktivnosti'**
  String get activity;

  /// No description provided for @noContractsTitle.
  ///
  /// In sr, this message translates to:
  /// **'Još uvek nema ugovora'**
  String get noContractsTitle;

  /// No description provided for @noContractsMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da biste pratili kiriju i troškove, prvo pozovite stanara unošenjem detalja ugovora.'**
  String get noContractsMessage;

  /// No description provided for @inviteFirstTenant.
  ///
  /// In sr, this message translates to:
  /// **'Pozovite prvog zakupca'**
  String get inviteFirstTenant;

  /// No description provided for @confirmCancelInvitationTitle.
  ///
  /// In sr, this message translates to:
  /// **'Otkaži poziv'**
  String get confirmCancelInvitationTitle;

  /// No description provided for @confirmCancelInvitationMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni da želite da povučete ovaj poziv? Ova akcija će ga trajno izbrisati.'**
  String get confirmCancelInvitationMessage;

  /// No description provided for @confirmDeclineRevisionTitle.
  ///
  /// In sr, this message translates to:
  /// **'Odbij zahtev za reviziju'**
  String get confirmDeclineRevisionTitle;

  /// No description provided for @confirmDeclineRevisionMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni da želite da odbijete zahtev zakupca za reviziju? Ugovor će ostati na čekanju sa originalnim uslovima.'**
  String get confirmDeclineRevisionMessage;

  /// No description provided for @activeContract.
  ///
  /// In sr, this message translates to:
  /// **'Aktivni ugovor'**
  String get activeContract;

  /// No description provided for @activeLease.
  ///
  /// In sr, this message translates to:
  /// **'AKTIVNI UGOVOR'**
  String get activeLease;

  /// No description provided for @invitationSent.
  ///
  /// In sr, this message translates to:
  /// **'Poziv poslat'**
  String get invitationSent;

  /// No description provided for @accept.
  ///
  /// In sr, this message translates to:
  /// **'Prihvati'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In sr, this message translates to:
  /// **'Odbij'**
  String get decline;

  /// No description provided for @declineRevisionRequest.
  ///
  /// In sr, this message translates to:
  /// **'Odbij zahtev za reviziju'**
  String get declineRevisionRequest;

  /// No description provided for @pendingHeader.
  ///
  /// In sr, this message translates to:
  /// **'NA ČEKANJU'**
  String get pendingHeader;

  /// No description provided for @awaitingHeader.
  ///
  /// In sr, this message translates to:
  /// **'ČEKA ODOBRENJE'**
  String get awaitingHeader;

  /// No description provided for @paidHeader.
  ///
  /// In sr, this message translates to:
  /// **'PLAĆENO'**
  String get paidHeader;

  /// No description provided for @waitingForTenantPayment.
  ///
  /// In sr, this message translates to:
  /// **'Čeka uplatu stanara'**
  String get waitingForTenantPayment;

  /// No description provided for @waitingForYourApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka vaše odobrenje'**
  String get waitingForYourApproval;

  /// No description provided for @waitingForOwnerApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka odobrenje stanodavca'**
  String get waitingForOwnerApproval;

  /// No description provided for @waitingForYourPayment.
  ///
  /// In sr, this message translates to:
  /// **'Čeka vašu uplatu'**
  String get waitingForYourPayment;

  /// No description provided for @processCompleted.
  ///
  /// In sr, this message translates to:
  /// **'Proces završen'**
  String get processCompleted;

  /// No description provided for @declared.
  ///
  /// In sr, this message translates to:
  /// **'prijavljeno'**
  String get declared;

  /// No description provided for @sent.
  ///
  /// In sr, this message translates to:
  /// **'poslato'**
  String get sent;

  /// No description provided for @noInvoice.
  ///
  /// In sr, this message translates to:
  /// **'Bez računa'**
  String get noInvoice;

  /// No description provided for @uploadInvoice.
  ///
  /// In sr, this message translates to:
  /// **'Otpremi račun'**
  String get uploadInvoice;

  /// No description provided for @awaitingInvoice.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se račun'**
  String get awaitingInvoice;

  /// No description provided for @updateLabel.
  ///
  /// In sr, this message translates to:
  /// **'Ažuriraj'**
  String get updateLabel;

  /// No description provided for @statusVacant.
  ///
  /// In sr, this message translates to:
  /// **'Slobodno'**
  String get statusVacant;

  /// No description provided for @pendingApproval.
  ///
  /// In sr, this message translates to:
  /// **'ČEKA ODOBRENJE'**
  String get pendingApproval;

  /// No description provided for @targetRent.
  ///
  /// In sr, this message translates to:
  /// **'CILJNA KIRIJA'**
  String get targetRent;

  /// No description provided for @contractInfo.
  ///
  /// In sr, this message translates to:
  /// **'Podaci o ugovoru'**
  String get contractInfo;

  /// No description provided for @term.
  ///
  /// In sr, this message translates to:
  /// **'Period'**
  String get term;

  /// No description provided for @dueDay.
  ///
  /// In sr, this message translates to:
  /// **'Dan dospeća'**
  String get dueDay;

  /// No description provided for @contractDetails.
  ///
  /// In sr, this message translates to:
  /// **'Detalji ugovora'**
  String get contractDetails;

  /// No description provided for @pastContracts.
  ///
  /// In sr, this message translates to:
  /// **'Prošli ugovori'**
  String get pastContracts;

  /// No description provided for @previousLeasesCount.
  ///
  /// In sr, this message translates to:
  /// **'{count} prethodnih ugovora'**
  String previousLeasesCount(int count);

  /// No description provided for @propertySettingsLabel.
  ///
  /// In sr, this message translates to:
  /// **'Podešavanja nekretnine'**
  String get propertySettingsLabel;

  /// No description provided for @propertyActions.
  ///
  /// In sr, this message translates to:
  /// **'Akcije nekretnine'**
  String get propertyActions;

  /// No description provided for @leavePropertyConfirm.
  ///
  /// In sr, this message translates to:
  /// **'Da li želite da napustite ovu nekretninu?'**
  String get leavePropertyConfirm;

  /// No description provided for @leaveProperty.
  ///
  /// In sr, this message translates to:
  /// **'Napusti nekretninu'**
  String get leaveProperty;

  /// No description provided for @areYouSure.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni?'**
  String get areYouSure;

  /// No description provided for @pendingInvitations.
  ///
  /// In sr, this message translates to:
  /// **'Pozivi na čekanju'**
  String get pendingInvitations;

  /// No description provided for @contractSettings.
  ///
  /// In sr, this message translates to:
  /// **'Podešavanja ugovora'**
  String get contractSettings;

  /// No description provided for @activeContractTermsInfo.
  ///
  /// In sr, this message translates to:
  /// **'Aktivni uslovi ugovora. Sve izmene ovde stupaju na snagu samo kada se stanar i stanodavac slože.'**
  String get activeContractTermsInfo;

  /// No description provided for @dueDayOfMonth.
  ///
  /// In sr, this message translates to:
  /// **'Dan dospeća u mesecu'**
  String get dueDayOfMonth;

  /// No description provided for @startDate.
  ///
  /// In sr, this message translates to:
  /// **'Datum početka'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In sr, this message translates to:
  /// **'Datum kraja'**
  String get endDate;

  /// No description provided for @taxConfiguration.
  ///
  /// In sr, this message translates to:
  /// **'Konfiguracija poreza'**
  String get taxConfiguration;

  /// No description provided for @included.
  ///
  /// In sr, this message translates to:
  /// **'Uključeno'**
  String get included;

  /// No description provided for @addedVat.
  ///
  /// In sr, this message translates to:
  /// **'Dodato (+15%)'**
  String get addedVat;

  /// No description provided for @expensesHeader.
  ///
  /// In sr, this message translates to:
  /// **'TROŠKOVI'**
  String get expensesHeader;

  /// No description provided for @extraPayment.
  ///
  /// In sr, this message translates to:
  /// **'Dodatna uplata'**
  String get extraPayment;

  /// No description provided for @utility.
  ///
  /// In sr, this message translates to:
  /// **'Komunalno'**
  String get utility;

  /// No description provided for @owner.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik'**
  String get owner;

  /// No description provided for @proposeChangesInfo.
  ///
  /// In sr, this message translates to:
  /// **'Izmene će biti poslate {role} na odobrenje. Trenutni uslovi ostaju na snazi do prihvatanja.'**
  String proposeChangesInfo(String role);

  /// No description provided for @proposeChanges.
  ///
  /// In sr, this message translates to:
  /// **'Predloži izmene'**
  String get proposeChanges;

  /// No description provided for @declarePayment.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi uplatu'**
  String get declarePayment;

  /// No description provided for @uploadReceipt.
  ///
  /// In sr, this message translates to:
  /// **'Otpremi uplatnicu'**
  String get uploadReceipt;

  /// No description provided for @paidInCash.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeno gotovinom'**
  String get paidInCash;

  /// No description provided for @noFinancialRecords.
  ///
  /// In sr, this message translates to:
  /// **'Još uvek nema finansijskih zapisa'**
  String get noFinancialRecords;

  /// No description provided for @noActiveContract.
  ///
  /// In sr, this message translates to:
  /// **'Nije pronađen otpremljeni ugovor'**
  String get noActiveContract;

  /// No description provided for @contractTermsInfo.
  ///
  /// In sr, this message translates to:
  /// **'Aktivni uslovi ugovora. Sve izmene ovde stupaju na snagu samo kada se stanar i stanodavac slože.'**
  String get contractTermsInfo;

  /// No description provided for @send.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji'**
  String get send;

  /// No description provided for @totalRent.
  ///
  /// In sr, this message translates to:
  /// **'Ukupna kirija'**
  String get totalRent;

  /// No description provided for @infoTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Pokriva zajedničke komunalne usluge kao što su grejanje, voda i odvoz smeća.'**
  String get infoTooltip;

  /// No description provided for @electricityTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Individualni troškovi potrošnje električne energije.'**
  String get electricityTooltip;

  /// No description provided for @internetTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Pretplatnički internet i TV paketi.'**
  String get internetTooltip;

  /// No description provided for @maintenanceTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Čišćenje zgrade, održavanje lifta i troškovi zajedničkih prostorija.'**
  String get maintenanceTooltip;

  /// No description provided for @declare.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi'**
  String get declare;

  /// No description provided for @viewReceipt.
  ///
  /// In sr, this message translates to:
  /// **'Vidi uplatnicu'**
  String get viewReceipt;

  /// No description provided for @proposesChanges.
  ///
  /// In sr, this message translates to:
  /// **'{name} predlaže sledeće izmene:'**
  String proposesChanges(String name);

  /// No description provided for @awaitingApprovalInfo.
  ///
  /// In sr, this message translates to:
  /// **'Vaš predlog izmena čeka odobrenje druge strane.'**
  String get awaitingApprovalInfo;

  /// No description provided for @propertyDetails.
  ///
  /// In sr, this message translates to:
  /// **'DETALJI NEKRETNINE'**
  String get propertyDetails;

  /// No description provided for @defaultLeaseTerms.
  ///
  /// In sr, this message translates to:
  /// **'PODRAZUMEVANI USLOVI ZAKUPA'**
  String get defaultLeaseTerms;

  /// No description provided for @defaultLeaseTermsSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Uslovi koji se koriste kao šablon za nove pozive.'**
  String get defaultLeaseTermsSubtitle;

  /// No description provided for @invalidNumber.
  ///
  /// In sr, this message translates to:
  /// **'Nevažeći broj'**
  String get invalidNumber;

  /// No description provided for @enterDayBetween1and31.
  ///
  /// In sr, this message translates to:
  /// **'Unesite dan između 1 i 31'**
  String get enterDayBetween1and31;

  /// No description provided for @expenseConfiguration.
  ///
  /// In sr, this message translates to:
  /// **'KONFIGURACIJA TROŠKOVA'**
  String get expenseConfiguration;

  /// No description provided for @expenseInfostan.
  ///
  /// In sr, this message translates to:
  /// **'Infostan'**
  String get expenseInfostan;

  /// No description provided for @expenseElectricity.
  ///
  /// In sr, this message translates to:
  /// **'Struja (Električna energija)'**
  String get expenseElectricity;

  /// No description provided for @expenseInternetTV.
  ///
  /// In sr, this message translates to:
  /// **'Internet/TV'**
  String get expenseInternetTV;

  /// No description provided for @expenseMaintenance.
  ///
  /// In sr, this message translates to:
  /// **'Održavanje zgrade'**
  String get expenseMaintenance;

  /// No description provided for @expenseTax.
  ///
  /// In sr, this message translates to:
  /// **'Porez'**
  String get expenseTax;

  /// No description provided for @tenantPaysTo.
  ///
  /// In sr, this message translates to:
  /// **'Stanar plaća:'**
  String get tenantPaysTo;

  /// No description provided for @fileSelected.
  ///
  /// In sr, this message translates to:
  /// **'Fajl izabran'**
  String get fileSelected;

  /// No description provided for @selectInvoice.
  ///
  /// In sr, this message translates to:
  /// **'Izaberi račun'**
  String get selectInvoice;

  /// No description provided for @amount.
  ///
  /// In sr, this message translates to:
  /// **'Iznos'**
  String get amount;

  /// No description provided for @setAmountAndUploadInvoice.
  ///
  /// In sr, this message translates to:
  /// **'Podesite iznos i otpremite račun'**
  String get setAmountAndUploadInvoice;

  /// No description provided for @save.
  ///
  /// In sr, this message translates to:
  /// **'Sačuvaj'**
  String get save;

  /// No description provided for @paymentDeclared.
  ///
  /// In sr, this message translates to:
  /// **'Uplata je uspešno prijavljena.'**
  String get paymentDeclared;

  /// No description provided for @dashboard.
  ///
  /// In sr, this message translates to:
  /// **'Kontrolna tabla'**
  String get dashboard;

  /// No description provided for @parties.
  ///
  /// In sr, this message translates to:
  /// **'STRANE'**
  String get parties;

  /// No description provided for @tenantEmail.
  ///
  /// In sr, this message translates to:
  /// **'E-pošta stanara'**
  String get tenantEmail;

  /// No description provided for @existingContractTermsInfo.
  ///
  /// In sr, this message translates to:
  /// **'Postojeći dogovoreni uslovi ugovora (kirija, datumi i troškovi) važiće i za ovog stanara.'**
  String get existingContractTermsInfo;

  /// No description provided for @rentAndPayment.
  ///
  /// In sr, this message translates to:
  /// **'KIRIJA I PLAĆANJE'**
  String get rentAndPayment;

  /// No description provided for @datesAndContract.
  ///
  /// In sr, this message translates to:
  /// **'DATUMI I UGOVOR'**
  String get datesAndContract;

  /// No description provided for @expenseSettingsHeader.
  ///
  /// In sr, this message translates to:
  /// **'PODEŠAVANJE TROŠKOVA'**
  String get expenseSettingsHeader;

  /// No description provided for @editContract.
  ///
  /// In sr, this message translates to:
  /// **'Izmeni ugovor'**
  String get editContract;

  /// No description provided for @sendRevision.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji reviziju'**
  String get sendRevision;

  /// No description provided for @revisionSent.
  ///
  /// In sr, this message translates to:
  /// **'Predlog revizije je poslat'**
  String get revisionSent;

  /// No description provided for @existingFileKept.
  ///
  /// In sr, this message translates to:
  /// **'Postojeći fajl je zadržan'**
  String get existingFileKept;

  /// No description provided for @done.
  ///
  /// In sr, this message translates to:
  /// **'Gotovo'**
  String get done;

  /// No description provided for @startAndEndDatesMandatory.
  ///
  /// In sr, this message translates to:
  /// **'Datum početka i završetka su obavezni'**
  String get startAndEndDatesMandatory;

  /// No description provided for @revisionRequested.
  ///
  /// In sr, this message translates to:
  /// **'Tražena revizija'**
  String get revisionRequested;

  /// No description provided for @statusActive.
  ///
  /// In sr, this message translates to:
  /// **'Aktivno'**
  String get statusActive;

  /// No description provided for @statusPending.
  ///
  /// In sr, this message translates to:
  /// **'Čeka odobrenje'**
  String get statusPending;

  /// No description provided for @statusDeclined.
  ///
  /// In sr, this message translates to:
  /// **'Odbijeno'**
  String get statusDeclined;

  /// No description provided for @statusExpired.
  ///
  /// In sr, this message translates to:
  /// **'Isteklo'**
  String get statusExpired;

  /// No description provided for @statusNegotiating.
  ///
  /// In sr, this message translates to:
  /// **'U pregovorima'**
  String get statusNegotiating;

  /// No description provided for @tenantPaysLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Stanar plaća stanodavcu'**
  String get tenantPaysLandlord;

  /// No description provided for @tenantPaysUtility.
  ///
  /// In sr, this message translates to:
  /// **'Stanar plaća komunalijama'**
  String get tenantPaysUtility;

  /// No description provided for @includedInRent.
  ///
  /// In sr, this message translates to:
  /// **'Uključeno u kiriju'**
  String get includedInRent;

  /// No description provided for @changesAccepted.
  ///
  /// In sr, this message translates to:
  /// **'Promene su prihvaćene'**
  String get changesAccepted;

  /// No description provided for @changesDeclined.
  ///
  /// In sr, this message translates to:
  /// **'Promene su odbijene'**
  String get changesDeclined;

  /// No description provided for @contractChangeProposal.
  ///
  /// In sr, this message translates to:
  /// **'Predlog promene ugovora'**
  String get contractChangeProposal;

  /// No description provided for @cancelProposal.
  ///
  /// In sr, this message translates to:
  /// **'Otkaži predlog'**
  String get cancelProposal;

  /// No description provided for @viewInvoice.
  ///
  /// In sr, this message translates to:
  /// **'Pogledaj fakturu'**
  String get viewInvoice;

  /// No description provided for @paymentResponsibility.
  ///
  /// In sr, this message translates to:
  /// **'ODGOVORNOST ZA PLAĆANJE'**
  String get paymentResponsibility;

  /// No description provided for @tenantPaysDirectlyToUtility.
  ///
  /// In sr, this message translates to:
  /// **'Stanar plaća direktno komunalnoj službi'**
  String get tenantPaysDirectlyToUtility;

  /// No description provided for @tenantPaysToLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Stanar plaća stanodavcu'**
  String get tenantPaysToLandlord;

  /// No description provided for @selectPaymentReceiverWarning.
  ///
  /// In sr, this message translates to:
  /// **'Molimo izaberite primaoca uplate pre nastavka.'**
  String get selectPaymentReceiverWarning;

  /// No description provided for @progressSummary.
  ///
  /// In sr, this message translates to:
  /// **'{completed} / {total} plaćeno • {sent} poslato'**
  String progressSummary(int completed, int total, int sent);

  /// No description provided for @maintenance.
  ///
  /// In sr, this message translates to:
  /// **'Održavanje'**
  String get maintenance;

  /// No description provided for @issues.
  ///
  /// In sr, this message translates to:
  /// **'Problemi'**
  String get issues;

  /// No description provided for @newRequest.
  ///
  /// In sr, this message translates to:
  /// **'Novi zahtev'**
  String get newRequest;

  /// No description provided for @reportIssue.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi kvar'**
  String get reportIssue;

  /// No description provided for @issueTitle.
  ///
  /// In sr, this message translates to:
  /// **'Naslov'**
  String get issueTitle;

  /// No description provided for @issueDescription.
  ///
  /// In sr, this message translates to:
  /// **'Opis'**
  String get issueDescription;

  /// No description provided for @issueCategory.
  ///
  /// In sr, this message translates to:
  /// **'Kategorija'**
  String get issueCategory;

  /// No description provided for @issuePriority.
  ///
  /// In sr, this message translates to:
  /// **'Prioritet'**
  String get issuePriority;

  /// No description provided for @statusInvestigating.
  ///
  /// In sr, this message translates to:
  /// **'Na pregledu'**
  String get statusInvestigating;

  /// No description provided for @statusResolved.
  ///
  /// In sr, this message translates to:
  /// **'Rešeno'**
  String get statusResolved;

  /// No description provided for @priorityNormal.
  ///
  /// In sr, this message translates to:
  /// **'Normalno'**
  String get priorityNormal;

  /// No description provided for @priorityUrgent.
  ///
  /// In sr, this message translates to:
  /// **'Hitno'**
  String get priorityUrgent;

  /// No description provided for @categoryPlumbing.
  ///
  /// In sr, this message translates to:
  /// **'Vodovod'**
  String get categoryPlumbing;

  /// No description provided for @categoryElectrical.
  ///
  /// In sr, this message translates to:
  /// **'Električna energija'**
  String get categoryElectrical;

  /// No description provided for @categoryHeating.
  ///
  /// In sr, this message translates to:
  /// **'Grejanje'**
  String get categoryHeating;

  /// No description provided for @categoryInternet.
  ///
  /// In sr, this message translates to:
  /// **'Internet'**
  String get categoryInternet;

  /// No description provided for @categoryOther.
  ///
  /// In sr, this message translates to:
  /// **'Ostalo'**
  String get categoryOther;

  /// No description provided for @noIssuesTitle.
  ///
  /// In sr, this message translates to:
  /// **'Još nema prijavljenih kvarova'**
  String get noIssuesTitle;

  /// No description provided for @noIssuesMessage.
  ///
  /// In sr, this message translates to:
  /// **'Sve je u redu! Nema prijavljenih zahteva za održavanje ove imovine.'**
  String get noIssuesMessage;

  /// No description provided for @updateStatus.
  ///
  /// In sr, this message translates to:
  /// **'Ažuriraj status'**
  String get updateStatus;

  /// No description provided for @issueDetails.
  ///
  /// In sr, this message translates to:
  /// **'Detalji kvara'**
  String get issueDetails;

  /// No description provided for @logMaintenanceCreated.
  ///
  /// In sr, this message translates to:
  /// **'Kreiran zahtev za održavanje: {title}'**
  String logMaintenanceCreated(String title);

  /// No description provided for @logMaintenanceStatusUpdated.
  ///
  /// In sr, this message translates to:
  /// **'Status održavanja ažuriran na {status}'**
  String logMaintenanceStatusUpdated(String status);

  /// No description provided for @logMaintenanceReopened.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev za održavanje ponovo otvoren'**
  String get logMaintenanceReopened;

  /// No description provided for @logMaintenanceMessageAdded.
  ///
  /// In sr, this message translates to:
  /// **'Dodata nova poruka zahtevu za održavanje'**
  String get logMaintenanceMessageAdded;

  /// No description provided for @notifications.
  ///
  /// In sr, this message translates to:
  /// **'Obaveštenja'**
  String get notifications;

  /// No description provided for @markAllAsRead.
  ///
  /// In sr, this message translates to:
  /// **'Označi sve kao pročitano'**
  String get markAllAsRead;

  /// No description provided for @noNotifications.
  ///
  /// In sr, this message translates to:
  /// **'Još nema obaveštenja'**
  String get noNotifications;

  /// No description provided for @documents.
  ///
  /// In sr, this message translates to:
  /// **'Dokumenta'**
  String get documents;

  /// No description provided for @mainContract.
  ///
  /// In sr, this message translates to:
  /// **'Glavni ugovor'**
  String get mainContract;

  /// No description provided for @addDocument.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj dokument'**
  String get addDocument;

  /// No description provided for @enterDocumentName.
  ///
  /// In sr, this message translates to:
  /// **'Unesite naziv dokumenta'**
  String get enterDocumentName;

  /// No description provided for @noDocumentsYet.
  ///
  /// In sr, this message translates to:
  /// **'Još uvek nema dokumenata'**
  String get noDocumentsYet;

  /// No description provided for @additionalDocuments.
  ///
  /// In sr, this message translates to:
  /// **'Dodatna dokumenta'**
  String get additionalDocuments;

  /// No description provided for @deleteDocument.
  ///
  /// In sr, this message translates to:
  /// **'Obriši dokument'**
  String get deleteDocument;

  /// No description provided for @deleteDocumentConfirm.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni da želite da obrišete ovaj dokument?'**
  String get deleteDocumentConfirm;

  /// No description provided for @uploadMainContract.
  ///
  /// In sr, this message translates to:
  /// **'Otpremi ugovor'**
  String get uploadMainContract;

  /// No description provided for @manageDocuments.
  ///
  /// In sr, this message translates to:
  /// **'Upravljaj dokumentima'**
  String get manageDocuments;

  /// No description provided for @monthlyCollected.
  ///
  /// In sr, this message translates to:
  /// **'Prikupljeno'**
  String get monthlyCollected;

  /// No description provided for @totalRentShort.
  ///
  /// In sr, this message translates to:
  /// **'Kira'**
  String get totalRentShort;

  /// No description provided for @delays.
  ///
  /// In sr, this message translates to:
  /// **'Kašnjenja'**
  String get delays;

  /// No description provided for @vacant.
  ///
  /// In sr, this message translates to:
  /// **'Slobodno'**
  String get vacant;

  /// No description provided for @propertiesCount.
  ///
  /// In sr, this message translates to:
  /// **'{count, plural, one{{count} nekretnina} other{{count} nekretnina}}'**
  String propertiesCount(int count);

  /// No description provided for @hasDebt.
  ///
  /// In sr, this message translates to:
  /// **'Ima dug'**
  String get hasDebt;

  /// No description provided for @paymentAwaitingApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka odobrenje'**
  String get paymentAwaitingApproval;

  /// No description provided for @rent.
  ///
  /// In sr, this message translates to:
  /// **'Kirija'**
  String get rent;

  /// No description provided for @bills.
  ///
  /// In sr, this message translates to:
  /// **'Računi'**
  String get bills;

  /// No description provided for @waiting.
  ///
  /// In sr, this message translates to:
  /// **'Na čekanju'**
  String get waiting;

  /// No description provided for @debtLabel.
  ///
  /// In sr, this message translates to:
  /// **'Dug'**
  String get debtLabel;

  /// No description provided for @paidLabel.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeno'**
  String get paidLabel;

  /// No description provided for @enterBill.
  ///
  /// In sr, this message translates to:
  /// **'Unesi račun'**
  String get enterBill;

  /// No description provided for @addContractAndTenant.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj ugovor i zakupca'**
  String get addContractAndTenant;

  /// No description provided for @approve.
  ///
  /// In sr, this message translates to:
  /// **'Potvrdi'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In sr, this message translates to:
  /// **'Odbij'**
  String get reject;

  /// No description provided for @confirmApprovePaymentTitle.
  ///
  /// In sr, this message translates to:
  /// **'Potvrdi uplatu'**
  String get confirmApprovePaymentTitle;

  /// No description provided for @confirmApprovePaymentMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni da želite da potvrdite ovu uplatu?'**
  String get confirmApprovePaymentMessage;

  /// No description provided for @confirmRejectPaymentTitle.
  ///
  /// In sr, this message translates to:
  /// **'Odbij uplatu'**
  String get confirmRejectPaymentTitle;

  /// No description provided for @confirmRejectPaymentMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li želite da odbijete ovu deklaraciju i tražite od zakupca da je ponovo prijavi?'**
  String get confirmRejectPaymentMessage;

  /// No description provided for @confirm.
  ///
  /// In sr, this message translates to:
  /// **'Potvrdi'**
  String get confirm;

  /// No description provided for @terminateContract.
  ///
  /// In sr, this message translates to:
  /// **'Raskini ugovor'**
  String get terminateContract;

  /// No description provided for @terminationDate.
  ///
  /// In sr, this message translates to:
  /// **'Datum raskida'**
  String get terminationDate;

  /// No description provided for @confirmTerminationTitle.
  ///
  /// In sr, this message translates to:
  /// **'Raskinuti ugovor?'**
  String get confirmTerminationTitle;

  /// No description provided for @confirmTerminationMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni da želite da pošaljete zahtev za raskid ugovora na izabrani datum?'**
  String get confirmTerminationMessage;

  /// No description provided for @terminationRequestSent.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev za raskid ugovora je uspešno poslat.'**
  String get terminationRequestSent;

  /// No description provided for @statusInactive.
  ///
  /// In sr, this message translates to:
  /// **'Pasivno / Završeno'**
  String get statusInactive;

  /// No description provided for @terminationRequested.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se raskid'**
  String get terminationRequested;

  /// No description provided for @approveTermination.
  ///
  /// In sr, this message translates to:
  /// **'Potvrdi raskid'**
  String get approveTermination;

  /// No description provided for @declineTermination.
  ///
  /// In sr, this message translates to:
  /// **'Odbij raskid'**
  String get declineTermination;

  /// No description provided for @contractTerminatedOn.
  ///
  /// In sr, this message translates to:
  /// **'Ugovor je raskinut: {date}'**
  String contractTerminatedOn(Object date);

  /// No description provided for @contractWillEndOn.
  ///
  /// In sr, this message translates to:
  /// **'Ugovor će se završiti: {date}'**
  String contractWillEndOn(String date);

  /// No description provided for @dispute.
  ///
  /// In sr, this message translates to:
  /// **'Ospori'**
  String get dispute;

  /// No description provided for @disputeReason.
  ///
  /// In sr, this message translates to:
  /// **'Razlog osporavanja'**
  String get disputeReason;

  /// No description provided for @disputeReasonHint.
  ///
  /// In sr, this message translates to:
  /// **'Unesite razlog za osporavanje troška...'**
  String get disputeReasonHint;

  /// No description provided for @disputedHeader.
  ///
  /// In sr, this message translates to:
  /// **'OSPORENO'**
  String get disputedHeader;

  /// No description provided for @logRentDisputed.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je osporio uplatu za {month}: {reason}'**
  String logRentDisputed(String month, String reason);

  /// No description provided for @confirmDisputeTitle.
  ///
  /// In sr, this message translates to:
  /// **'Ospori uplatu'**
  String get confirmDisputeTitle;

  /// No description provided for @disputeSentSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Vaš prigovor je poslat stanodavcu.'**
  String get disputeSentSuccess;

  /// No description provided for @takeAction.
  ///
  /// In sr, this message translates to:
  /// **'Preduzmi akciju'**
  String get takeAction;

  /// No description provided for @ownerNote.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnikova beleška'**
  String get ownerNote;

  /// No description provided for @explanationOptional.
  ///
  /// In sr, this message translates to:
  /// **'Objašnjenje (Opciono)'**
  String get explanationOptional;

  /// No description provided for @explanationHint.
  ///
  /// In sr, this message translates to:
  /// **'npr. Proverio sam brojilo...'**
  String get explanationHint;

  /// No description provided for @units.
  ///
  /// In sr, this message translates to:
  /// **'Jedinice'**
  String get units;

  /// No description provided for @tenantsLabel.
  ///
  /// In sr, this message translates to:
  /// **'Stanari'**
  String get tenantsLabel;

  /// No description provided for @portfolioManagement.
  ///
  /// In sr, this message translates to:
  /// **'Upravljanje portfolijom'**
  String get portfolioManagement;

  /// No description provided for @paymentRequests.
  ///
  /// In sr, this message translates to:
  /// **'Plaćanja i zahtevi'**
  String get paymentRequests;

  /// No description provided for @profileSettings.
  ///
  /// In sr, this message translates to:
  /// **'Podešavanja profila'**
  String get profileSettings;

  /// No description provided for @confirmSignOutMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni da želite da se odjavite?'**
  String get confirmSignOutMessage;

  /// No description provided for @errorWithDetails.
  ///
  /// In sr, this message translates to:
  /// **'Greška: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @syncError.
  ///
  /// In sr, this message translates to:
  /// **'Greška pri sinhronizaciji: {error}'**
  String syncError(String error);

  /// No description provided for @acceptTermsWarning.
  ///
  /// In sr, this message translates to:
  /// **'Molimo prihvatite uslove pre nego što nastavite.'**
  String get acceptTermsWarning;

  /// No description provided for @maintenanceRequestSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev za održavanje je uspešno poslat.'**
  String get maintenanceRequestSuccess;

  /// No description provided for @ok.
  ///
  /// In sr, this message translates to:
  /// **'U redu'**
  String get ok;

  /// No description provided for @orLabel.
  ///
  /// In sr, this message translates to:
  /// **'ILI'**
  String get orLabel;

  /// No description provided for @errorUploadingPhoto.
  ///
  /// In sr, this message translates to:
  /// **'Greška pri otpremanju fotografije: {error}'**
  String errorUploadingPhoto(String error);

  /// No description provided for @errorUpdatingStatus.
  ///
  /// In sr, this message translates to:
  /// **'Greška pri ažuriranju statusa: {error}'**
  String errorUpdatingStatus(String error);

  /// No description provided for @errorReopeningRequest.
  ///
  /// In sr, this message translates to:
  /// **'Greška pri ponovnom otvaranju zahteva: {error}'**
  String errorReopeningRequest(String error);

  /// No description provided for @errorOpeningDetails.
  ///
  /// In sr, this message translates to:
  /// **'Nije moguće otvoriti detalje: {error}'**
  String errorOpeningDetails(String error);

  /// No description provided for @nextPayment.
  ///
  /// In sr, this message translates to:
  /// **'Sledeća uplata'**
  String get nextPayment;

  /// No description provided for @payNow.
  ///
  /// In sr, this message translates to:
  /// **'Plati odmah'**
  String get payNow;

  /// No description provided for @upcomingLabel.
  ///
  /// In sr, this message translates to:
  /// **'Predstojeće'**
  String get upcomingLabel;

  /// No description provided for @joinPropertyInvitation.
  ///
  /// In sr, this message translates to:
  /// **'Poziv za pridruživanje nekretnini'**
  String get joinPropertyInvitation;

  /// No description provided for @feedbackSent.
  ///
  /// In sr, this message translates to:
  /// **'Povratne informacije su poslate'**
  String get feedbackSent;

  /// No description provided for @rentalProposal.
  ///
  /// In sr, this message translates to:
  /// **'Predlog zakupa'**
  String get rentalProposal;

  /// No description provided for @reviewContractTerms.
  ///
  /// In sr, this message translates to:
  /// **'Molimo pregledajte uslove ugovora.'**
  String get reviewContractTerms;

  /// No description provided for @expenseDistribution.
  ///
  /// In sr, this message translates to:
  /// **'Raspodela troškova'**
  String get expenseDistribution;

  /// No description provided for @yourNote.
  ///
  /// In sr, this message translates to:
  /// **'Vaša beleška:'**
  String get yourNote;

  /// No description provided for @backToDashboard.
  ///
  /// In sr, this message translates to:
  /// **'Nazad na kontrolnu tablu'**
  String get backToDashboard;

  /// No description provided for @propertyDetailsHeader.
  ///
  /// In sr, this message translates to:
  /// **'DETALJI NEKRETNINE'**
  String get propertyDetailsHeader;

  /// No description provided for @defaultLeaseTermsHeader.
  ///
  /// In sr, this message translates to:
  /// **'PODRAZUMEVANI USLOVI ZAKUPA'**
  String get defaultLeaseTermsHeader;

  /// No description provided for @proposeRevision.
  ///
  /// In sr, this message translates to:
  /// **'Predloži reviziju'**
  String get proposeRevision;

  /// No description provided for @revisionTermsQuestion.
  ///
  /// In sr, this message translates to:
  /// **'Koje uslove želite da promenite? (Zakupnina, dan dospeća, troškovi, itd.)'**
  String get revisionTermsQuestion;

  /// No description provided for @enterNotesHint.
  ///
  /// In sr, this message translates to:
  /// **'Unesite svoje beleške ovde...'**
  String get enterNotesHint;

  /// No description provided for @submit.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji'**
  String get submit;

  /// No description provided for @invitedToJoinProperty.
  ///
  /// In sr, this message translates to:
  /// **'Pozvani ste da se pridružite nekretnini {property}.'**
  String invitedToJoinProperty(String property);

  /// No description provided for @waitingForLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se odgovor stanodavca...'**
  String get waitingForLandlord;

  /// No description provided for @day.
  ///
  /// In sr, this message translates to:
  /// **'Dan'**
  String get day;

  /// No description provided for @notSelected.
  ///
  /// In sr, this message translates to:
  /// **'Nije izabrano'**
  String get notSelected;

  /// No description provided for @acceptTermsAndDistribution.
  ///
  /// In sr, this message translates to:
  /// **'Prihvatam uslove ugovora i raspodelu troškova.'**
  String get acceptTermsAndDistribution;

  /// No description provided for @datesMandatory.
  ///
  /// In sr, this message translates to:
  /// **'Datum početka i završetka su obavezni'**
  String get datesMandatory;

  /// No description provided for @partiesHeader.
  ///
  /// In sr, this message translates to:
  /// **'STRANE'**
  String get partiesHeader;

  /// No description provided for @leaseLockedWarning.
  ///
  /// In sr, this message translates to:
  /// **'Postojeći dogovoreni uslovi zakupa (zakupnina, datumi i troškovi) će se primenjivati i na ovog zakupca.'**
  String get leaseLockedWarning;

  /// No description provided for @rentPaymentHeader.
  ///
  /// In sr, this message translates to:
  /// **'ZAKUP I PLAĆANJE'**
  String get rentPaymentHeader;

  /// No description provided for @loadingPlaceholder.
  ///
  /// In sr, this message translates to:
  /// **'Učitavanje...'**
  String get loadingPlaceholder;

  /// No description provided for @photos.
  ///
  /// In sr, this message translates to:
  /// **'Fotografije'**
  String get photos;

  /// No description provided for @add.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj'**
  String get add;

  /// No description provided for @paymentHistory.
  ///
  /// In sr, this message translates to:
  /// **'Istorija plaćanja'**
  String get paymentHistory;

  /// No description provided for @viewAll.
  ///
  /// In sr, this message translates to:
  /// **'Pogledaj sve'**
  String get viewAll;

  /// No description provided for @ended.
  ///
  /// In sr, this message translates to:
  /// **'Završeno'**
  String get ended;

  /// No description provided for @plannedEnd.
  ///
  /// In sr, this message translates to:
  /// **'Planirani završetak: {date}'**
  String plannedEnd(String date);

  /// No description provided for @yourApartment.
  ///
  /// In sr, this message translates to:
  /// **'Vaš stan'**
  String get yourApartment;

  /// No description provided for @commentHint.
  ///
  /// In sr, this message translates to:
  /// **'Dodajte komentar...'**
  String get commentHint;

  /// No description provided for @issueResolvedStatus.
  ///
  /// In sr, this message translates to:
  /// **'Ovaj kvara je označen kao rešen.'**
  String get issueResolvedStatus;

  /// No description provided for @reopenIssue.
  ///
  /// In sr, this message translates to:
  /// **'Još uvek postoji problem (Ponovo otvori)'**
  String get reopenIssue;

  /// No description provided for @deleteRequest.
  ///
  /// In sr, this message translates to:
  /// **'Obriši zahtev'**
  String get deleteRequest;

  /// No description provided for @terminationApproved.
  ///
  /// In sr, this message translates to:
  /// **'Raskid odobren'**
  String get terminationApproved;

  /// No description provided for @paymentDeclaredHand.
  ///
  /// In sr, this message translates to:
  /// **'Plaćanje je prijavljeno kao lična dostava.'**
  String get paymentDeclaredHand;

  /// No description provided for @fileUnreadable.
  ///
  /// In sr, this message translates to:
  /// **'Nije moguće pročitati datoteku.'**
  String get fileUnreadable;

  /// No description provided for @paymentDeclaredSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Uplata {title} je prijavljena.'**
  String paymentDeclaredSuccess(String title);

  /// No description provided for @setAmountUploadInvoice.
  ///
  /// In sr, this message translates to:
  /// **'Podesite iznos i otpremite račun'**
  String get setAmountUploadInvoice;

  /// No description provided for @yourMessage.
  ///
  /// In sr, this message translates to:
  /// **'Vaša poruka:'**
  String get yourMessage;

  /// No description provided for @revisionRequestLabel.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev za reviziju:'**
  String get revisionRequestLabel;

  /// No description provided for @noActivityLogs.
  ///
  /// In sr, this message translates to:
  /// **'Još nema prijavljenih aktivnosti'**
  String get noActivityLogs;

  /// No description provided for @landlordProposedChanges.
  ///
  /// In sr, this message translates to:
  /// **'Stanodavac je predložio izmene ugovora. Dodirnite da pregledate.'**
  String get landlordProposedChanges;

  /// No description provided for @tenantProposedChanges.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je predložio izmene ugovora. Dodirnite da pregledate.'**
  String get tenantProposedChanges;

  /// No description provided for @dueOn.
  ///
  /// In sr, this message translates to:
  /// **'Dospeva: {date}'**
  String dueOn(String date);

  /// No description provided for @item.
  ///
  /// In sr, this message translates to:
  /// **'stavka'**
  String get item;

  /// No description provided for @items.
  ///
  /// In sr, this message translates to:
  /// **'stavke'**
  String get items;

  /// No description provided for @waitingForOtherParty.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se odobrenje druge strane...'**
  String get waitingForOtherParty;

  /// No description provided for @awaitingApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se odobrenje...'**
  String get awaitingApproval;

  /// No description provided for @contract.
  ///
  /// In sr, this message translates to:
  /// **'Ugovor'**
  String get contract;

  /// No description provided for @paidOn.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeno: {date}'**
  String paidOn(Object date);

  /// No description provided for @cannotInviteSelf.
  ///
  /// In sr, this message translates to:
  /// **'Ne možete pozvati sebe kao stanara.'**
  String get cannotInviteSelf;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sr', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'sr':
      {
        switch (locale.scriptCode) {
          case 'Cyrl':
            return AppLocalizationsSrCyrl();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sr':
      return AppLocalizationsSr();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
