import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
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
    Locale('ru'),
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
  /// **'Prijavi se'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In sr, this message translates to:
  /// **'Registruj se'**
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
  /// **'Izaberi svoju ulogu'**
  String get selectRole;

  /// No description provided for @fieldRequired.
  ///
  /// In sr, this message translates to:
  /// **'Ovo polje je obavezno'**
  String get fieldRequired;

  /// No description provided for @consentRequired.
  ///
  /// In sr, this message translates to:
  /// **'Moraš prihvatiti ZZPL da nastaviš'**
  String get consentRequired;

  /// No description provided for @loginToAccount.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi se na svoj nalog'**
  String get loginToAccount;

  /// No description provided for @createAccount.
  ///
  /// In sr, this message translates to:
  /// **'Napravi novi nalog'**
  String get createAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In sr, this message translates to:
  /// **'Nemate nalog? Registruj se'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In sr, this message translates to:
  /// **'Imaš nalog? Prijavi se'**
  String get alreadyHaveAccount;

  /// No description provided for @continueWithGoogle.
  ///
  /// In sr, this message translates to:
  /// **'Nastavi sa Google-om'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In sr, this message translates to:
  /// **'Nastavi sa Apple-om'**
  String get continueWithApple;

  /// No description provided for @fullName.
  ///
  /// In sr, this message translates to:
  /// **'Ime i prezime'**
  String get fullName;

  /// No description provided for @errorSelectRole.
  ///
  /// In sr, this message translates to:
  /// **'Molimo izaberi svoju ulogu'**
  String get errorSelectRole;

  /// No description provided for @deleteAccount.
  ///
  /// In sr, this message translates to:
  /// **'Obriši nalog'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In sr, this message translates to:
  /// **'Ova radnja je trajna i ne može se poništiti. Svi tvoji podaci će biti obrisani.'**
  String get deleteAccountWarning;

  /// No description provided for @confirmPasswordForDeletion.
  ///
  /// In sr, this message translates to:
  /// **'Unesi lozinku da potvrdiš brisanje'**
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

  /// No description provided for @settingsHeader.
  ///
  /// In sr, this message translates to:
  /// **'Podešavanja'**
  String get settingsHeader;

  /// No description provided for @accountHeader.
  ///
  /// In sr, this message translates to:
  /// **'Nalog'**
  String get accountHeader;

  /// No description provided for @discoverPremium.
  ///
  /// In sr, this message translates to:
  /// **'Istražite Premium'**
  String get discoverPremium;

  /// No description provided for @unlimitedLeaseContracts.
  ///
  /// In sr, this message translates to:
  /// **'Neograničeni najamni ugovori'**
  String get unlimitedLeaseContracts;

  /// No description provided for @updateName.
  ///
  /// In sr, this message translates to:
  /// **'Ažuriraj ime'**
  String get updateName;

  /// No description provided for @updatePassword.
  ///
  /// In sr, this message translates to:
  /// **'Promeni lozinku'**
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
  /// **'npr. Stan u Beogradu'**
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
  /// **'Još uvek nema nekretnina'**
  String get noProperties;

  /// No description provided for @addYourFirstProperty.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj svoju prvu nekretninu da pokreneš praćenje!'**
  String get addYourFirstProperty;

  /// No description provided for @editProperty.
  ///
  /// In sr, this message translates to:
  /// **'Izmeni nekretninu'**
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
  /// **'Da li sigurno želiš da obrišeš ovu nekretninu? Ova akcija je nepovratna.'**
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
  /// **'Pozivni link je kreiran! Možeš ga podeliti.'**
  String get inviteCreatedSuccess;

  /// No description provided for @shareInviteLink.
  ///
  /// In sr, this message translates to:
  /// **'Podeli pozivni link'**
  String get shareInviteLink;

  /// No description provided for @copyLink.
  ///
  /// In sr, this message translates to:
  /// **'Kopiraj link'**
  String get copyLink;

  /// No description provided for @noInvitesYet.
  ///
  /// In sr, this message translates to:
  /// **'Nema poslatih poziva'**
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
  /// **'Ugovor je poslat stanaru'**
  String get contractSentToTenant;

  /// No description provided for @overview.
  ///
  /// In sr, this message translates to:
  /// **'Pregled'**
  String get overview;

  /// No description provided for @financials.
  ///
  /// In sr, this message translates to:
  /// **'Plaćanja'**
  String get financials;

  /// No description provided for @propertySettings.
  ///
  /// In sr, this message translates to:
  /// **'Podešavanja nekretnine'**
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
  /// **'Prihvati poziv'**
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
  /// **'Dobrodošao/la kući! Poziv je prihvaćen.'**
  String get invitationAcceptedSuccess;

  /// No description provided for @pendingInvitationBanner.
  ///
  /// In sr, this message translates to:
  /// **'Imaš poziv za {property}'**
  String pendingInvitationBanner(String property);

  /// No description provided for @invitedBy.
  ///
  /// In sr, this message translates to:
  /// **'{name} te je pozvao/la'**
  String invitedBy(String name);

  /// No description provided for @yourName.
  ///
  /// In sr, this message translates to:
  /// **'Vaše ime'**
  String get yourName;

  /// No description provided for @yourNameHint.
  ///
  /// In sr, this message translates to:
  /// **'Unesi svoje ime i prezime'**
  String get yourNameHint;

  /// No description provided for @viewInvite.
  ///
  /// In sr, this message translates to:
  /// **'Pogledaj poziv'**
  String get viewInvite;

  /// No description provided for @myProperty.
  ///
  /// In sr, this message translates to:
  /// **'Moja nekretnina'**
  String get myProperty;

  /// No description provided for @myProperties.
  ///
  /// In sr, this message translates to:
  /// **'Moje nekretnine'**
  String get myProperties;

  /// No description provided for @tenantEmptyStateTitle.
  ///
  /// In sr, this message translates to:
  /// **'Još uvek nemaš dodeljen stan'**
  String get tenantEmptyStateTitle;

  /// No description provided for @tenantEmptyStateMessage.
  ///
  /// In sr, this message translates to:
  /// **'Ako ti je vlasnik poslao poziv, videćeš ga ovde. Osveži listu klikom na dugme ispod.'**
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
  /// **'Da li sigurno želiš da odbiješ ovaj poziv? Poziv će biti uklonjen sa liste.'**
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
  /// **'Učitaj ugovor'**
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
  /// **'Jezik'**
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

  /// No description provided for @russian.
  ///
  /// In sr, this message translates to:
  /// **'Ruski'**
  String get russian;

  /// No description provided for @tenantMode.
  ///
  /// In sr, this message translates to:
  /// **'Uloga stanara'**
  String get tenantMode;

  /// No description provided for @landlordMode.
  ///
  /// In sr, this message translates to:
  /// **'Uloga vlasnika'**
  String get landlordMode;

  /// No description provided for @whatAreYou.
  ///
  /// In sr, this message translates to:
  /// **'Izaberi svoju ulogu:'**
  String get whatAreYou;

  /// No description provided for @selectRoleToContinue.
  ///
  /// In sr, this message translates to:
  /// **'Izaberi ulogu za početak. Možeš je promeniti bilo kada u meniju iznad.'**
  String get selectRoleToContinue;

  /// No description provided for @consentTextFullBody.
  ///
  /// In sr, this message translates to:
  /// **'Korišćenjem aplikacije Stanomer, dajete izričit pristanak za obradu vaših podataka o ličnosti u skladu sa Zakonom o zaštiti podataka o ličnosti (ZZPL) Republike Srbije.\n\nKoji podaci se prikupljaju: Vaše ime, e-mail adresa, IP adresa i podaci iz ugovora o zakupu nepokretnosti.\n\nSvrha obrade: Podaci se koriste isključivo za olakšavanje komunikacije između stanodavca i zakupca, vođenje evidencije o plaćanju i kreiranje pravno valjanih zapisa.\n\nDeljenje podataka: Vaši podaci se ne prodaju trećim licima. Čuvaju se na sigurnim serverima u EU (Supabase Frankfurt).\n\nVaša prava: Imate pravo da u bilo kom trenutku zatražite pristup svojim podacima ili trajno brisanje vašeg naloga i svih povezanih podataka direktno putem aplikacije.'**
  String get consentTextFullBody;

  /// No description provided for @removeTenant.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni stanara'**
  String get removeTenant;

  /// No description provided for @removeTenantConfirmation.
  ///
  /// In sr, this message translates to:
  /// **'Da li želiš da ukloniš stanara? Ovo će prekinuti vezu i obrisati istoriju poziva.'**
  String get removeTenantConfirmation;

  /// No description provided for @remove.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni'**
  String get remove;

  /// No description provided for @logRentDeclared.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je prijavio uplatu za {month}.'**
  String logRentDeclared(String month);

  /// No description provided for @logRentApproved.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je odobrio uplatu za {month}.'**
  String logRentApproved(String month);

  /// No description provided for @logRentRejected.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je odbio uplatu za {month}.'**
  String logRentRejected(String month);

  /// No description provided for @logMarkedAsPaid.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je označio {month} kao plaćen.'**
  String logMarkedAsPaid(String month);

  /// No description provided for @logMarkedAsPending.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je vratio {month} na čekanje.'**
  String logMarkedAsPending(String month);

  /// No description provided for @logAutoApproved.
  ///
  /// In sr, this message translates to:
  /// **'Sistem je automatski odobrio uplatu za {month} posle 5 dana.'**
  String logAutoApproved(String month);

  /// No description provided for @activity.
  ///
  /// In sr, this message translates to:
  /// **'Aktivnosti'**
  String get activity;

  /// No description provided for @noContractsTitle.
  ///
  /// In sr, this message translates to:
  /// **'Nema aktivnih ugovora'**
  String get noContractsTitle;

  /// No description provided for @noContractsMessage.
  ///
  /// In sr, this message translates to:
  /// **'Kako bi pratio kirije i račune, prvo unesi ugovor i pozovi stanara.'**
  String get noContractsMessage;

  /// No description provided for @inviteFirstTenant.
  ///
  /// In sr, this message translates to:
  /// **'Pozovi zakupca'**
  String get inviteFirstTenant;

  /// No description provided for @confirmCancelInvitationTitle.
  ///
  /// In sr, this message translates to:
  /// **'Otkaži poziv'**
  String get confirmCancelInvitationTitle;

  /// No description provided for @confirmCancelInvitationMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li želiš da otkažeš poziv? Link će postati nevažeći.'**
  String get confirmCancelInvitationMessage;

  /// No description provided for @confirmDeclineRevisionTitle.
  ///
  /// In sr, this message translates to:
  /// **'Odbij zahtev za reviziju'**
  String get confirmDeclineRevisionTitle;

  /// No description provided for @confirmDeclineRevisionMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li želiš da odbijete izmene ugovora? Ugovor ostaje sa prvobitnim uslovima.'**
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
  /// **'Odbij izmene'**
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

  /// No description provided for @awaitingExplanation.
  ///
  /// In sr, this message translates to:
  /// **'Potrebno je odobrenje stanodavca da bi se označilo kao plaćeno.'**
  String get awaitingExplanation;

  /// No description provided for @paidHeader.
  ///
  /// In sr, this message translates to:
  /// **'PLAĆENO'**
  String get paidHeader;

  /// No description provided for @waitingForTenantPayment.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se uplata stanara'**
  String get waitingForTenantPayment;

  /// No description provided for @waitingForYourApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka tvoje odobrenje'**
  String get waitingForYourApproval;

  /// No description provided for @waitingForOwnerApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se odobrenje vlasnika'**
  String get waitingForOwnerApproval;

  /// No description provided for @waitingForAgency.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se odgovor agencije...'**
  String get waitingForAgency;

  /// No description provided for @waitingForAgencyApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se odobrenje agencije'**
  String get waitingForAgencyApproval;

  /// No description provided for @waitingForYourPayment.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se tvoja uplata'**
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
  /// **'Učitaj račun'**
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
  /// **'Porez'**
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
  /// **'Komunalne usluge'**
  String get utility;

  /// No description provided for @owner.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik'**
  String get owner;

  /// No description provided for @proposeChangesInfo.
  ///
  /// In sr, this message translates to:
  /// **'Izmene će biti poslate {role} na odobrenje. Stari uslovi važe dok se novi ne prihvate.'**
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
  /// **'Otpremi uplatnicu o plaćanju'**
  String get uploadReceipt;

  /// No description provided for @paidInCash.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeno gotovinom'**
  String get paidInCash;

  /// No description provided for @noFinancialRecords.
  ///
  /// In sr, this message translates to:
  /// **'Nema zabeleženih plaćanja'**
  String get noFinancialRecords;

  /// No description provided for @noActiveContract.
  ///
  /// In sr, this message translates to:
  /// **'Nema aktivnih ugovora'**
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
  /// **'Ukupno'**
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
  /// **'Prikaži uplatnicu'**
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
  /// **'Ciljni uslovi koji se koriste kao predložak za nova pozivanja.'**
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
  /// **'Struja'**
  String get expenseElectricity;

  /// No description provided for @expenseInternetTV.
  ///
  /// In sr, this message translates to:
  /// **'Internet/TV'**
  String get expenseInternetTV;

  /// No description provided for @expenseMaintenance.
  ///
  /// In sr, this message translates to:
  /// **'Održavanje'**
  String get expenseMaintenance;

  /// No description provided for @expenseTax.
  ///
  /// In sr, this message translates to:
  /// **'Porez'**
  String get expenseTax;

  /// No description provided for @tenantPaysTo.
  ///
  /// In sr, this message translates to:
  /// **'Plaća se:'**
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
  /// **'Unesite detalje računa'**
  String get setAmountAndUploadInvoice;

  /// No description provided for @save.
  ///
  /// In sr, this message translates to:
  /// **'Sačuvaj'**
  String get save;

  /// No description provided for @paymentDeclared.
  ///
  /// In sr, this message translates to:
  /// **'Uplata je prijavljena.'**
  String get paymentDeclared;

  /// No description provided for @dashboard.
  ///
  /// In sr, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @parties.
  ///
  /// In sr, this message translates to:
  /// **'STRANE'**
  String get parties;

  /// No description provided for @tenantEmail.
  ///
  /// In sr, this message translates to:
  /// **'E-mail stanara'**
  String get tenantEmail;

  /// No description provided for @existingContractTermsInfo.
  ///
  /// In sr, this message translates to:
  /// **'Dogovoreni uslovi ugovora važiće i za ovog stanara.'**
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
  /// **'Pošalji izmene'**
  String get sendRevision;

  /// No description provided for @revisionSent.
  ///
  /// In sr, this message translates to:
  /// **'Predlog izmena je poslat'**
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
  /// **'Datumi početka i kraja su obavezni'**
  String get startAndEndDatesMandatory;

  /// No description provided for @revisionRequested.
  ///
  /// In sr, this message translates to:
  /// **'Tražene izmene'**
  String get revisionRequested;

  /// No description provided for @statusActive.
  ///
  /// In sr, this message translates to:
  /// **'Aktivno'**
  String get statusActive;

  /// No description provided for @statusPending.
  ///
  /// In sr, this message translates to:
  /// **'Na čekanju'**
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
  /// **'Izmene su prihvaćene'**
  String get changesAccepted;

  /// No description provided for @changesDeclined.
  ///
  /// In sr, this message translates to:
  /// **'Izmene su odbijene'**
  String get changesDeclined;

  /// No description provided for @contractChangeProposal.
  ///
  /// In sr, this message translates to:
  /// **'Predlog izmena ugovora'**
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
  /// **'Izaberi primaoca uplate pre nego što nastaviš.'**
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
  /// **'Prijavi problem'**
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
  /// **'U toku'**
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

  /// No description provided for @categoryAppliance.
  ///
  /// In sr, this message translates to:
  /// **'Kućni aparati'**
  String get categoryAppliance;

  /// No description provided for @categoryStructural.
  ///
  /// In sr, this message translates to:
  /// **'Građevinski radovi'**
  String get categoryStructural;

  /// No description provided for @categoryOther.
  ///
  /// In sr, this message translates to:
  /// **'Ostalo'**
  String get categoryOther;

  /// No description provided for @noIssuesTitle.
  ///
  /// In sr, this message translates to:
  /// **'Nema prijavljenih problema'**
  String get noIssuesTitle;

  /// No description provided for @noIssuesMessage.
  ///
  /// In sr, this message translates to:
  /// **'Sve je u redu, nema zabeleženih problema.'**
  String get noIssuesMessage;

  /// No description provided for @updateStatus.
  ///
  /// In sr, this message translates to:
  /// **'Ažuriraj status'**
  String get updateStatus;

  /// No description provided for @issueDetails.
  ///
  /// In sr, this message translates to:
  /// **'Detalji problema'**
  String get issueDetails;

  /// No description provided for @logMaintenanceCreated.
  ///
  /// In sr, this message translates to:
  /// **'Prijavljen problem: {title}'**
  String logMaintenanceCreated(String title);

  /// No description provided for @logMaintenanceStatusUpdated.
  ///
  /// In sr, this message translates to:
  /// **'Status problema je promenjen na {status}'**
  String logMaintenanceStatusUpdated(String status);

  /// No description provided for @logMaintenanceReopened.
  ///
  /// In sr, this message translates to:
  /// **'Problem je ponovo otvoren'**
  String get logMaintenanceReopened;

  /// No description provided for @logMaintenanceMessageAdded.
  ///
  /// In sr, this message translates to:
  /// **'Dodata je nova poruka'**
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
  /// **'Nema novih obaveštenja'**
  String get noNotifications;

  /// No description provided for @documents.
  ///
  /// In sr, this message translates to:
  /// **'Dokumenti'**
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
  /// **'Nema učitanih dokumenata'**
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
  /// **'Da li sigurno želiš da obrišeš ovaj dokument?'**
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
  /// **'Prazno'**
  String get vacant;

  /// No description provided for @overdueReceivables.
  ///
  /// In sr, this message translates to:
  /// **'Kašnjenja'**
  String get overdueReceivables;

  /// No description provided for @collectedByType.
  ///
  /// In sr, this message translates to:
  /// **'Naplaćeno'**
  String get collectedByType;

  /// No description provided for @propertiesCount.
  ///
  /// In sr, this message translates to:
  /// **'{count, plural, one{{count} nekretnina} other{{count} nekretnina}}'**
  String propertiesCount(int count);

  /// No description provided for @hasDebt.
  ///
  /// In sr, this message translates to:
  /// **'Duguje'**
  String get hasDebt;

  /// No description provided for @paymentAwaitingApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka proveru'**
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

  /// No description provided for @totalDebt.
  ///
  /// In sr, this message translates to:
  /// **'Ukupan dug'**
  String get totalDebt;

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
  /// **'Da li želiš da potvrdiš ovu uplatu?'**
  String get confirmApprovePaymentMessage;

  /// No description provided for @confirmRejectPaymentTitle.
  ///
  /// In sr, this message translates to:
  /// **'Odbij uplatu'**
  String get confirmRejectPaymentTitle;

  /// No description provided for @confirmRejectPaymentMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li želiš da odbiješ ovu prijavu i tražiš ponovno slanje?'**
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
  /// **'Da li želiš da pošalješ zahtev za raskid ugovora za izabrani datum?'**
  String get confirmTerminationMessage;

  /// No description provided for @terminationRequestSent.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev za raskid je poslat.'**
  String get terminationRequestSent;

  /// No description provided for @statusInactive.
  ///
  /// In sr, this message translates to:
  /// **'Završeno'**
  String get statusInactive;

  /// No description provided for @terminationRequested.
  ///
  /// In sr, this message translates to:
  /// **'Raskid na čekanju'**
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
  /// **'Prigovor je poslat vlasniku stana.'**
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
  /// **'Napomena (opciono)'**
  String get explanationOptional;

  /// No description provided for @explanationHint.
  ///
  /// In sr, this message translates to:
  /// **'npr. Proverio sam struju...'**
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
  /// **'Portfolijo'**
  String get portfolioManagement;

  /// No description provided for @paymentRequests.
  ///
  /// In sr, this message translates to:
  /// **'Zahtevi i plaćanja'**
  String get paymentRequests;

  /// No description provided for @profileSettings.
  ///
  /// In sr, this message translates to:
  /// **'Podešavanja profila'**
  String get profileSettings;

  /// No description provided for @confirmSignOutMessage.
  ///
  /// In sr, this message translates to:
  /// **'Da li želiš da se odjaviš?'**
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
  /// **'Prihvati uslove pre nego što nastaviš.'**
  String get acceptTermsWarning;

  /// No description provided for @maintenanceRequestSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Problem je uspešno prijavljen.'**
  String get maintenanceRequestSuccess;

  /// No description provided for @ok.
  ///
  /// In sr, this message translates to:
  /// **'OK'**
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
  /// **'Prijavi uplatu'**
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
  /// **'Hvala na feedback-u!'**
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
  /// **'INFORMACIJE O NEKRETNINI'**
  String get propertyDetailsHeader;

  /// No description provided for @defaultLeaseTermsHeader.
  ///
  /// In sr, this message translates to:
  /// **'PODRAZUMEVANI USLOVI ZAKUPA'**
  String get defaultLeaseTermsHeader;

  /// No description provided for @proposeRevision.
  ///
  /// In sr, this message translates to:
  /// **'Predloži izmene'**
  String get proposeRevision;

  /// No description provided for @revisionTermsQuestion.
  ///
  /// In sr, this message translates to:
  /// **'Koje uslove želiš da promeniš? (Kiriju, dan plaćanja, troškove...)'**
  String get revisionTermsQuestion;

  /// No description provided for @enterNotesHint.
  ///
  /// In sr, this message translates to:
  /// **'Upiši svoju napomenu...'**
  String get enterNotesHint;

  /// No description provided for @submit.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji'**
  String get submit;

  /// No description provided for @invitedToJoinProperty.
  ///
  /// In sr, this message translates to:
  /// **'Pozvan/a si da se pridružiš objektu {property}.'**
  String invitedToJoinProperty(String property);

  /// No description provided for @waitingForLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se odgovor vlasnika...'**
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
  /// **'Prihvatam uslove ugovora i podelu troškova.'**
  String get acceptTermsAndDistribution;

  /// No description provided for @datesMandatory.
  ///
  /// In sr, this message translates to:
  /// **'Datumi početka i kraja su obavezni'**
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
  /// **'Problem i dalje postoji (Otvori ponovo)'**
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
  /// **'Uplata za {title} je uspešno prijavljena.'**
  String paymentDeclaredSuccess(String title);

  /// No description provided for @setAmountUploadInvoice.
  ///
  /// In sr, this message translates to:
  /// **'Unesite detalje računa'**
  String get setAmountUploadInvoice;

  /// No description provided for @yourMessage.
  ///
  /// In sr, this message translates to:
  /// **'Tvoja poruka:'**
  String get yourMessage;

  /// No description provided for @revisionRequestLabel.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev za izmenama:'**
  String get revisionRequestLabel;

  /// No description provided for @noActivityLogs.
  ///
  /// In sr, this message translates to:
  /// **'Još nema prijavljenih aktivnosti'**
  String get noActivityLogs;

  /// No description provided for @landlordProposedChanges.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je predložio izmene ugovora. Dodirni da pogledaš.'**
  String get landlordProposedChanges;

  /// No description provided for @tenantProposedChanges.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je predložio izmene ugovora. Dodirni da pogledaš.'**
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
  /// **'Ne možeš pozvati sopstveni e-mail.'**
  String get cannotInviteSelf;

  /// No description provided for @paywallTitle.
  ///
  /// In sr, this message translates to:
  /// **'Stanomer Premium'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni sva ograničenja u vođenju nekretnina.'**
  String get paywallSubtitle;

  /// No description provided for @unlimitedProperties.
  ///
  /// In sr, this message translates to:
  /// **'Neograničeno dodavanje i upravljanje nekretninama'**
  String get unlimitedProperties;

  /// No description provided for @detailedReporting.
  ///
  /// In sr, this message translates to:
  /// **'Napredno finansijsko izveštavanje'**
  String get detailedReporting;

  /// No description provided for @extraStorage.
  ///
  /// In sr, this message translates to:
  /// **'Više prostora za skladištenje'**
  String get extraStorage;

  /// No description provided for @pdfContracts.
  ///
  /// In sr, this message translates to:
  /// **'PDF ugovori (Uskoro)'**
  String get pdfContracts;

  /// No description provided for @automatedRenewal.
  ///
  /// In sr, this message translates to:
  /// **'Automatska obnova (Uskoro)'**
  String get automatedRenewal;

  /// No description provided for @restorePurchases.
  ///
  /// In sr, this message translates to:
  /// **'Povrati kupovine'**
  String get restorePurchases;

  /// No description provided for @limitReachedTitle.
  ///
  /// In sr, this message translates to:
  /// **'Dostigli ste besplatni limit'**
  String get limitReachedTitle;

  /// No description provided for @limitReachedSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Pređite na Stanomer Premium za upravljanje sa više nekretnina.'**
  String get limitReachedSubtitle;

  /// No description provided for @optionsLoadFailed.
  ///
  /// In sr, this message translates to:
  /// **'Nije moguće učitati opcije pretplate.'**
  String get optionsLoadFailed;

  /// No description provided for @manageSubscription.
  ///
  /// In sr, this message translates to:
  /// **'Upravljaj pretplatom'**
  String get manageSubscription;

  /// No description provided for @premiumMobileOnly.
  ///
  /// In sr, this message translates to:
  /// **'Potrebna mobilna aplikacija'**
  String get premiumMobileOnly;

  /// No description provided for @premiumMobileOnlyDesc.
  ///
  /// In sr, this message translates to:
  /// **'Stanomer Premium se kupuje samo kroz mobilnu aplikaciju. Preuzmi je preko linkova ispod.'**
  String get premiumMobileOnlyDesc;

  /// No description provided for @downloadOnAppStore.
  ///
  /// In sr, this message translates to:
  /// **'Preuzmi na App Store-u'**
  String get downloadOnAppStore;

  /// No description provided for @downloadOnPlayStore.
  ///
  /// In sr, this message translates to:
  /// **'Preuzmi na Google Play-u'**
  String get downloadOnPlayStore;

  /// No description provided for @premiumFeatures.
  ///
  /// In sr, this message translates to:
  /// **'Premium funkcije'**
  String get premiumFeatures;

  /// No description provided for @premiumFeature1.
  ///
  /// In sr, this message translates to:
  /// **'Neograničeno upravljanje nekretninama'**
  String get premiumFeature1;

  /// No description provided for @premiumFeature2.
  ///
  /// In sr, this message translates to:
  /// **'Napredno finansijsko izveštavanje'**
  String get premiumFeature2;

  /// No description provided for @premiumFeature3.
  ///
  /// In sr, this message translates to:
  /// **'Prioritetna podrška'**
  String get premiumFeature3;

  /// No description provided for @premiumFeature4.
  ///
  /// In sr, this message translates to:
  /// **'Pristup na svim platformama'**
  String get premiumFeature4;

  /// No description provided for @termsOfService.
  ///
  /// In sr, this message translates to:
  /// **'Uslovi korišćenja i EULA'**
  String get termsOfService;

  /// No description provided for @termsOfServiceContent.
  ///
  /// In sr, this message translates to:
  /// **'Stanomer – Ugovor o licenciranju sa krajnjim korisnikom (EULA) i Uslovi korišćenja\nPoslednji put ažurirano: 23. april 2026.\n\n1. Uvod\nOvaj Ugovor o licenciranju sa krajnjim korisnikom (\"Ugovor\") predstavlja pravni sporazum između Vas (\"Korisnik\") i aplikacije Stanomer. Instaliranjem ili korišćenjem aplikacije prihvatate odredbe ovog Ugovora.\n\n2. Apple i Google uslovi\nApple App Store: Ovaj Ugovor je zaključen isključivo između Korisnika i Stanomer-a. Ovaj ugovor uključuje Apple-ov standardni ugovor o licenci za krajnjeg korisnika (Standard EULA) putem reference: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/\n\nGoogle Play Store: Ovaj Ugovor je zaključen isključivo između Korisnika i Stanomer-a.\n\nPotvrđujete da Apple i Google nemaju nikakvu obavezu pružanja usluga održavanja i podrške u vezi sa aplikacijom.\n\n3. Pretplata i naplata\nPlaćanje: Plaćanje će biti naplaćeno sa Vašeg iTunes ili Google Play naloga prilikom potvrde kupovine.\n\nObnavljanje: Pretplate se automatski obnavljaju osim ako se automatsko obnavljanje ne isključi najmanje 24 sata pre kraja tekućeg perioda.\n\nUpravljanje: Možete upravljati pretplatama ili isključiti automatsko obnavljanje u podešavanjima naloga nakon kupovine.\n\n4. Korisnički sadržaj i ponašanje\nOdgovorni ste za podatke koje unosite (iznosi zakupa, izveštaji o šteti, ugovori).\n\nZabranjeno je otpremanje nezakonitog, uvredljivog ili kršećeg sadržaja.\n\nStanomer zadržava pravo da ukloni bilo koji sadržaj koji krši zakone Republike Srbije ili ove uslove.\n\n5. Privatnost i zaštita podataka (ZZPL, GDPR, KVKK)\nZakon Srbije (ZZPL): Zakon o zaštiti podataka o ličnosti.\n\nGDPR: Opšta uredba o zaštiti podataka o ličnosti (EU).\n\nKVKK: Zakon o zaštiti podataka o ličnosti (Turska).\n\nVaši podaci se štite u skladu sa globalnim principima privatnosti podataka, bez obzir na Vašu lokaciju.\n\n6. Ograničenje odgovornosti\nStanomer pruža platformu za upravljanje zakupom i nije strana u stvarnim ugovorima o zakupu između stanodavaca i zakupaca. Ne snosimo odgovornost za sporove između korisnika ili za finansijske transakcije obavljene van platforme.\n\n7. Prekid\nOvaj Ugovor važi dok ga ne raskinete Vi ili Stanomer. Vaša prava po ovoj licenci će automatski prestati ako se ne pridržavate bilo koje od njenih odredbi.'**
  String get termsOfServiceContent;

  /// No description provided for @support_title.
  ///
  /// In sr, this message translates to:
  /// **'Podrška'**
  String get support_title;

  /// No description provided for @support_desc.
  ///
  /// In sr, this message translates to:
  /// **'Piši nam ako imaš pitanja ili feedback.'**
  String get support_desc;

  /// No description provided for @subject.
  ///
  /// In sr, this message translates to:
  /// **'Tema'**
  String get subject;

  /// No description provided for @category.
  ///
  /// In sr, this message translates to:
  /// **'Kategorija'**
  String get category;

  /// No description provided for @message.
  ///
  /// In sr, this message translates to:
  /// **'Poruka'**
  String get message;

  /// No description provided for @support.
  ///
  /// In sr, this message translates to:
  /// **'Podrška'**
  String get support;

  /// No description provided for @bug.
  ///
  /// In sr, this message translates to:
  /// **'Prijava greške'**
  String get bug;

  /// No description provided for @other.
  ///
  /// In sr, this message translates to:
  /// **'Drugo'**
  String get other;

  /// No description provided for @messageSent.
  ///
  /// In sr, this message translates to:
  /// **'Poruka je poslata!'**
  String get messageSent;

  /// No description provided for @errorSendingMessage.
  ///
  /// In sr, this message translates to:
  /// **'Slanje poruke nije uspelo. Molimo pokušajte ponovo.'**
  String get errorSendingMessage;

  /// No description provided for @requiredField.
  ///
  /// In sr, this message translates to:
  /// **'Ovo polje je obavezno'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In sr, this message translates to:
  /// **'Unesite validnu email adresu'**
  String get invalidEmail;

  /// No description provided for @offlineMessage.
  ///
  /// In sr, this message translates to:
  /// **'Trenutno ste van mreže. Možete nastaviti sa postojećim podacima. Biće ažurirano kada se povežete.'**
  String get offlineMessage;

  /// No description provided for @retry.
  ///
  /// In sr, this message translates to:
  /// **'OSVEŽI'**
  String get retry;

  /// No description provided for @zzplConsentTitle.
  ///
  /// In sr, this message translates to:
  /// **'Zaštita podataka (ZZPL)'**
  String get zzplConsentTitle;

  /// No description provided for @zzplAgreeAndContinue.
  ///
  /// In sr, this message translates to:
  /// **'Prihvatam i nastavljam'**
  String get zzplAgreeAndContinue;

  /// No description provided for @share.
  ///
  /// In sr, this message translates to:
  /// **'Podeli'**
  String get share;

  /// No description provided for @optional.
  ///
  /// In sr, this message translates to:
  /// **'Opciono'**
  String get optional;

  /// No description provided for @sentInvitation.
  ///
  /// In sr, this message translates to:
  /// **'Poslati poziv'**
  String get sentInvitation;

  /// No description provided for @invitedOn.
  ///
  /// In sr, this message translates to:
  /// **'Pozvan {date}'**
  String invitedOn(String date);

  /// No description provided for @noEmailProvided.
  ///
  /// In sr, this message translates to:
  /// **'E-pošta nije navedena'**
  String get noEmailProvided;

  /// No description provided for @invoiceLocalOnlyDesc.
  ///
  /// In sr, this message translates to:
  /// **'Račun se čuva samo lokalno. Možeš uključiti cloud backup u podešavanjima.'**
  String get invoiceLocalOnlyDesc;

  /// No description provided for @invoiceCloudSecureDesc.
  ///
  /// In sr, this message translates to:
  /// **'Račun je sačuvan na cloud-u. Vide ga samo stanar i vlasnik.'**
  String get invoiceCloudSecureDesc;

  /// No description provided for @invoiceUploadLimitDesc.
  ///
  /// In sr, this message translates to:
  /// **'JPEG, PNG ili PDF · maks. 10 MB'**
  String get invoiceUploadLimitDesc;

  /// No description provided for @billMissingLocalDesc.
  ///
  /// In sr, this message translates to:
  /// **'Račun je sačuvan lokalno na drugom uređaju. Uključi cloud backup da ga vidiš ovde.'**
  String get billMissingLocalDesc;

  /// No description provided for @documentMissingLocalDesc.
  ///
  /// In sr, this message translates to:
  /// **'Dokument je sačuvan lokalno na drugom uređaju. Uključi cloud backup da ga vidiš ovde.'**
  String get documentMissingLocalDesc;

  /// No description provided for @cannotOpenDocument.
  ///
  /// In sr, this message translates to:
  /// **'Nije moguće otvoriti dokument'**
  String get cannotOpenDocument;

  /// No description provided for @agencyAccount.
  ///
  /// In sr, this message translates to:
  /// **'Nalog agencije'**
  String get agencyAccount;

  /// No description provided for @managedProperties.
  ///
  /// In sr, this message translates to:
  /// **'Upravljane nekretnine'**
  String get managedProperties;

  /// No description provided for @paymentApprovalQueue.
  ///
  /// In sr, this message translates to:
  /// **'Red za odobrenje plaćanja'**
  String get paymentApprovalQueue;

  /// No description provided for @noPendingPaymentApprovals.
  ///
  /// In sr, this message translates to:
  /// **'Nema plaćanja na čekanju'**
  String get noPendingPaymentApprovals;

  /// No description provided for @noManagedPropertiesYet.
  ///
  /// In sr, this message translates to:
  /// **'Još nema upravljanih nekretnina'**
  String get noManagedPropertiesYet;

  /// No description provided for @occupied.
  ///
  /// In sr, this message translates to:
  /// **'Zauzeto'**
  String get occupied;

  /// No description provided for @dueDateShort.
  ///
  /// In sr, this message translates to:
  /// **'Rok: {date}'**
  String dueDateShort(String date);

  /// No description provided for @payment.
  ///
  /// In sr, this message translates to:
  /// **'Plaćanje'**
  String get payment;

  /// No description provided for @insightPendingApprovalsTitle.
  ///
  /// In sr, this message translates to:
  /// **'Čekaju odobrenje'**
  String get insightPendingApprovalsTitle;

  /// No description provided for @insightPendingApprovalsDesc.
  ///
  /// In sr, this message translates to:
  /// **'Imate nekretnine za koje stanodavac ili zakupci još nisu prihvatili poziv.'**
  String get insightPendingApprovalsDesc;

  /// No description provided for @insightPendingApprovalsAction.
  ///
  /// In sr, this message translates to:
  /// **'Prikaži povezane nekretnine'**
  String get insightPendingApprovalsAction;

  /// No description provided for @insightWithoutContractsTitle.
  ///
  /// In sr, this message translates to:
  /// **'Nekretnine bez ugovora'**
  String get insightWithoutContractsTitle;

  /// No description provided for @insightWithoutContractsDesc.
  ///
  /// In sr, this message translates to:
  /// **'Imate nekretnine registrovane u sistemu, ali za njih još nije priložen ugovor.'**
  String get insightWithoutContractsDesc;

  /// No description provided for @insightWithoutContractsAction.
  ///
  /// In sr, this message translates to:
  /// **'Prikaži povezane nekretnine'**
  String get insightWithoutContractsAction;

  /// No description provided for @insightExpiredContractsTitle.
  ///
  /// In sr, this message translates to:
  /// **'Istekli ugovori'**
  String get insightExpiredContractsTitle;

  /// No description provided for @insightExpiredContractsDesc.
  ///
  /// In sr, this message translates to:
  /// **'Imate nekretnine sa isteklim ugovorima koji nisu obnovljeni. Molimo preduzmite mere.'**
  String get insightExpiredContractsDesc;

  /// No description provided for @insightExpiredContractsAction.
  ///
  /// In sr, this message translates to:
  /// **'Prikaži povezane nekretnine'**
  String get insightExpiredContractsAction;

  /// No description provided for @insightExpiringContractsTitle.
  ///
  /// In sr, this message translates to:
  /// **'Ugovori koji uskoro ističu'**
  String get insightExpiringContractsTitle;

  /// No description provided for @insightExpiringContractsDesc.
  ///
  /// In sr, this message translates to:
  /// **'Imate nekretnine kojima je ostalo manje od mesec dana do isteka poslednjeg aktivnog ugovora.'**
  String get insightExpiringContractsDesc;

  /// No description provided for @insightExpiringContractsAction.
  ///
  /// In sr, this message translates to:
  /// **'Prikaži povezane nekretnine'**
  String get insightExpiringContractsAction;

  /// No description provided for @tabHome.
  ///
  /// In sr, this message translates to:
  /// **'Početna'**
  String get tabHome;

  /// No description provided for @tabFinance.
  ///
  /// In sr, this message translates to:
  /// **'Finansije'**
  String get tabFinance;

  /// No description provided for @tabRequests.
  ///
  /// In sr, this message translates to:
  /// **'Zahtevi'**
  String get tabRequests;

  /// No description provided for @tabPortfolio.
  ///
  /// In sr, this message translates to:
  /// **'Portfolio'**
  String get tabPortfolio;

  /// No description provided for @agencyAddProperty.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj nekretninu'**
  String get agencyAddProperty;

  /// No description provided for @searchAndFilterPanel.
  ///
  /// In sr, this message translates to:
  /// **'Pretraga i detaljni filteri'**
  String get searchAndFilterPanel;

  /// No description provided for @searchPlaceholder.
  ///
  /// In sr, this message translates to:
  /// **'Pretraži vlasnika, stanara, grad ili nekretninu...'**
  String get searchPlaceholder;

  /// No description provided for @filterAppliedLabel.
  ///
  /// In sr, this message translates to:
  /// **'Primenjen filter: {title}'**
  String filterAppliedLabel(String title);

  /// No description provided for @noPropertiesMatchingFilter.
  ///
  /// In sr, this message translates to:
  /// **'Nema nekretnina koje odgovaraju filteru'**
  String get noPropertiesMatchingFilter;

  /// No description provided for @groupNone.
  ///
  /// In sr, this message translates to:
  /// **'Grupljanje Yok'**
  String get groupNone;

  /// No description provided for @groupByLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Grupiši: Vlasnik'**
  String get groupByLandlord;

  /// No description provided for @groupByCity.
  ///
  /// In sr, this message translates to:
  /// **'Grupiši: Grad'**
  String get groupByCity;

  /// No description provided for @groupByStatus.
  ///
  /// In sr, this message translates to:
  /// **'Grupiši: Status'**
  String get groupByStatus;

  /// No description provided for @groupByDebtConsent.
  ///
  /// In sr, this message translates to:
  /// **'Grupiši: Dug / Odobrenje'**
  String get groupByDebtConsent;

  /// No description provided for @sortByNewest.
  ///
  /// In sr, this message translates to:
  /// **'Sortiraj: Najnovije'**
  String get sortByNewest;

  /// No description provided for @sortByOldest.
  ///
  /// In sr, this message translates to:
  /// **'Sortiraj: Najstarije'**
  String get sortByOldest;

  /// No description provided for @sortByDebt.
  ///
  /// In sr, this message translates to:
  /// **'Sortiraj: Prvo dužnici'**
  String get sortByDebt;

  /// No description provided for @sortByRentDesc.
  ///
  /// In sr, this message translates to:
  /// **'Sortiraj: Zakupnina (opadajuće)'**
  String get sortByRentDesc;

  /// No description provided for @sortByRentAsc.
  ///
  /// In sr, this message translates to:
  /// **'Sortiraj: Zakupnina (rastuće)'**
  String get sortByRentAsc;

  /// No description provided for @sortByAmountDesc.
  ///
  /// In sr, this message translates to:
  /// **'Sortiraj: Iznos (opadajuće)'**
  String get sortByAmountDesc;

  /// No description provided for @sortByAmountAsc.
  ///
  /// In sr, this message translates to:
  /// **'Sortiraj: Iznos (rastuće)'**
  String get sortByAmountAsc;

  /// No description provided for @sortByNameAsc.
  ///
  /// In sr, this message translates to:
  /// **'Sortiraj: Nekretnina A-Z'**
  String get sortByNameAsc;

  /// No description provided for @sortByCityAsc.
  ///
  /// In sr, this message translates to:
  /// **'Sortiraj: Grad A-Z'**
  String get sortByCityAsc;

  /// No description provided for @sortByLandlordAsc.
  ///
  /// In sr, this message translates to:
  /// **'Sortiraj: Vlasnik A-Z'**
  String get sortByLandlordAsc;

  /// No description provided for @viewModeTable.
  ///
  /// In sr, this message translates to:
  /// **'Tabela'**
  String get viewModeTable;

  /// No description provided for @viewModeGrid.
  ///
  /// In sr, this message translates to:
  /// **'Kartice'**
  String get viewModeGrid;

  /// No description provided for @statusLabel.
  ///
  /// In sr, this message translates to:
  /// **'STATUS'**
  String get statusLabel;

  /// No description provided for @statusOverdue.
  ///
  /// In sr, this message translates to:
  /// **'U kašnjenju'**
  String get statusOverdue;

  /// No description provided for @statusClean.
  ///
  /// In sr, this message translates to:
  /// **'Uredno'**
  String get statusClean;

  /// No description provided for @colPropertyAndType.
  ///
  /// In sr, this message translates to:
  /// **'NEKRETNINA I TIP'**
  String get colPropertyAndType;

  /// No description provided for @colDueDate.
  ///
  /// In sr, this message translates to:
  /// **'ROK'**
  String get colDueDate;

  /// No description provided for @colAmount.
  ///
  /// In sr, this message translates to:
  /// **'IZNOS'**
  String get colAmount;

  /// No description provided for @colAction.
  ///
  /// In sr, this message translates to:
  /// **'AKCIJA'**
  String get colAction;

  /// No description provided for @unenteredBillsTitle.
  ///
  /// In sr, this message translates to:
  /// **'Neuneti računi'**
  String get unenteredBillsTitle;

  /// No description provided for @cashBadge.
  ///
  /// In sr, this message translates to:
  /// **'Gotovina'**
  String get cashBadge;

  /// No description provided for @filterRent.
  ///
  /// In sr, this message translates to:
  /// **'Kirija'**
  String get filterRent;

  /// No description provided for @filterBills.
  ///
  /// In sr, this message translates to:
  /// **'Računi'**
  String get filterBills;

  /// No description provided for @filterDeposit.
  ///
  /// In sr, this message translates to:
  /// **'Depozit'**
  String get filterDeposit;

  /// No description provided for @filterDues.
  ///
  /// In sr, this message translates to:
  /// **'Komunalije'**
  String get filterDues;

  /// No description provided for @allPropertiesGroup.
  ///
  /// In sr, this message translates to:
  /// **'Sve nekretnine'**
  String get allPropertiesGroup;

  /// No description provided for @groupLandlordPendingInvite.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnici koji čekaju pozivnicu'**
  String get groupLandlordPendingInvite;

  /// No description provided for @groupUnspecifiedCity.
  ///
  /// In sr, this message translates to:
  /// **'Grad nije naveden'**
  String get groupUnspecifiedCity;

  /// No description provided for @groupStatusOccupied.
  ///
  /// In sr, this message translates to:
  /// **'Iznajmljene nekretnine'**
  String get groupStatusOccupied;

  /// No description provided for @groupStatusVacant.
  ///
  /// In sr, this message translates to:
  /// **'Prazne nekretnine'**
  String get groupStatusVacant;

  /// No description provided for @groupStatusLandlordPending.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik čeka pozivnicu'**
  String get groupStatusLandlordPending;

  /// No description provided for @groupDebtPending.
  ///
  /// In sr, this message translates to:
  /// **'Nekretnine sa dugom'**
  String get groupDebtPending;

  /// No description provided for @groupConsentPending.
  ///
  /// In sr, this message translates to:
  /// **'Čeka odobrenje / pristanak'**
  String get groupConsentPending;

  /// No description provided for @groupActiveClean.
  ///
  /// In sr, this message translates to:
  /// **'Nekretnine bez duga'**
  String get groupActiveClean;

  /// No description provided for @filterAllCount.
  ///
  /// In sr, this message translates to:
  /// **'Sve ({count})'**
  String filterAllCount(int count);

  /// No description provided for @filterHasDebtCount.
  ///
  /// In sr, this message translates to:
  /// **'⚠️ Sa dugom ({count})'**
  String filterHasDebtCount(int count);

  /// No description provided for @filterOccupiedCount.
  ///
  /// In sr, this message translates to:
  /// **'🟢 Zauzeto ({count})'**
  String filterOccupiedCount(int count);

  /// No description provided for @filterVacantCount.
  ///
  /// In sr, this message translates to:
  /// **'🟡 Slobodno ({count})'**
  String filterVacantCount(int count);

  /// No description provided for @filterActiveLabel.
  ///
  /// In sr, this message translates to:
  /// **'Filter aktivan ✓'**
  String get filterActiveLabel;

  /// No description provided for @financeAndPaymentsHeader.
  ///
  /// In sr, this message translates to:
  /// **'Finansije i plaćanja'**
  String get financeAndPaymentsHeader;

  /// No description provided for @financialSummaryTitle.
  ///
  /// In sr, this message translates to:
  /// **'Finansijski pregled'**
  String get financialSummaryTitle;

  /// No description provided for @pendingPaymentsSummary.
  ///
  /// In sr, this message translates to:
  /// **'{count} odobrenja plaćanja na čekanju'**
  String pendingPaymentsSummary(int count);

  /// No description provided for @financePlaceholderDesc.
  ///
  /// In sr, this message translates to:
  /// **'Finansijski dijagrami, praćenje zakupnine i istorija plaćanja biće uskoro dostupni.'**
  String get financePlaceholderDesc;

  /// No description provided for @maintenanceRequestsHeader.
  ///
  /// In sr, this message translates to:
  /// **'Zahtevi za održavanje i popravke'**
  String get maintenanceRequestsHeader;

  /// No description provided for @requestManagementTitle.
  ///
  /// In sr, this message translates to:
  /// **'Upravljanje zahtevima'**
  String get requestManagementTitle;

  /// No description provided for @requestsPlaceholderDesc.
  ///
  /// In sr, this message translates to:
  /// **'Zahtevi za popravku i podršku od stanara i vlasnika uskoro će se upravljati sa ovog kartica.'**
  String get requestsPlaceholderDesc;

  /// No description provided for @noOpenRequestsYet.
  ///
  /// In sr, this message translates to:
  /// **'Nema otvorenih zahteva'**
  String get noOpenRequestsYet;

  /// No description provided for @actionableInsightsHeader.
  ///
  /// In sr, this message translates to:
  /// **'Poruke za akciju'**
  String get actionableInsightsHeader;

  /// No description provided for @inviteTenantOrAddContract.
  ///
  /// In sr, this message translates to:
  /// **'Pozovi stanara / Dodaj ugovor'**
  String get inviteTenantOrAddContract;

  /// No description provided for @ownershipQrOrLink.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnički QR / Link'**
  String get ownershipQrOrLink;

  /// No description provided for @changeLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Promeni vlasnika'**
  String get changeLandlord;

  /// No description provided for @pendingDebtWarning.
  ///
  /// In sr, this message translates to:
  /// **'Dugovanje čeka odobrenje agencije ili uplatu stanara'**
  String get pendingDebtWarning;

  /// No description provided for @landlordLabel.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik: '**
  String get landlordLabel;

  /// No description provided for @invitePending.
  ///
  /// In sr, this message translates to:
  /// **'Čeka pozivnicu'**
  String get invitePending;

  /// No description provided for @tenantLabel.
  ///
  /// In sr, this message translates to:
  /// **'Stanar: '**
  String get tenantLabel;

  /// No description provided for @vacantLabel.
  ///
  /// In sr, this message translates to:
  /// **'Slobodno'**
  String get vacantLabel;

  /// No description provided for @latestContractNone.
  ///
  /// In sr, this message translates to:
  /// **'Poslednji ugovor: Nema'**
  String get latestContractNone;

  /// No description provided for @unlimited.
  ///
  /// In sr, this message translates to:
  /// **'Neodređeno'**
  String get unlimited;

  /// No description provided for @contractDateRange.
  ///
  /// In sr, this message translates to:
  /// **'Ugovor: {dates}'**
  String contractDateRange(String dates);

  /// No description provided for @cashPayment.
  ///
  /// In sr, this message translates to:
  /// **'Gotovinsko plaćanje'**
  String get cashPayment;

  /// No description provided for @changeLandlordDialogTitle.
  ///
  /// In sr, this message translates to:
  /// **'Promeni vlasnika / Pošalji pozivnicu'**
  String get changeLandlordDialogTitle;

  /// No description provided for @changeLandlordDialogDesc.
  ///
  /// In sr, this message translates to:
  /// **'Unesite kontakt podatke novog vlasnika. Postojeće vlasništvo biće resetovano i generisan novi QR/Link.'**
  String get changeLandlordDialogDesc;

  /// No description provided for @phone.
  ///
  /// In sr, this message translates to:
  /// **'Broj telefona'**
  String get phone;

  /// No description provided for @error.
  ///
  /// In sr, this message translates to:
  /// **'Greška'**
  String get error;

  /// No description provided for @changeAndGenerateQr.
  ///
  /// In sr, this message translates to:
  /// **'Promeni i generiši QR'**
  String get changeAndGenerateQr;

  /// No description provided for @financePendingApprovals.
  ///
  /// In sr, this message translates to:
  /// **'Čekaju odobrenje'**
  String get financePendingApprovals;

  /// No description provided for @financeOverduePayments.
  ///
  /// In sr, this message translates to:
  /// **'Dugovanja u kašnjenju'**
  String get financeOverduePayments;

  /// No description provided for @financePaidThisMonth.
  ///
  /// In sr, this message translates to:
  /// **'Odobreno ovog meseca'**
  String get financePaidThisMonth;

  /// No description provided for @financeRentCollected.
  ///
  /// In sr, this message translates to:
  /// **'Kirija naplaćena od zakupaca'**
  String get financeRentCollected;

  /// No description provided for @financeBillsCollected.
  ///
  /// In sr, this message translates to:
  /// **'Racuni naplaceni od zakupaca'**
  String get financeBillsCollected;

  /// No description provided for @financeBillsToInstitutions.
  ///
  /// In sr, this message translates to:
  /// **'Racuni placeni institucijama'**
  String get financeBillsToInstitutions;

  /// No description provided for @financeBillsToInstitutionsTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Racuni naplaceni od zakupaca smatraju se placenim institucijama.'**
  String get financeBillsToInstitutionsTooltip;

  /// No description provided for @financeMaintenancePaid.
  ///
  /// In sr, this message translates to:
  /// **'Placeni troskovi odrzavanja'**
  String get financeMaintenancePaid;

  /// No description provided for @financeMaintenanceOwedToAgency.
  ///
  /// In sr, this message translates to:
  /// **'Dug agenciji za odrzavanje'**
  String get financeMaintenanceOwedToAgency;

  /// No description provided for @financeMaintenanceOwedToAgencyTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Racuni naplaceni od zakupaca smatraju se placenim agenciji.'**
  String get financeMaintenanceOwedToAgencyTooltip;

  /// No description provided for @periodThisMonth.
  ///
  /// In sr, this message translates to:
  /// **'Ovaj mesec'**
  String get periodThisMonth;

  /// No description provided for @periodLastMonth.
  ///
  /// In sr, this message translates to:
  /// **'Prošli mesec'**
  String get periodLastMonth;

  /// No description provided for @periodThisYear.
  ///
  /// In sr, this message translates to:
  /// **'Ova godina'**
  String get periodThisYear;

  /// No description provided for @periodLastYear.
  ///
  /// In sr, this message translates to:
  /// **'Prošla godina'**
  String get periodLastYear;

  /// No description provided for @periodAllTime.
  ///
  /// In sr, this message translates to:
  /// **'Od početka'**
  String get periodAllTime;

  /// No description provided for @periodCustom.
  ///
  /// In sr, this message translates to:
  /// **'Posebno'**
  String get periodCustom;

  /// No description provided for @financeUpcoming7Days.
  ///
  /// In sr, this message translates to:
  /// **'Nadolazeća (7 dana)'**
  String get financeUpcoming7Days;

  /// No description provided for @tabPendingQueue.
  ///
  /// In sr, this message translates to:
  /// **'Red za odobrenje'**
  String get tabPendingQueue;

  /// No description provided for @tabOverdueList.
  ///
  /// In sr, this message translates to:
  /// **'Dužnici'**
  String get tabOverdueList;

  /// No description provided for @tabAllHistory.
  ///
  /// In sr, this message translates to:
  /// **'Istorija plaćanja'**
  String get tabAllHistory;

  /// No description provided for @approvePayment.
  ///
  /// In sr, this message translates to:
  /// **'Odobri'**
  String get approvePayment;

  /// No description provided for @rejectPayment.
  ///
  /// In sr, this message translates to:
  /// **'Odbij'**
  String get rejectPayment;

  /// No description provided for @markAsCashPaid.
  ///
  /// In sr, this message translates to:
  /// **'Označi kao plaćeno gotovinom'**
  String get markAsCashPaid;

  /// No description provided for @sendReminder.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji podsetnik'**
  String get sendReminder;

  /// No description provided for @daysOverdue.
  ///
  /// In sr, this message translates to:
  /// **'Kasni {count} dana'**
  String daysOverdue(int count);

  /// No description provided for @noFinanceRecords.
  ///
  /// In sr, this message translates to:
  /// **'Nema zapisa u ovoj kategoriji'**
  String get noFinanceRecords;

  /// No description provided for @reminderMessageCopied.
  ///
  /// In sr, this message translates to:
  /// **'Poruka podsetnika je kopirana'**
  String get reminderMessageCopied;

  /// No description provided for @tenantNoPropertyTitle.
  ///
  /// In sr, this message translates to:
  /// **'Još niste povezani sa nekretninom.'**
  String get tenantNoPropertyTitle;

  /// No description provided for @tenantNoPropertyTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Još niste povezani sa nekretninom.'**
  String get tenantNoPropertyTooltip;

  /// No description provided for @tenantNoPropertyMaintenanceTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Još niste povezani sa nekretninom.\nDa biste podneli zahtev za održavanje, prvo se pridružite nekretnini.'**
  String get tenantNoPropertyMaintenanceTooltip;

  /// No description provided for @joinWithQrCode.
  ///
  /// In sr, this message translates to:
  /// **'Pridruži se domu putem QR / pozivnog koda'**
  String get joinWithQrCode;

  /// No description provided for @agencyPropertyTakeoverQr.
  ///
  /// In sr, this message translates to:
  /// **'Preuzmi nekretninu agencije putem QR koda'**
  String get agencyPropertyTakeoverQr;

  /// No description provided for @welcomeUser.
  ///
  /// In sr, this message translates to:
  /// **'Dobrodošli, {userName} 👋'**
  String welcomeUser(String userName);

  /// No description provided for @overduePaymentReminderMessage.
  ///
  /// In sr, this message translates to:
  /// **'Poštovani/a {tenantName}, vaša uplata od {amount} {currency} za nekretninu {propertyName} je prekoračila rok. Molimo vas da izvršite uplatu i pošaljete uplatnicu.'**
  String overduePaymentReminderMessage(
    String tenantName,
    String propertyName,
    String amount,
    String currency,
  );

  /// No description provided for @heroHeadline.
  ///
  /// In sr, this message translates to:
  /// **'Upravljajte vašim nekretninama iz jednog panela'**
  String get heroHeadline;

  /// No description provided for @heroSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Praćenje stanara, evidencija uplata i detalji o nekretninama — sve na jednom mestu.'**
  String get heroSubtitle;

  /// No description provided for @forgotPassword.
  ///
  /// In sr, this message translates to:
  /// **'Zaboravili ste lozinku?'**
  String get forgotPassword;

  /// No description provided for @copy.
  ///
  /// In sr, this message translates to:
  /// **'Kopiraj'**
  String get copy;

  /// No description provided for @showLandlordInviteQrOrLink.
  ///
  /// In sr, this message translates to:
  /// **'Prikaži QR kod / vezu vlasništva'**
  String get showLandlordInviteQrOrLink;

  /// No description provided for @showLandlordInviteQrOrLinkClaimed.
  ///
  /// In sr, this message translates to:
  /// **'QR kod / veza vlasništva'**
  String get showLandlordInviteQrOrLinkClaimed;

  /// No description provided for @landlordOwnershipInviteTitle.
  ///
  /// In sr, this message translates to:
  /// **'Pozivnica za vlasništvo nad nekretninom'**
  String get landlordOwnershipInviteTitle;

  /// No description provided for @becomeLandlordTitle.
  ///
  /// In sr, this message translates to:
  /// **'Postanite vlasnik nekretnine {propertyName}'**
  String becomeLandlordTitle(String propertyName);

  /// No description provided for @landlordInviteAcceptDesc.
  ///
  /// In sr, this message translates to:
  /// **'Potvrdite pozivnicu da biste bili dodeljeni i upravljali ovom nekretninom kojom upravlja agencija.'**
  String get landlordInviteAcceptDesc;

  /// No description provided for @acceptAsLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Prihvati kao vlasnik'**
  String get acceptAsLandlord;

  /// No description provided for @landlordAcceptedInviteTitle.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je prihvatio pozivnicu!'**
  String get landlordAcceptedInviteTitle;

  /// No description provided for @landlordOwnershipTransferredDesc.
  ///
  /// In sr, this message translates to:
  /// **'Vlasništvo nad nekretninom {propertyName} je uspešno preneto.'**
  String landlordOwnershipTransferredDesc(String propertyName);

  /// No description provided for @landlordShareQrInstruction.
  ///
  /// In sr, this message translates to:
  /// **'Neka vlasnik skenira ovaj QR kod ili mu pošaljite vezu.'**
  String get landlordShareQrInstruction;

  /// No description provided for @ownershipLinkCopied.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnička veza je kopirana!'**
  String get ownershipLinkCopied;

  /// No description provided for @landlordShareMessage.
  ///
  /// In sr, this message translates to:
  /// **'Zdravo {landlordName}, kliknite na ovu vezu da preuzmete vlasništvo nad nekretninom \"{propertyName}\" na Stanomeru:\n{inviteUrl}'**
  String landlordShareMessage(
    String landlordName,
    String propertyName,
    String inviteUrl,
  );

  /// No description provided for @joinHomeTitle.
  ///
  /// In sr, this message translates to:
  /// **'Pridruži se domu'**
  String get joinHomeTitle;

  /// No description provided for @joinHomeSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Skenirajte QR kod ili unesite vezu/kod pozivnice.'**
  String get joinHomeSubtitle;

  /// No description provided for @closeCamera.
  ///
  /// In sr, this message translates to:
  /// **'Zatvori kameru'**
  String get closeCamera;

  /// No description provided for @scanQrCodeBtn.
  ///
  /// In sr, this message translates to:
  /// **'Skeniraj QR kod'**
  String get scanQrCodeBtn;

  /// No description provided for @inviteLinkOrTokenLabel.
  ///
  /// In sr, this message translates to:
  /// **'Veza pozivnice ili token kod'**
  String get inviteLinkOrTokenLabel;

  /// No description provided for @inviteLinkOrTokenHint.
  ///
  /// In sr, this message translates to:
  /// **'https://.../invite?token=... ili kod'**
  String get inviteLinkOrTokenHint;

  /// No description provided for @paste.
  ///
  /// In sr, this message translates to:
  /// **'Zalepi'**
  String get paste;

  /// No description provided for @joinAndReview.
  ///
  /// In sr, this message translates to:
  /// **'Pridruži se i pregledaj'**
  String get joinAndReview;

  /// No description provided for @invalidInviteCodeOrLink.
  ///
  /// In sr, this message translates to:
  /// **'Molimo unesite važeću vezu ili kod pozivnice.'**
  String get invalidInviteCodeOrLink;

  /// No description provided for @landlordOwnershipTransferredSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Čestitamo! Vlasništvo nad nekretninom je uspešno preneto na vaš nalog.'**
  String get landlordOwnershipTransferredSuccess;

  /// No description provided for @landlordOwnershipInviteInvalid.
  ///
  /// In sr, this message translates to:
  /// **'Pozivnica za vlasništvo je nevažeća, istekla ili je već prihvaćena.'**
  String get landlordOwnershipInviteInvalid;

  /// No description provided for @statusApproved.
  ///
  /// In sr, this message translates to:
  /// **'Potvrđeno'**
  String get statusApproved;

  /// No description provided for @referringAgency.
  ///
  /// In sr, this message translates to:
  /// **'Agencija Koja Je Preporučila'**
  String get referringAgency;

  /// No description provided for @noReferringAgency.
  ///
  /// In sr, this message translates to:
  /// **'Nemate Preporučenu Agenciju'**
  String get noReferringAgency;

  /// No description provided for @noReferringAgencyDesc.
  ///
  /// In sr, this message translates to:
  /// **'Ako vas je preporučila agencija za nekretnine, skenirajte QR kod vaše agencije da povežete nalog.'**
  String get noReferringAgencyDesc;

  /// No description provided for @scanAgencyReferralQrBtn.
  ///
  /// In sr, this message translates to:
  /// **'Skeniraj Referral QR Kod Agencije'**
  String get scanAgencyReferralQrBtn;

  /// No description provided for @referralCodeLabel.
  ///
  /// In sr, this message translates to:
  /// **'Referral Kod'**
  String get referralCodeLabel;

  /// No description provided for @detailedEntry.
  ///
  /// In sr, this message translates to:
  /// **'Napredne informacije'**
  String get detailedEntry;

  /// No description provided for @detailedEntrySubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Svi detalji o nekretnini, strukturne metrike i parametri oglasa.'**
  String get detailedEntrySubtitle;

  /// No description provided for @propertyAndLocationInfo.
  ///
  /// In sr, this message translates to:
  /// **'Informacije o Nekretnini i Lokaciji'**
  String get propertyAndLocationInfo;

  /// No description provided for @propertyTypeLabel.
  ///
  /// In sr, this message translates to:
  /// **'Tip Nekretnine'**
  String get propertyTypeLabel;

  /// No description provided for @propertyTypeApartment.
  ///
  /// In sr, this message translates to:
  /// **'Stan'**
  String get propertyTypeApartment;

  /// No description provided for @propertyTypeHouse.
  ///
  /// In sr, this message translates to:
  /// **'Kuća'**
  String get propertyTypeHouse;

  /// No description provided for @propertyTypeCommercial.
  ///
  /// In sr, this message translates to:
  /// **'Poslovni Prostor'**
  String get propertyTypeCommercial;

  /// No description provided for @propertyTypeGarage.
  ///
  /// In sr, this message translates to:
  /// **'Garaža'**
  String get propertyTypeGarage;

  /// No description provided for @unitNumberLabel.
  ///
  /// In sr, this message translates to:
  /// **'Broj Stana / Jedinice'**
  String get unitNumberLabel;

  /// No description provided for @unitNumberHint.
  ///
  /// In sr, this message translates to:
  /// **'Npr: 4 ili 12B'**
  String get unitNumberHint;

  /// No description provided for @addressDetailedHint.
  ///
  /// In sr, this message translates to:
  /// **'Unesite grad, opštinu, naselje ili ulicu...'**
  String get addressDetailedHint;

  /// No description provided for @structuralAndFinancialMetrics.
  ///
  /// In sr, this message translates to:
  /// **'Strukturne i Finansijske Metrike'**
  String get structuralAndFinancialMetrics;

  /// No description provided for @roomCountLabel.
  ///
  /// In sr, this message translates to:
  /// **'Struktura (Broj Soba)'**
  String get roomCountLabel;

  /// No description provided for @areaSqmLabel.
  ///
  /// In sr, this message translates to:
  /// **'Površina'**
  String get areaSqmLabel;

  /// No description provided for @floorLevelLabel.
  ///
  /// In sr, this message translates to:
  /// **'Sprat'**
  String get floorLevelLabel;

  /// No description provided for @totalFloorsLabel.
  ///
  /// In sr, this message translates to:
  /// **'Ukupno Spratova u Zgradi'**
  String get totalFloorsLabel;

  /// No description provided for @equipmentAndHeatingStandards.
  ///
  /// In sr, this message translates to:
  /// **'Standardi Opreme i Grejanja'**
  String get equipmentAndHeatingStandards;

  /// No description provided for @furnishingLabel.
  ///
  /// In sr, this message translates to:
  /// **'Nameštenost'**
  String get furnishingLabel;

  /// No description provided for @furnishingFurnished.
  ///
  /// In sr, this message translates to:
  /// **'Namešten'**
  String get furnishingFurnished;

  /// No description provided for @furnishingFurnishedDesc.
  ///
  /// In sr, this message translates to:
  /// **'Kompletno Namešten'**
  String get furnishingFurnishedDesc;

  /// No description provided for @furnishingSemi.
  ///
  /// In sr, this message translates to:
  /// **'Polunamešten'**
  String get furnishingSemi;

  /// No description provided for @furnishingSemiDesc.
  ///
  /// In sr, this message translates to:
  /// **'Samo Kuhinja i Kupatilo'**
  String get furnishingSemiDesc;

  /// No description provided for @furnishingUnfurnished.
  ///
  /// In sr, this message translates to:
  /// **'Nenamešten'**
  String get furnishingUnfurnished;

  /// No description provided for @furnishingUnfurnishedDesc.
  ///
  /// In sr, this message translates to:
  /// **'Prazan / Bez Nameštaja'**
  String get furnishingUnfurnishedDesc;

  /// No description provided for @heatingTypeLabel.
  ///
  /// In sr, this message translates to:
  /// **'Tip Grejanja'**
  String get heatingTypeLabel;

  /// No description provided for @heatingCg.
  ///
  /// In sr, this message translates to:
  /// **'CG (Centralno grejanje)'**
  String get heatingCg;

  /// No description provided for @heatingEg.
  ///
  /// In sr, this message translates to:
  /// **'EG (Etažno grejanje - struja)'**
  String get heatingEg;

  /// No description provided for @heatingGas.
  ///
  /// In sr, this message translates to:
  /// **'Gas (Gasno grejanje)'**
  String get heatingGas;

  /// No description provided for @heatingUnderfloor.
  ///
  /// In sr, this message translates to:
  /// **'Podno grejanje'**
  String get heatingUnderfloor;

  /// No description provided for @heatingTa.
  ///
  /// In sr, this message translates to:
  /// **'TA Peć / Klima / Mermerni radijatori'**
  String get heatingTa;

  /// No description provided for @featuredAmenitiesLabel.
  ///
  /// In sr, this message translates to:
  /// **'Dodatne Pogodnosti (Dodatno)'**
  String get featuredAmenitiesLabel;

  /// No description provided for @amenityPets.
  ///
  /// In sr, this message translates to:
  /// **'Dozvoljeni kućni ljubimci'**
  String get amenityPets;

  /// No description provided for @amenityElevator.
  ///
  /// In sr, this message translates to:
  /// **'Lift'**
  String get amenityElevator;

  /// No description provided for @amenityBalcony.
  ///
  /// In sr, this message translates to:
  /// **'Terasa / Balkon / Lođa'**
  String get amenityBalcony;

  /// No description provided for @amenityParking.
  ///
  /// In sr, this message translates to:
  /// **'Garaža / Parking mesto'**
  String get amenityParking;

  /// No description provided for @amenityStorage.
  ///
  /// In sr, this message translates to:
  /// **'Podrum / Ostava'**
  String get amenityStorage;

  /// No description provided for @extendedDescriptionLabel.
  ///
  /// In sr, this message translates to:
  /// **'Opis Nekretnine (Detalji)'**
  String get extendedDescriptionLabel;

  /// No description provided for @extendedDescriptionHint.
  ///
  /// In sr, this message translates to:
  /// **'Unesite detalje o prevozu, zgradi, orijentaciji i uslovima...'**
  String get extendedDescriptionHint;

  /// No description provided for @clearFormBtn.
  ///
  /// In sr, this message translates to:
  /// **'Obriši Formu'**
  String get clearFormBtn;

  /// No description provided for @floorSuteren.
  ///
  /// In sr, this message translates to:
  /// **'Suteren (SUT)'**
  String get floorSuteren;

  /// No description provided for @floorPrizemlje.
  ///
  /// In sr, this message translates to:
  /// **'Prizemlje (PR)'**
  String get floorPrizemlje;

  /// No description provided for @floorVisokoPrizemlje.
  ///
  /// In sr, this message translates to:
  /// **'Visoko prizemlje (VPR)'**
  String get floorVisokoPrizemlje;

  /// No description provided for @floorNth.
  ///
  /// In sr, this message translates to:
  /// **'{floor}. sprat'**
  String floorNth(String floor);

  /// No description provided for @floorPotkrovlje.
  ///
  /// In sr, this message translates to:
  /// **'Potkrovlje (PK)'**
  String get floorPotkrovlje;

  /// No description provided for @floorOther.
  ///
  /// In sr, this message translates to:
  /// **'Ostali spratovi'**
  String get floorOther;

  /// No description provided for @statusOpen.
  ///
  /// In sr, this message translates to:
  /// **'Otvoreno'**
  String get statusOpen;

  /// No description provided for @statusInProgress.
  ///
  /// In sr, this message translates to:
  /// **'Poslat majstor'**
  String get statusInProgress;

  /// No description provided for @statusClosed.
  ///
  /// In sr, this message translates to:
  /// **'Zatvoreno'**
  String get statusClosed;

  /// No description provided for @statusCancelled.
  ///
  /// In sr, this message translates to:
  /// **'Otkazano'**
  String get statusCancelled;

  /// No description provided for @financialDetails.
  ///
  /// In sr, this message translates to:
  /// **'Finansijski Detalji'**
  String get financialDetails;

  /// No description provided for @financialStatusPendingReview.
  ///
  /// In sr, this message translates to:
  /// **'Na čekanju pregleda'**
  String get financialStatusPendingReview;

  /// No description provided for @financialStatusPendingAgencyApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka odobrenje agencije'**
  String get financialStatusPendingAgencyApproval;

  /// No description provided for @financialStatusPendingOppositeApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka odobrenje poravnanja'**
  String get financialStatusPendingOppositeApproval;

  /// No description provided for @financialStatusPendingPayment.
  ///
  /// In sr, this message translates to:
  /// **'Čeka uplatu'**
  String get financialStatusPendingPayment;

  /// No description provided for @financialStatusPaid.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeno'**
  String get financialStatusPaid;

  /// No description provided for @financialStatusRejected.
  ///
  /// In sr, this message translates to:
  /// **'Odbijeno'**
  String get financialStatusRejected;

  /// No description provided for @rejectionReasonRequired.
  ///
  /// In sr, this message translates to:
  /// **'Molimo unesite razlog odbijanja'**
  String get rejectionReasonRequired;

  /// No description provided for @payerTenant.
  ///
  /// In sr, this message translates to:
  /// **'Stanar'**
  String get payerTenant;

  /// No description provided for @payerLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik'**
  String get payerLandlord;

  /// No description provided for @payerTenantPaidOrWillPay.
  ///
  /// In sr, this message translates to:
  /// **'Stanar snosi / platio'**
  String get payerTenantPaidOrWillPay;

  /// No description provided for @payerLandlordWillCover.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik će pokriti'**
  String get payerLandlordWillCover;

  /// No description provided for @unassigned.
  ///
  /// In sr, this message translates to:
  /// **'Nije dodeljeno'**
  String get unassigned;

  /// No description provided for @noFinancialRecordTitle.
  ///
  /// In sr, this message translates to:
  /// **'Nema finansijskog zapisa'**
  String get noFinancialRecordTitle;

  /// No description provided for @noFinancialRecordDesc.
  ///
  /// In sr, this message translates to:
  /// **'Za ovaj zahtev za održavanje još uvek nije unet trošak ili račun.'**
  String get noFinancialRecordDesc;

  /// No description provided for @iPaidSubmitReceipt.
  ///
  /// In sr, this message translates to:
  /// **'Ja sam platio (Priloži račun)'**
  String get iPaidSubmitReceipt;

  /// No description provided for @resubmitExpenseIPaid.
  ///
  /// In sr, this message translates to:
  /// **'Ponovo prijavi trošak (Ja sam platio)'**
  String get resubmitExpenseIPaid;

  /// No description provided for @addCostInvoice.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj trošak / račun'**
  String get addCostInvoice;

  /// No description provided for @costPayerLabel.
  ///
  /// In sr, this message translates to:
  /// **'Odgovoran za trošak'**
  String get costPayerLabel;

  /// No description provided for @receiptInvoiceDocument.
  ///
  /// In sr, this message translates to:
  /// **'Račun / Fiskalni račun'**
  String get receiptInvoiceDocument;

  /// No description provided for @clickToViewDocument.
  ///
  /// In sr, this message translates to:
  /// **'Kliknite za pregled dokumenta'**
  String get clickToViewDocument;

  /// No description provided for @agencyExpenseApproval.
  ///
  /// In sr, this message translates to:
  /// **'Odobrenje troška od agencije'**
  String get agencyExpenseApproval;

  /// No description provided for @landlordExpenseApproval.
  ///
  /// In sr, this message translates to:
  /// **'Odobrenje troška od vlasnika'**
  String get landlordExpenseApproval;

  /// No description provided for @tenantExpenseApproval.
  ///
  /// In sr, this message translates to:
  /// **'Odobrenje troška od stanara'**
  String get tenantExpenseApproval;

  /// No description provided for @expenseApprovedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Trošak je uspešno odobren.'**
  String get expenseApprovedSuccess;

  /// No description provided for @expenseRejectedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Prijava troška je odbijena.'**
  String get expenseRejectedSuccess;

  /// No description provided for @rejectExpenseTitle.
  ///
  /// In sr, this message translates to:
  /// **'Odbij trošak'**
  String get rejectExpenseTitle;

  /// No description provided for @rejectExpenseConfirm.
  ///
  /// In sr, this message translates to:
  /// **'Da li ste sigurni da želite da odbijete prijavljeni trošak?'**
  String get rejectExpenseConfirm;

  /// No description provided for @rejectionReasonOptional.
  ///
  /// In sr, this message translates to:
  /// **'Razlog odbijanja (opciono)'**
  String get rejectionReasonOptional;

  /// No description provided for @quickActions.
  ///
  /// In sr, this message translates to:
  /// **'Brze Radnje'**
  String get quickActions;

  /// No description provided for @descriptionOrNoteOptional.
  ///
  /// In sr, this message translates to:
  /// **'Opis / Napomena (Opciono)'**
  String get descriptionOrNoteOptional;

  /// No description provided for @enterExpenseNoteHint.
  ///
  /// In sr, this message translates to:
  /// **'npr. Zamenjen ventil u kuhinji, uključujući rad majstora'**
  String get enterExpenseNoteHint;

  /// No description provided for @editFinancialDetails.
  ///
  /// In sr, this message translates to:
  /// **'Izmeni finansijske detalje'**
  String get editFinancialDetails;

  /// No description provided for @propertyInfo.
  ///
  /// In sr, this message translates to:
  /// **'Informacije o Nekretnini'**
  String get propertyInfo;

  /// No description provided for @coveredByLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je pokrio'**
  String get coveredByLandlord;

  /// No description provided for @coveredByTenant.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je pokrio'**
  String get coveredByTenant;

  /// No description provided for @landlordReimbursement.
  ///
  /// In sr, this message translates to:
  /// **'Refundacija od vlasnika'**
  String get landlordReimbursement;

  /// No description provided for @tenantToPay.
  ///
  /// In sr, this message translates to:
  /// **'Stanar plaća'**
  String get tenantToPay;

  /// No description provided for @landlordReimburseDesc.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je platio unapred. Vlasnik će refundirati ili umanjiti sledeću kiriju.'**
  String get landlordReimburseDesc;

  /// No description provided for @tenantToPayDesc.
  ///
  /// In sr, this message translates to:
  /// **'Trošak snosi stanar. Iznos će biti dodat na sledeću kiriju.'**
  String get tenantToPayDesc;

  /// No description provided for @coveredByLandlordClosedDesc.
  ///
  /// In sr, this message translates to:
  /// **'Pokriveno kao investiciono održavanje i zatvoreno.'**
  String get coveredByLandlordClosedDesc;

  /// No description provided for @coveredByTenantClosedDesc.
  ///
  /// In sr, this message translates to:
  /// **'Pokriveno kao tekuće održavanje stanara i zatvoreno.'**
  String get coveredByTenantClosedDesc;

  /// No description provided for @reEditFinancials.
  ///
  /// In sr, this message translates to:
  /// **'Ponovo izmeni finansije'**
  String get reEditFinancials;

  /// No description provided for @expenseRejectedDesc.
  ///
  /// In sr, this message translates to:
  /// **'Prethodno prijavljeni trošak nije odobren. Možete ponovo poslati sa tačnim iznosom i računom.'**
  String get expenseRejectedDesc;

  /// No description provided for @agencyManager.
  ///
  /// In sr, this message translates to:
  /// **'Menadžer agencije'**
  String get agencyManager;

  /// No description provided for @actorStatusInvestigating.
  ///
  /// In sr, this message translates to:
  /// **'🔍 {actor} je preuzeo zahtev na pregled.'**
  String actorStatusInvestigating(String actor);

  /// No description provided for @actorStatusInProgress.
  ///
  /// In sr, this message translates to:
  /// **'🔧 {actor} je poslao majstora, radovi su u toku.'**
  String actorStatusInProgress(String actor);

  /// No description provided for @actorStatusResolved.
  ///
  /// In sr, this message translates to:
  /// **'✅ {actor} je označio zahtev kao rešen.'**
  String actorStatusResolved(String actor);

  /// No description provided for @actorStatusClosed.
  ///
  /// In sr, this message translates to:
  /// **'🔒 {actor} je zatvorio zahtev.'**
  String actorStatusClosed(String actor);

  /// No description provided for @actorStatusReopened.
  ///
  /// In sr, this message translates to:
  /// **'🔄 {actor} je ponovo otvorio zahtev. Problem i dalje postoji.'**
  String actorStatusReopened(String actor);

  /// No description provided for @actorMarkedActive.
  ///
  /// In sr, this message translates to:
  /// **'📋 {actor} je postavio zahtev u aktivan status.'**
  String actorMarkedActive(String actor);

  /// No description provided for @actorUpdatedStatus.
  ///
  /// In sr, this message translates to:
  /// **'📌 {actor} je ažurirao status: {status}'**
  String actorUpdatedStatus(String actor, String status);

  /// No description provided for @submitExpenseReview.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi trošak (Pošalji na pregled)'**
  String get submitExpenseReview;

  /// No description provided for @pleaseEnterValidCost.
  ///
  /// In sr, this message translates to:
  /// **'Molimo unesite važeći plaćeni iznos.'**
  String get pleaseEnterValidCost;

  /// No description provided for @pleaseUploadReceipt.
  ///
  /// In sr, this message translates to:
  /// **'Molimo priložite račun ili uplatnicu.'**
  String get pleaseUploadReceipt;

  /// No description provided for @pleaseSelectCostPayer.
  ///
  /// In sr, this message translates to:
  /// **'Molimo izaberite ko snosi trošak.'**
  String get pleaseSelectCostPayer;

  /// No description provided for @noteLabel.
  ///
  /// In sr, this message translates to:
  /// **'Napomena'**
  String get noteLabel;

  /// No description provided for @amountPaid.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeni iznos'**
  String get amountPaid;

  /// No description provided for @costAmount.
  ///
  /// In sr, this message translates to:
  /// **'Iznos troška'**
  String get costAmount;

  /// No description provided for @costResponsibility.
  ///
  /// In sr, this message translates to:
  /// **'Ko je platio trošak?'**
  String get costResponsibility;

  /// No description provided for @whoPaidTheCost.
  ///
  /// In sr, this message translates to:
  /// **'Ko je platio trošak?'**
  String get whoPaidTheCost;

  /// No description provided for @paymentInvoiceStatus.
  ///
  /// In sr, this message translates to:
  /// **'Status uplate i računa'**
  String get paymentInvoiceStatus;

  /// No description provided for @paymentDueDate.
  ///
  /// In sr, this message translates to:
  /// **'Datum uplate / dospelosti'**
  String get paymentDueDate;

  /// No description provided for @noDate.
  ///
  /// In sr, this message translates to:
  /// **'Nema datuma'**
  String get noDate;

  /// No description provided for @uploadReceiptInvoice.
  ///
  /// In sr, this message translates to:
  /// **'Priloži račun / uplatnicu (PDF, Slika)'**
  String get uploadReceiptInvoice;

  /// No description provided for @uploadInvoiceDoc.
  ///
  /// In sr, this message translates to:
  /// **'Priloži fakturu'**
  String get uploadInvoiceDoc;

  /// No description provided for @existingDocument.
  ///
  /// In sr, this message translates to:
  /// **'Postojeći dokument'**
  String get existingDocument;

  /// No description provided for @change.
  ///
  /// In sr, this message translates to:
  /// **'Promeni'**
  String get change;

  /// No description provided for @enterAmountAttachReceipt.
  ///
  /// In sr, this message translates to:
  /// **'Unesite plaćeni iznos i priložite račun.'**
  String get enterAmountAttachReceipt;

  /// No description provided for @declaredAmountTitle.
  ///
  /// In sr, this message translates to:
  /// **'Prijavljeni iznos: {amount} • Izaberite ko je platio trošak:'**
  String declaredAmountTitle(String amount);

  /// No description provided for @expenseApprovalResponsibility.
  ///
  /// In sr, this message translates to:
  /// **'Odobrenje troška i odgovornost'**
  String get expenseApprovalResponsibility;

  /// No description provided for @landlordCoveredPaidTitle.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je pokrio (Označi kao plaćeno)'**
  String get landlordCoveredPaidTitle;

  /// No description provided for @landlordCoveredPaidSub.
  ///
  /// In sr, this message translates to:
  /// **'Trošak je na vlasniku (investiciono održavanje). Nema refundacije, zatvara se kao plaćeno.'**
  String get landlordCoveredPaidSub;

  /// No description provided for @landlordCoveredPaidBadge.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeno • Vlasnik'**
  String get landlordCoveredPaidBadge;

  /// No description provided for @tenantWillPayTitle.
  ///
  /// In sr, this message translates to:
  /// **'Stanar plaća (Dodati na kiriju)'**
  String get tenantWillPayTitle;

  /// No description provided for @tenantWillPaySub.
  ///
  /// In sr, this message translates to:
  /// **'Trošak je nastao upotrebom stanara. Iznos se dodaje na kiriju.'**
  String get tenantWillPaySub;

  /// No description provided for @tenantWillPayBadge.
  ///
  /// In sr, this message translates to:
  /// **'Čeka uplatu • Dug stanara'**
  String get tenantWillPayBadge;

  /// No description provided for @tenantPaidMarkAsPaidTitle.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je platio (Označi kao plaćeno)'**
  String get tenantPaidMarkAsPaidTitle;

  /// No description provided for @tenantPaidMarkAsPaidSub.
  ///
  /// In sr, this message translates to:
  /// **'Kvar je nastao upotrebom stanara. Iznos ostaje na stanaru, zatvoreno kao plaćeno.'**
  String get tenantPaidMarkAsPaidSub;

  /// No description provided for @tenantPaidMarkAsPaidBadge.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeno • Upotreba stanara'**
  String get tenantPaidMarkAsPaidBadge;

  /// No description provided for @landlordReimbursesTitle.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik refundira (Odbiti od kirije)'**
  String get landlordReimbursesTitle;

  /// No description provided for @landlordReimbursesSub.
  ///
  /// In sr, this message translates to:
  /// **'Trošak investicionog održavanja koji je platio stanar. Vlasnik refundira ili umanjuje kiriju.'**
  String get landlordReimbursesSub;

  /// No description provided for @landlordReimbursesBadge.
  ///
  /// In sr, this message translates to:
  /// **'Čeka uplatu • Odbitak od kirije'**
  String get landlordReimbursesBadge;

  /// No description provided for @propertyManagedByAgencyNotice.
  ///
  /// In sr, this message translates to:
  /// **'Nekretninom upravlja agencija. Samo agencija može menjati finansijske podatke.'**
  String get propertyManagedByAgencyNotice;

  /// No description provided for @agencyExpenseApprovedMsg.
  ///
  /// In sr, this message translates to:
  /// **'✅ Trošak odobren: {amount} (Odobrio {actor} • {details})'**
  String agencyExpenseApprovedMsg(String amount, String actor, String details);

  /// No description provided for @agencyExpenseRejectedMsg.
  ///
  /// In sr, this message translates to:
  /// **'❌ Prijavu troška je odbio {actor}'**
  String agencyExpenseRejectedMsg(String actor);

  /// No description provided for @reasonLabel.
  ///
  /// In sr, this message translates to:
  /// **'Razlog: {reason}'**
  String reasonLabel(String reason);

  /// No description provided for @roleYou.
  ///
  /// In sr, this message translates to:
  /// **'Vi'**
  String get roleYou;

  /// No description provided for @roleUser.
  ///
  /// In sr, this message translates to:
  /// **'Korisnik'**
  String get roleUser;

  /// No description provided for @landlordDeclaredExpenseSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je prijavio trošak od {amount}. Možete odobriti ili odbiti trošak.'**
  String landlordDeclaredExpenseSubtitle(String amount);

  /// No description provided for @tenantDeclaredExpenseSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je prijavio trošak od {amount}. Možete odobriti ili odbiti trošak.'**
  String tenantDeclaredExpenseSubtitle(String amount);

  /// No description provided for @expenseSubmittedForLandlordReview.
  ///
  /// In sr, this message translates to:
  /// **'Prijavljeni trošak je poslat vlasniku na pregled.'**
  String get expenseSubmittedForLandlordReview;

  /// No description provided for @expenseSubmittedForTenantReview.
  ///
  /// In sr, this message translates to:
  /// **'Prijavljeni trošak je poslat stanaru na pregled.'**
  String get expenseSubmittedForTenantReview;

  /// No description provided for @tblRequestProperty.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev & Nekretnina'**
  String get tblRequestProperty;

  /// No description provided for @tblPriority.
  ///
  /// In sr, this message translates to:
  /// **'Prioritet'**
  String get tblPriority;

  /// No description provided for @tblIssueStatus.
  ///
  /// In sr, this message translates to:
  /// **'Status kvara'**
  String get tblIssueStatus;

  /// No description provided for @tblCostPayer.
  ///
  /// In sr, this message translates to:
  /// **'Trošak & Platilac'**
  String get tblCostPayer;

  /// No description provided for @tblFinancialStatus.
  ///
  /// In sr, this message translates to:
  /// **'Finansijski status'**
  String get tblFinancialStatus;

  /// No description provided for @tblDate.
  ///
  /// In sr, this message translates to:
  /// **'Datum'**
  String get tblDate;

  /// No description provided for @dueDatePrefix.
  ///
  /// In sr, this message translates to:
  /// **'Rok'**
  String get dueDatePrefix;

  /// No description provided for @edit.
  ///
  /// In sr, this message translates to:
  /// **'Uredi'**
  String get edit;

  /// No description provided for @update.
  ///
  /// In sr, this message translates to:
  /// **'Ažuriraj'**
  String get update;

  /// No description provided for @paymentDate.
  ///
  /// In sr, this message translates to:
  /// **'Datum uplate'**
  String get paymentDate;

  /// No description provided for @profileUpdated.
  ///
  /// In sr, this message translates to:
  /// **'Uspešno sačuvano.'**
  String get profileUpdated;

  /// No description provided for @agencyPropertyTakeoverTitle.
  ///
  /// In sr, this message translates to:
  /// **'Preuzmi nekretninu dodatu od agencije'**
  String get agencyPropertyTakeoverTitle;

  /// No description provided for @agencyPropertyTakeoverDesc.
  ///
  /// In sr, this message translates to:
  /// **'Dodajte nekretninu koju je unela agencija na svoj nalog skeniranjem QR koda ili unosom pozivnog koda.'**
  String get agencyPropertyTakeoverDesc;

  /// No description provided for @scanQrOrEnterInviteCodeBtn.
  ///
  /// In sr, this message translates to:
  /// **'Skeniraj QR kod / Unesi kod pozivnice'**
  String get scanQrOrEnterInviteCodeBtn;

  /// No description provided for @settlementIntentTitle.
  ///
  /// In sr, this message translates to:
  /// **'Svrha plaćanja i obračun'**
  String get settlementIntentTitle;

  /// No description provided for @intentTenantSelfTitle.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je platio za sopstvenu upotrebu (Kvar usled korišćenja)'**
  String get intentTenantSelfTitle;

  /// No description provided for @intentTenantSelfSub.
  ///
  /// In sr, this message translates to:
  /// **'Trošak ostaje na stanaru. Ne traži se refundacija, zatvara se kao plaćeno.'**
  String get intentTenantSelfSub;

  /// No description provided for @intentTenantSelfBadge.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeno • Trošak stanara'**
  String get intentTenantSelfBadge;

  /// No description provided for @intentTenantReimburseTitle.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je platio za investiciono održavanje (U ime vlasnika)'**
  String get intentTenantReimburseTitle;

  /// No description provided for @intentTenantReimburseSub.
  ///
  /// In sr, this message translates to:
  /// **'Stanar je predujmio trošak demirbaša. Traži se odbitak od sledeće kirije ili refundacija.'**
  String get intentTenantReimburseSub;

  /// No description provided for @intentTenantReimburseBadge.
  ///
  /// In sr, this message translates to:
  /// **'Odbitak od kirije'**
  String get intentTenantReimburseBadge;

  /// No description provided for @intentLandlordSelfTitle.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je platio za investiciono održavanje (Demirbaš)'**
  String get intentLandlordSelfTitle;

  /// No description provided for @intentLandlordSelfSub.
  ///
  /// In sr, this message translates to:
  /// **'Trošak snosi vlasnik. Ne potražuje se od stanara, zatvara se kao plaćeno.'**
  String get intentLandlordSelfSub;

  /// No description provided for @intentLandlordSelfBadge.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeno • Vlasnik'**
  String get intentLandlordSelfBadge;

  /// No description provided for @intentLandlordTenantDueTitle.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik je platio za kvar usled upotrebe stanara (Na teret stanara)'**
  String get intentLandlordTenantDueTitle;

  /// No description provided for @intentLandlordTenantDueSub.
  ///
  /// In sr, this message translates to:
  /// **'Kvar je nastao upotrebom stanara. Iznos se dodaje na sledeću kiriju stanara.'**
  String get intentLandlordTenantDueSub;

  /// No description provided for @intentLandlordTenantDueBadge.
  ///
  /// In sr, this message translates to:
  /// **'Dug stanara'**
  String get intentLandlordTenantDueBadge;

  /// No description provided for @pleaseSelectDeclarationIntent.
  ///
  /// In sr, this message translates to:
  /// **'Molimo izaberite svrhu plaćanja i predlog obračuna.'**
  String get pleaseSelectDeclarationIntent;

  /// No description provided for @confirmTenantReimburseApprovalTitle.
  ///
  /// In sr, this message translates to:
  /// **'Odobrenje prebijanja'**
  String get confirmTenantReimburseApprovalTitle;

  /// No description provided for @confirmTenantReimburseApprovalMsg.
  ///
  /// In sr, this message translates to:
  /// **'Potvrđujete li da stanar može prebiti ovaj investicioni trošak od {amount} sa plaćanjem kirije?'**
  String confirmTenantReimburseApprovalMsg(String amount);

  /// No description provided for @confirmTenantSelfApprovalTitle.
  ///
  /// In sr, this message translates to:
  /// **'Potvrda ličnog troška stanara'**
  String get confirmTenantSelfApprovalTitle;

  /// No description provided for @confirmTenantSelfApprovalMsg.
  ///
  /// In sr, this message translates to:
  /// **'Potvrđujete li da je stanar platio trošak upotrebe od {amount} i da se zahtev zatvori kao plaćen bez refundacije?'**
  String confirmTenantSelfApprovalMsg(String amount);

  /// No description provided for @confirmLandlordSelfApprovalTitle.
  ///
  /// In sr, this message translates to:
  /// **'Potvrda troška vlasnika'**
  String get confirmLandlordSelfApprovalTitle;

  /// No description provided for @confirmLandlordSelfApprovalMsg.
  ///
  /// In sr, this message translates to:
  /// **'Potvrđujete li da je vlasnik pokrio investicioni trošak od {amount} i da se zahtev zatvori kao plaćen?'**
  String confirmLandlordSelfApprovalMsg(String amount);

  /// No description provided for @confirmLandlordTenantDueApprovalTitle.
  ///
  /// In sr, this message translates to:
  /// **'Odobrenje duga'**
  String get confirmLandlordTenantDueApprovalTitle;

  /// No description provided for @confirmLandlordTenantDueApprovalMsg.
  ///
  /// In sr, this message translates to:
  /// **'Potvrđujete li da je ovaj trošak od {amount} nastao vašim korišćenjem i da ćete ga platiti stanodavcu?'**
  String confirmLandlordTenantDueApprovalMsg(String amount);

  /// No description provided for @acceptDebtBtn.
  ///
  /// In sr, this message translates to:
  /// **'Prihvati dug'**
  String get acceptDebtBtn;

  /// No description provided for @approveOffsetBtn.
  ///
  /// In sr, this message translates to:
  /// **'Odobri prebijanje'**
  String get approveOffsetBtn;

  /// No description provided for @acceptDebtNote.
  ///
  /// In sr, this message translates to:
  /// **'Kada prihvatite, ovaj iznos će biti dodat vašim dugovanjima u planu plaćanja.'**
  String get acceptDebtNote;

  /// No description provided for @approveOffsetNote.
  ///
  /// In sr, this message translates to:
  /// **'Kada odobrite, iznos se dodaje potraživanjima stanara za prebijanje sa predstojećim zakupom.'**
  String get approveOffsetNote;

  /// No description provided for @declaredIntentLabel.
  ///
  /// In sr, this message translates to:
  /// **'Predlog obračuna: {intent}'**
  String declaredIntentLabel(String intent);

  /// No description provided for @maintenanceSettlementsHeader.
  ///
  /// In sr, this message translates to:
  /// **'Obračun održavanja i kvarova'**
  String get maintenanceSettlementsHeader;

  /// No description provided for @maintenanceSettlementsSub.
  ///
  /// In sr, this message translates to:
  /// **'Odobreni troškovi održavanja koji se odbijaju ili dodaju na kiriju'**
  String get maintenanceSettlementsSub;

  /// No description provided for @deductFromRentBadge.
  ///
  /// In sr, this message translates to:
  /// **'Odbija se od kirije'**
  String get deductFromRentBadge;

  /// No description provided for @addToRentBadge.
  ///
  /// In sr, this message translates to:
  /// **'Dodaje se na kiriju'**
  String get addToRentBadge;

  /// No description provided for @markAsSettledBtn.
  ///
  /// In sr, this message translates to:
  /// **'Označi kao poravnato / plaćeno'**
  String get markAsSettledBtn;

  /// No description provided for @confirmSettlementTitle.
  ///
  /// In sr, this message translates to:
  /// **'Zatvori obračun'**
  String get confirmSettlementTitle;

  /// No description provided for @confirmSettlementMsg.
  ///
  /// In sr, this message translates to:
  /// **'Da li potvrđujete da je trošak održavanja od {amount} poravnat/plaćen i da treba zatvoriti stavku?'**
  String confirmSettlementMsg(String amount);

  /// No description provided for @settlementRecordedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Obračun održavanja je uspešno zatvoren.'**
  String get settlementRecordedSuccess;

  /// No description provided for @goToMaintenanceRequest.
  ///
  /// In sr, this message translates to:
  /// **'Otvori zahtev'**
  String get goToMaintenanceRequest;

  /// No description provided for @maintenanceSettlementActivityMsg.
  ///
  /// In sr, this message translates to:
  /// **'💰 Trošak održavanja ({amount}) je označen kao poravnat/plaćen od strane {role}.'**
  String maintenanceSettlementActivityMsg(String amount, String role);

  /// No description provided for @settleExpenseTitle.
  ///
  /// In sr, this message translates to:
  /// **'Poravnanje troškova održavanja'**
  String get settleExpenseTitle;

  /// No description provided for @settleExpenseSub.
  ///
  /// In sr, this message translates to:
  /// **'Izaberite način plaćanja ili prebijanja'**
  String get settleExpenseSub;

  /// No description provided for @optionOffsetFromRent.
  ///
  /// In sr, this message translates to:
  /// **'Prebij sa dugom'**
  String get optionOffsetFromRent;

  /// No description provided for @optionOffsetFromRentDesc.
  ///
  /// In sr, this message translates to:
  /// **'Automatski umanji ovaj iznos sa predstojeće kirije, računa ili troškova održavanja u istoj valuti'**
  String get optionOffsetFromRentDesc;

  /// No description provided for @optionBankTransfer.
  ///
  /// In sr, this message translates to:
  /// **'Plati bankarskim transferom'**
  String get optionBankTransfer;

  /// No description provided for @optionBankTransferDesc.
  ///
  /// In sr, this message translates to:
  /// **'Priložite uplatnicu i pošaljite na potvrdu'**
  String get optionBankTransferDesc;

  /// No description provided for @optionCashPayment.
  ///
  /// In sr, this message translates to:
  /// **'Plati u gotovini'**
  String get optionCashPayment;

  /// No description provided for @optionCashPaymentDesc.
  ///
  /// In sr, this message translates to:
  /// **'Prijavite da je plaćeno u gotovini'**
  String get optionCashPaymentDesc;

  /// No description provided for @selectRentToOffset.
  ///
  /// In sr, this message translates to:
  /// **'Izaberite stavku za prebijanje'**
  String get selectRentToOffset;

  /// No description provided for @noEligiblePendingPayments.
  ///
  /// In sr, this message translates to:
  /// **'Nema odgovarajućih dugovanja kirije, računa ili održavanja za prebijanje ({currency}).'**
  String noEligiblePendingPayments(String currency);

  /// No description provided for @offsetAppliedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Iznos od {amount} je uspešno prebijen sa stavke {paymentTitle}.'**
  String offsetAppliedSuccess(String amount, String paymentTitle);

  /// No description provided for @confirmReceiptBtn.
  ///
  /// In sr, this message translates to:
  /// **'Primio sam uplatu / Potvrdi'**
  String get confirmReceiptBtn;

  /// No description provided for @waitingForRecipientApproval.
  ///
  /// In sr, this message translates to:
  /// **'Čeka se potvrda druge strane'**
  String get waitingForRecipientApproval;

  /// No description provided for @iPaidBtn.
  ///
  /// In sr, this message translates to:
  /// **'Platio sam / Priloži uplatnicu'**
  String get iPaidBtn;

  /// No description provided for @iPaidCashBtn.
  ///
  /// In sr, this message translates to:
  /// **'Plaćeno u gotovini'**
  String get iPaidCashBtn;

  /// No description provided for @maintenanceCashPaidActivityMsg.
  ///
  /// In sr, this message translates to:
  /// **'💵 {role} je prijavio plaćanje troška održavanja od {amount} u gotovini. Čeka se potvrda.'**
  String maintenanceCashPaidActivityMsg(String role, String amount);

  /// No description provided for @maintenanceBankPaidActivityMsg.
  ///
  /// In sr, this message translates to:
  /// **'📄 {role} je prijavio plaćanje troška održavanja od {amount} preko banke (Uplatnica priložena). Čeka se potvrda.'**
  String maintenanceBankPaidActivityMsg(String role, String amount);

  /// No description provided for @maintenanceOffsetActivityMsg.
  ///
  /// In sr, this message translates to:
  /// **'🏠 Trošak održavanja od {amount} je prebijen sa stavke {paymentTitle}.'**
  String maintenanceOffsetActivityMsg(String amount, String paymentTitle);

  /// No description provided for @agencyReferralBoundSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Agencijski referral je povezan: {agencyName}'**
  String agencyReferralBoundSuccess(String agencyName);

  /// No description provided for @invalidAgencyReferralCode.
  ///
  /// In sr, this message translates to:
  /// **'Nevažeći ili nepronađeni agencijski referral kod.'**
  String get invalidAgencyReferralCode;

  /// No description provided for @occupancyRate.
  ///
  /// In sr, this message translates to:
  /// **'Popunjenost'**
  String get occupancyRate;

  /// No description provided for @allPropertiesUpToDate.
  ///
  /// In sr, this message translates to:
  /// **'Sve nekretnine i uplate su ažurne. Nema odobrenja na čekanju.'**
  String get allPropertiesUpToDate;

  /// No description provided for @overduePaymentsAlert.
  ///
  /// In sr, this message translates to:
  /// **'Ima {count} zakasnelih uplata. Proverite listu nekretnina za detalje.'**
  String overduePaymentsAlert(int count);

  /// No description provided for @filterAll.
  ///
  /// In sr, this message translates to:
  /// **'Sve'**
  String get filterAll;

  /// No description provided for @filterRented.
  ///
  /// In sr, this message translates to:
  /// **'Izdato'**
  String get filterRented;

  /// No description provided for @filterVacant.
  ///
  /// In sr, this message translates to:
  /// **'Slobodno'**
  String get filterVacant;

  /// No description provided for @noPropertiesForFilter.
  ///
  /// In sr, this message translates to:
  /// **'Nema nekretnina za ovaj filter.'**
  String get noPropertiesForFilter;

  /// No description provided for @attentionTag.
  ///
  /// In sr, this message translates to:
  /// **'PAŽNJA'**
  String get attentionTag;

  /// No description provided for @reviewAction.
  ///
  /// In sr, this message translates to:
  /// **'Pregledaj'**
  String get reviewAction;

  /// No description provided for @detailsAction.
  ///
  /// In sr, this message translates to:
  /// **'Detalji'**
  String get detailsAction;

  /// No description provided for @noActiveContractTapToInvite.
  ///
  /// In sr, this message translates to:
  /// **'Nema aktivnog ugovora. Dodirnite da pozovete stanara.'**
  String get noActiveContractTapToInvite;

  /// No description provided for @activeTenantsCount.
  ///
  /// In sr, this message translates to:
  /// **'Aktivni stanari'**
  String get activeTenantsCount;

  /// No description provided for @totalPropertiesCount.
  ///
  /// In sr, this message translates to:
  /// **'Ukupno nekretnina'**
  String get totalPropertiesCount;

  /// No description provided for @collectedRentSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Naplaćena kirija'**
  String get collectedRentSubtitle;

  /// No description provided for @awaitingApprovalSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Odobrenje uplatnice'**
  String get awaitingApprovalSubtitle;

  /// No description provided for @overduePaymentsSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Zakasnelo'**
  String get overduePaymentsSubtitle;

  /// No description provided for @vacantUnitsSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Dostupno za izdavanje'**
  String get vacantUnitsSubtitle;

  /// No description provided for @portfolioRateSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Stopa portfolija'**
  String get portfolioRateSubtitle;

  /// No description provided for @rentedStatusTag.
  ///
  /// In sr, this message translates to:
  /// **'Izdato'**
  String get rentedStatusTag;

  /// No description provided for @invitedStatusTag.
  ///
  /// In sr, this message translates to:
  /// **'Poziv na čekanju'**
  String get invitedStatusTag;

  /// No description provided for @settlementCredit.
  ///
  /// In sr, this message translates to:
  /// **'Prebijanje potraživanja'**
  String get settlementCredit;

  /// No description provided for @noDebtLabel.
  ///
  /// In sr, this message translates to:
  /// **'Nema duga'**
  String get noDebtLabel;

  /// No description provided for @daysLeftBadge.
  ///
  /// In sr, this message translates to:
  /// **'Još {count} dana'**
  String daysLeftBadge(int count);

  /// No description provided for @dueTodayBadge.
  ///
  /// In sr, this message translates to:
  /// **'Danas ističe'**
  String get dueTodayBadge;

  /// No description provided for @overdueBadge.
  ///
  /// In sr, this message translates to:
  /// **'U zakašnjenju'**
  String get overdueBadge;

  /// No description provided for @allTenantPaymentsUpToDate.
  ///
  /// In sr, this message translates to:
  /// **'Sve vaše uplate su ažurne. Sledeća kirija dospeva {date}.'**
  String allTenantPaymentsUpToDate(String date);

  /// No description provided for @tenantAwaitingReceiptApprovalMsg.
  ///
  /// In sr, this message translates to:
  /// **'Uplatnica je priložena za {count} uplata, čeka se odobrenje.'**
  String tenantAwaitingReceiptApprovalMsg(int count);

  /// No description provided for @tenantOutstandingDebtMsg.
  ///
  /// In sr, this message translates to:
  /// **'Imate {count} neizmirenih obaveza.'**
  String tenantOutstandingDebtMsg(int count);

  /// No description provided for @quickActionFinance.
  ///
  /// In sr, this message translates to:
  /// **'Kirija i računi'**
  String get quickActionFinance;

  /// No description provided for @quickActionMaintenance.
  ///
  /// In sr, this message translates to:
  /// **'Održavanje'**
  String get quickActionMaintenance;

  /// No description provided for @quickActionContract.
  ///
  /// In sr, this message translates to:
  /// **'Ugovor'**
  String get quickActionContract;

  /// No description provided for @quickActionHistory.
  ///
  /// In sr, this message translates to:
  /// **'Istorija plaćanja'**
  String get quickActionHistory;

  /// No description provided for @monthlyBaseRent.
  ///
  /// In sr, this message translates to:
  /// **'Mesečna kirija'**
  String get monthlyBaseRent;

  /// No description provided for @payNowAction.
  ///
  /// In sr, this message translates to:
  /// **'Plati odmah'**
  String get payNowAction;

  /// No description provided for @depositSecuredLabel.
  ///
  /// In sr, this message translates to:
  /// **'Obezbeđen depozit'**
  String get depositSecuredLabel;

  /// No description provided for @maintenanceTitle.
  ///
  /// In sr, this message translates to:
  /// **'Zahtevi za održavanje i popravke'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Pratite prijavljene kvarove, dolaske majstora i troškove.'**
  String get maintenanceSubtitle;

  /// No description provided for @filterActive.
  ///
  /// In sr, this message translates to:
  /// **'Aktivni i u toku'**
  String get filterActive;

  /// No description provided for @filterInvestigating.
  ///
  /// In sr, this message translates to:
  /// **'Na proveri'**
  String get filterInvestigating;

  /// No description provided for @filterUrgent.
  ///
  /// In sr, this message translates to:
  /// **'Hitno'**
  String get filterUrgent;

  /// No description provided for @filterCompleted.
  ///
  /// In sr, this message translates to:
  /// **'Rešeno'**
  String get filterCompleted;

  /// No description provided for @filterCost.
  ///
  /// In sr, this message translates to:
  /// **'Sa troškom / Refundacija'**
  String get filterCost;

  /// No description provided for @searchMaintenancePlaceholder.
  ///
  /// In sr, this message translates to:
  /// **'Pretraži zahteve...'**
  String get searchMaintenancePlaceholder;

  /// No description provided for @statActiveIssues.
  ///
  /// In sr, this message translates to:
  /// **'Aktivni / U toku'**
  String get statActiveIssues;

  /// No description provided for @statUrgentIssues.
  ///
  /// In sr, this message translates to:
  /// **'Hitni zahtevi'**
  String get statUrgentIssues;

  /// No description provided for @statResolvedIssues.
  ///
  /// In sr, this message translates to:
  /// **'Rešeni'**
  String get statResolvedIssues;

  /// No description provided for @statPendingSettlement.
  ///
  /// In sr, this message translates to:
  /// **'Trošak / Refundacija'**
  String get statPendingSettlement;

  /// No description provided for @progressReported.
  ///
  /// In sr, this message translates to:
  /// **'Prijavljeno'**
  String get progressReported;

  /// No description provided for @progressInvestigating.
  ///
  /// In sr, this message translates to:
  /// **'Provera'**
  String get progressInvestigating;

  /// No description provided for @progressInProgress.
  ///
  /// In sr, this message translates to:
  /// **'Majstor'**
  String get progressInProgress;

  /// No description provided for @progressResolved.
  ///
  /// In sr, this message translates to:
  /// **'Rešeno'**
  String get progressResolved;

  /// No description provided for @statusInProgressTechnician.
  ///
  /// In sr, this message translates to:
  /// **'Poslat majstor'**
  String get statusInProgressTechnician;

  /// No description provided for @costDeductFromRent.
  ///
  /// In sr, this message translates to:
  /// **'Odbija se od kirije'**
  String get costDeductFromRent;

  /// No description provided for @costAddToRent.
  ///
  /// In sr, this message translates to:
  /// **'Dodaje se na kiriju'**
  String get costAddToRent;

  /// No description provided for @costPaidByTenant.
  ///
  /// In sr, this message translates to:
  /// **'Platio stanar'**
  String get costPaidByTenant;

  /// No description provided for @costPaidByLandlord.
  ///
  /// In sr, this message translates to:
  /// **'Platio vlasnik'**
  String get costPaidByLandlord;

  /// No description provided for @costPendingReview.
  ///
  /// In sr, this message translates to:
  /// **'Čeka proveru troška'**
  String get costPendingReview;

  /// No description provided for @costRejected.
  ///
  /// In sr, this message translates to:
  /// **'Trošak odbijen'**
  String get costRejected;

  /// No description provided for @viewInvoiceAction.
  ///
  /// In sr, this message translates to:
  /// **'Pogledaj račun'**
  String get viewInvoiceAction;

  /// No description provided for @noMatchingIssues.
  ///
  /// In sr, this message translates to:
  /// **'Nema zahteva za održavanje koji odgovaraju pretrazi'**
  String get noMatchingIssues;

  /// No description provided for @clearFilters.
  ///
  /// In sr, this message translates to:
  /// **'Očisti filtere'**
  String get clearFilters;

  /// No description provided for @photosCount.
  ///
  /// In sr, this message translates to:
  /// **'{count, plural, one{{count} fotografija} few{{count} fotografije} other{{count} fotografija}}'**
  String photosCount(int count);

  /// No description provided for @viewDetailsAction.
  ///
  /// In sr, this message translates to:
  /// **'Pogledaj detalje'**
  String get viewDetailsAction;

  /// No description provided for @reportIssueSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Prijavite kvar ili potrebu za održavanjem uz fotografije za brže rešavanje.'**
  String get reportIssueSubtitle;

  /// No description provided for @issueTitleHint.
  ///
  /// In sr, this message translates to:
  /// **'Npr: Curenje vode ispod sudopere u kuhinji'**
  String get issueTitleHint;

  /// No description provided for @issueDescriptionHint.
  ///
  /// In sr, this message translates to:
  /// **'Opišite tačnu lokaciju kvara, kada je počeo i detalje...'**
  String get issueDescriptionHint;

  /// No description provided for @priorityNormalDesc.
  ///
  /// In sr, this message translates to:
  /// **'Standardan postupak popravke i održavanja'**
  String get priorityNormalDesc;

  /// No description provided for @priorityUrgentDesc.
  ///
  /// In sr, this message translates to:
  /// **'Poplava, opasnost od struje ili hitna intervencija'**
  String get priorityUrgentDesc;

  /// No description provided for @photosSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Dodajte jasne fotografije kvara (Maks. 5)'**
  String get photosSubtitle;

  /// No description provided for @addPhotoFromGallery.
  ///
  /// In sr, this message translates to:
  /// **'Otpremi fotografije'**
  String get addPhotoFromGallery;

  /// No description provided for @sendRequestBtn.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji prijavu kvara'**
  String get sendRequestBtn;

  /// No description provided for @categorySelectorTitle.
  ///
  /// In sr, this message translates to:
  /// **'Kategorija kvara'**
  String get categorySelectorTitle;

  /// No description provided for @prioritySelectorTitle.
  ///
  /// In sr, this message translates to:
  /// **'Nivo prioriteta'**
  String get prioritySelectorTitle;

  /// No description provided for @financialSectionTitle.
  ///
  /// In sr, this message translates to:
  /// **'FINANSIJSKI PODACI & FAKTURA'**
  String get financialSectionTitle;

  /// No description provided for @financialSectionSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Dodajte trošak popravke i fakturu ako postoji (Opciono).'**
  String get financialSectionSubtitle;

  /// No description provided for @costAmountLabel.
  ///
  /// In sr, this message translates to:
  /// **'Iznos troška'**
  String get costAmountLabel;

  /// No description provided for @paidByLabel.
  ///
  /// In sr, this message translates to:
  /// **'Odgovoran za trošak'**
  String get paidByLabel;

  /// No description provided for @unassignedLabel.
  ///
  /// In sr, this message translates to:
  /// **'Nije navedeno'**
  String get unassignedLabel;

  /// No description provided for @paymentStatusLabel.
  ///
  /// In sr, this message translates to:
  /// **'Status fakture i plaćanja'**
  String get paymentStatusLabel;

  /// No description provided for @pendingReviewHint.
  ///
  /// In sr, this message translates to:
  /// **'Račun se proverava (Ne utiče na bilans)'**
  String get pendingReviewHint;

  /// No description provided for @pendingPaymentHint.
  ///
  /// In sr, this message translates to:
  /// **'Odobreno • Evidentira se zaduženje'**
  String get pendingPaymentHint;

  /// No description provided for @paymentCompletedSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Plaćanje završeno'**
  String get paymentCompletedSubtitle;

  /// No description provided for @paymentRejectedSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Nevažeće / Odbijeno'**
  String get paymentRejectedSubtitle;

  /// No description provided for @invoicePdfLabel.
  ///
  /// In sr, this message translates to:
  /// **'Faktura / Račun'**
  String get invoicePdfLabel;

  /// No description provided for @uploadPdfTitle.
  ///
  /// In sr, this message translates to:
  /// **'Otpremi PDF račun'**
  String get uploadPdfTitle;

  /// No description provided for @uploadPdfSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Dodirnite za izbor PDF-a (Maks. 10MB)'**
  String get uploadPdfSubtitle;

  /// No description provided for @tenantLockedStatusNotice.
  ///
  /// In sr, this message translates to:
  /// **'Stanar ne može menjati status plaćanja ukoliko sam ne plaća trošak (biće sačuvano kao Čeka proveru).'**
  String get tenantLockedStatusNotice;

  /// No description provided for @payerRequiredError.
  ///
  /// In sr, this message translates to:
  /// **'Molimo izaberite ko plaća trošak pre postavljanja statusa plaćanja.'**
  String get payerRequiredError;

  /// No description provided for @tabRentAndFinance.
  ///
  /// In sr, this message translates to:
  /// **'Kirija i Finansije'**
  String get tabRentAndFinance;

  /// No description provided for @tabLeaseAndTenant.
  ///
  /// In sr, this message translates to:
  /// **'Ugovor i Zakupac'**
  String get tabLeaseAndTenant;

  /// No description provided for @tabMaintenance.
  ///
  /// In sr, this message translates to:
  /// **'Održavanje'**
  String get tabMaintenance;

  /// No description provided for @tabAuditLog.
  ///
  /// In sr, this message translates to:
  /// **'Istorija'**
  String get tabAuditLog;

  /// No description provided for @paymentMethodBank.
  ///
  /// In sr, this message translates to:
  /// **'Banka'**
  String get paymentMethodBank;

  /// No description provided for @paymentMethodCash.
  ///
  /// In sr, this message translates to:
  /// **'Gotovina'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In sr, this message translates to:
  /// **'Način plaćanja:'**
  String get paymentMethodLabel;

  /// No description provided for @managedByAgencyTitle.
  ///
  /// In sr, this message translates to:
  /// **'Upravlja agencija'**
  String get managedByAgencyTitle;

  /// No description provided for @managedByAgencyDesc.
  ///
  /// In sr, this message translates to:
  /// **'Vašim nekretninama upravlja agencija. Dodavanje novih nekretnina može izvršiti samo vaša agencija.'**
  String get managedByAgencyDesc;

  /// No description provided for @structuralAndFinancialMetricsSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Tip nekretnine, broj stana, broj soba i spratnost'**
  String get structuralAndFinancialMetricsSubtitle;

  /// No description provided for @equipmentAndHeatingStandardsSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Status opremljenosti i infrastruktura grejanja'**
  String get equipmentAndHeatingStandardsSubtitle;

  /// No description provided for @featuredAmenitiesSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Istaknute pogodnosti i detaljan opis'**
  String get featuredAmenitiesSubtitle;

  /// No description provided for @roomTypeStudio.
  ///
  /// In sr, this message translates to:
  /// **'Garsonjera'**
  String get roomTypeStudio;

  /// No description provided for @secondaryContacts.
  ///
  /// In sr, this message translates to:
  /// **'Dodatne kontakt osobe'**
  String get secondaryContacts;

  /// No description provided for @addSecondaryContact.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj kontakt'**
  String get addSecondaryContact;

  /// No description provided for @secondaryContactsOptionalDesc.
  ///
  /// In sr, this message translates to:
  /// **'Opciono: Možete dodati pomoćne kontakte poput asistenta, zastupnika ili člana porodice.'**
  String get secondaryContactsOptionalDesc;

  /// No description provided for @roleOrRelation.
  ///
  /// In sr, this message translates to:
  /// **'Uloga / Odnos'**
  String get roleOrRelation;

  /// No description provided for @tenantFullName.
  ///
  /// In sr, this message translates to:
  /// **'Ime i prezime zakupca'**
  String get tenantFullName;

  /// No description provided for @tenantIdOrPassport.
  ///
  /// In sr, this message translates to:
  /// **'Br. l.k. / Pasoša / JMBG'**
  String get tenantIdOrPassport;

  /// No description provided for @tenantNotes.
  ///
  /// In sr, this message translates to:
  /// **'Napomene o zakupcu'**
  String get tenantNotes;

  /// No description provided for @tenantIdDocument.
  ///
  /// In sr, this message translates to:
  /// **'Lični dokument / Pasoš zakupca'**
  String get tenantIdDocument;

  /// No description provided for @uploadPdfOrPhoto.
  ///
  /// In sr, this message translates to:
  /// **'Otpremite u PDF ili formatu slike'**
  String get uploadPdfOrPhoto;

  /// No description provided for @uploadAction.
  ///
  /// In sr, this message translates to:
  /// **'Otpremi'**
  String get uploadAction;

  /// No description provided for @idDocumentUploaded.
  ///
  /// In sr, this message translates to:
  /// **'Lični dokument je otpremljen'**
  String get idDocumentUploaded;

  /// No description provided for @copiedId.
  ///
  /// In sr, this message translates to:
  /// **'ID je kopiran: {id}'**
  String copiedId(String id);

  /// No description provided for @rolePersonalAssistant.
  ///
  /// In sr, this message translates to:
  /// **'Lični asistent'**
  String get rolePersonalAssistant;

  /// No description provided for @rolePrRep.
  ///
  /// In sr, this message translates to:
  /// **'PR / Zastupnik'**
  String get rolePrRep;

  /// No description provided for @roleFamilyMember.
  ///
  /// In sr, this message translates to:
  /// **'Član porodice'**
  String get roleFamilyMember;

  /// No description provided for @roleAuthorizedContact.
  ///
  /// In sr, this message translates to:
  /// **'Ovlašćeni kontakt'**
  String get roleAuthorizedContact;

  /// No description provided for @clearAllAction.
  ///
  /// In sr, this message translates to:
  /// **'Poništi sve'**
  String get clearAllAction;

  /// No description provided for @selectAllAction.
  ///
  /// In sr, this message translates to:
  /// **'Izaberi sve'**
  String get selectAllAction;

  /// No description provided for @applyAction.
  ///
  /// In sr, this message translates to:
  /// **'Primeni'**
  String get applyAction;

  /// Localization for selectedCount
  ///
  /// In sr, this message translates to:
  /// **'{count} izabrano'**
  String selectedCount(int count);

  /// Localization for selectedItemsCount
  ///
  /// In sr, this message translates to:
  /// **'{count} Izabrano'**
  String selectedItemsCount(int count);

  /// No description provided for @propertyOwnerInfoTitle.
  ///
  /// In sr, this message translates to:
  /// **'Podaci o vlasnicima nekretnine'**
  String get propertyOwnerInfoTitle;

  /// No description provided for @propertyOwnerInfoSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Možete dodati više suvlasnika, pravna ili fizička lica, kao i priložiti dokumenta o vlasništvu i ovlašćenja.'**
  String get propertyOwnerInfoSubtitle;

  /// No description provided for @addCoOwner.
  ///
  /// In sr, this message translates to:
  /// **'+ Dodaj suvlasnika'**
  String get addCoOwner;

  /// No description provided for @primaryOwnerLabel.
  ///
  /// In sr, this message translates to:
  /// **'1. Vlasnik (Glavni)'**
  String get primaryOwnerLabel;

  /// Localization for coOwnerIndexedLabel
  ///
  /// In sr, this message translates to:
  /// **'{index}. Suvlasnik'**
  String coOwnerIndexedLabel(int index);

  /// No description provided for @sharePercentage.
  ///
  /// In sr, this message translates to:
  /// **'Udeo %'**
  String get sharePercentage;

  /// No description provided for @removeOwner.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni vlasnika'**
  String get removeOwner;

  /// No description provided for @ownerType.
  ///
  /// In sr, this message translates to:
  /// **'Vrsta vlasnika'**
  String get ownerType;

  /// No description provided for @ownerIndividual.
  ///
  /// In sr, this message translates to:
  /// **'Fizičko lice'**
  String get ownerIndividual;

  /// No description provided for @ownerCompany.
  ///
  /// In sr, this message translates to:
  /// **'Pravno lice / Kompanija'**
  String get ownerCompany;

  /// No description provided for @firstNameRequired.
  ///
  /// In sr, this message translates to:
  /// **'Ime *'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In sr, this message translates to:
  /// **'Prezime *'**
  String get lastNameRequired;

  /// No description provided for @idOrPassportOrJmbg.
  ///
  /// In sr, this message translates to:
  /// **'Broj l.k. / Pasoša / JMBG'**
  String get idOrPassportOrJmbg;

  /// No description provided for @idIssuingAuthority.
  ///
  /// In sr, this message translates to:
  /// **'Organ izdavanja'**
  String get idIssuingAuthority;

  /// No description provided for @companyLegalNameRequired.
  ///
  /// In sr, this message translates to:
  /// **'Puni naziv pravnog lica *'**
  String get companyLegalNameRequired;

  /// No description provided for @registeredOfficeAddress.
  ///
  /// In sr, this message translates to:
  /// **'Sedište / Adresa registracije'**
  String get registeredOfficeAddress;

  /// No description provided for @taxIdPibRequired.
  ///
  /// In sr, this message translates to:
  /// **'PIB *'**
  String get taxIdPibRequired;

  /// No description provided for @companyRegNo.
  ///
  /// In sr, this message translates to:
  /// **'Matični broj'**
  String get companyRegNo;

  /// No description provided for @legalRepFullNameRequired.
  ///
  /// In sr, this message translates to:
  /// **'Ime i prezime zastupnika *'**
  String get legalRepFullNameRequired;

  /// No description provided for @repIdJmbg.
  ///
  /// In sr, this message translates to:
  /// **'Broj l.k./JMBG zastupnika'**
  String get repIdJmbg;

  /// No description provided for @repAuthorityDetails.
  ///
  /// In sr, this message translates to:
  /// **'Detalji ovlašćenja zastupnika'**
  String get repAuthorityDetails;

  /// No description provided for @contactPhoneRequired.
  ///
  /// In sr, this message translates to:
  /// **'Kontakt telefon *'**
  String get contactPhoneRequired;

  /// No description provided for @secondaryContactOptional.
  ///
  /// In sr, this message translates to:
  /// **'Drugi kontakt (Opciono)'**
  String get secondaryContactOptional;

  /// No description provided for @altPhoneOrNote.
  ///
  /// In sr, this message translates to:
  /// **'Alternativni tel.'**
  String get altPhoneOrNote;

  /// No description provided for @emailAddressRequiredForPrimary.
  ///
  /// In sr, this message translates to:
  /// **'Email adresa (Obavezno za glavnog) *'**
  String get emailAddressRequiredForPrimary;

  /// No description provided for @emailAddressOptional.
  ///
  /// In sr, this message translates to:
  /// **'Email adresa (Opciono)'**
  String get emailAddressOptional;

  /// No description provided for @selectExistingAgencyContact.
  ///
  /// In sr, this message translates to:
  /// **'Ili izaberite iz postojećih kontakata agencije...'**
  String get selectExistingAgencyContact;

  /// No description provided for @clearSelectionTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Poništi izbor'**
  String get clearSelectionTooltip;

  /// No description provided for @supportingPdfDocuments.
  ///
  /// In sr, this message translates to:
  /// **'Prateća PDF dokumenta'**
  String get supportingPdfDocuments;

  /// No description provided for @uploadDocumentTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Priloži dokument'**
  String get uploadDocumentTooltip;

  /// No description provided for @docTypePassportCopy.
  ///
  /// In sr, this message translates to:
  /// **'Kopija l.k. / Pasoša (PDF)'**
  String get docTypePassportCopy;

  /// No description provided for @docTypeProofOfOwnership.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnički list / Dokaz (PDF)'**
  String get docTypeProofOfOwnership;

  /// No description provided for @docTypePowerOfAttorney.
  ///
  /// In sr, this message translates to:
  /// **'Ovlašćenje / Punomoćje (PDF)'**
  String get docTypePowerOfAttorney;

  /// No description provided for @docTypeOtherDocument.
  ///
  /// In sr, this message translates to:
  /// **'Ostala dokumentacija (PDF)'**
  String get docTypeOtherDocument;

  /// No description provided for @addPdfDocument.
  ///
  /// In sr, this message translates to:
  /// **'+ Priloži PDF'**
  String get addPdfDocument;

  /// No description provided for @docTypeLabelId.
  ///
  /// In sr, this message translates to:
  /// **'L.K.'**
  String get docTypeLabelId;

  /// No description provided for @docTypeLabelTitleDeed.
  ///
  /// In sr, this message translates to:
  /// **'List nepokretnosti'**
  String get docTypeLabelTitleDeed;

  /// No description provided for @docTypeLabelPoa.
  ///
  /// In sr, this message translates to:
  /// **'Ovlašćenje'**
  String get docTypeLabelPoa;

  /// No description provided for @docTypeLabelOther.
  ///
  /// In sr, this message translates to:
  /// **'Dokument'**
  String get docTypeLabelOther;

  /// No description provided for @markAsPaid.
  ///
  /// In sr, this message translates to:
  /// **'Označi kao plaćeno'**
  String get markAsPaid;

  /// Localization for markAsPaidSubtitle
  ///
  /// In sr, this message translates to:
  /// **'Potvrda plaćanja za {title} ({month})'**
  String markAsPaidSubtitle(String title, String month);

  /// No description provided for @bankTransferOption.
  ///
  /// In sr, this message translates to:
  /// **'Preko banke'**
  String get bankTransferOption;

  /// No description provided for @receiptOrDocOptional.
  ///
  /// In sr, this message translates to:
  /// **'Uplatnica / Dokument (Opciono)'**
  String get receiptOrDocOptional;

  /// No description provided for @uploadReceiptOrImage.
  ///
  /// In sr, this message translates to:
  /// **'Priložite uplatnicu ili sliku'**
  String get uploadReceiptOrImage;

  /// No description provided for @uploadReceiptHint.
  ///
  /// In sr, this message translates to:
  /// **'PDF, PNG, JPG ili fotografija'**
  String get uploadReceiptHint;

  /// No description provided for @noteOptional.
  ///
  /// In sr, this message translates to:
  /// **'Napomena (Opciono)'**
  String get noteOptional;

  /// No description provided for @noteOptionalRentHint.
  ///
  /// In sr, this message translates to:
  /// **'Npr: Gotovinski plaćeno / Uplatnica priložena'**
  String get noteOptionalRentHint;

  /// No description provided for @paymentMarkedPaidSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Plaćanje je uspešno označeno kao plaćeno.'**
  String get paymentMarkedPaidSuccess;

  /// No description provided for @saveAsPaid.
  ///
  /// In sr, this message translates to:
  /// **'Sačuvaj kao plaćeno'**
  String get saveAsPaid;

  /// No description provided for @collectSettleExpenseTitle.
  ///
  /// In sr, this message translates to:
  /// **'Potvrda naplate i zatvaranje'**
  String get collectSettleExpenseTitle;

  /// Localization for collectSettleExpenseSubtitle
  ///
  /// In sr, this message translates to:
  /// **'Potvrdite naplatu {cost} i zatvorite trošak.'**
  String collectSettleExpenseSubtitle(String cost);

  /// No description provided for @collectionMethod.
  ///
  /// In sr, this message translates to:
  /// **'Način naplate'**
  String get collectionMethod;

  /// No description provided for @collectionMethodBank.
  ///
  /// In sr, this message translates to:
  /// **'Banka / Transfer'**
  String get collectionMethodBank;

  /// No description provided for @collectionMethodCash.
  ///
  /// In sr, this message translates to:
  /// **'Gotovina'**
  String get collectionMethodCash;

  /// No description provided for @collectionMethodPayoutDeduction.
  ///
  /// In sr, this message translates to:
  /// **'Odbijeno od isplate'**
  String get collectionMethodPayoutDeduction;

  /// No description provided for @attachReceiptOrVoucher.
  ///
  /// In sr, this message translates to:
  /// **'Priložite uplatnicu'**
  String get attachReceiptOrVoucher;

  /// No description provided for @noteOptionalAgencyHint.
  ///
  /// In sr, this message translates to:
  /// **'Npr: Vlasnik je uplatio na račun'**
  String get noteOptionalAgencyHint;

  /// No description provided for @payoutDeductionLabel.
  ///
  /// In sr, this message translates to:
  /// **'Odbijeno od isplate'**
  String get payoutDeductionLabel;

  /// No description provided for @collectionConfirmedAndSettled.
  ///
  /// In sr, this message translates to:
  /// **'Naplata je potvrđena i trošak je zatvoren.'**
  String get collectionConfirmedAndSettled;

  /// No description provided for @confirmAndSettle.
  ///
  /// In sr, this message translates to:
  /// **'Potvrdi i zatvori'**
  String get confirmAndSettle;

  /// Localization for propertyOwnersCountTitle
  ///
  /// In sr, this message translates to:
  /// **'Vlasnici nekretnine ({count})'**
  String propertyOwnersCountTitle(int count);

  /// No description provided for @editOwners.
  ///
  /// In sr, this message translates to:
  /// **'Uredi vlasnike'**
  String get editOwners;

  /// No description provided for @primaryOwnerBadge.
  ///
  /// In sr, this message translates to:
  /// **'Glavni vlasnik'**
  String get primaryOwnerBadge;

  /// No description provided for @authorizedRepresentative.
  ///
  /// In sr, this message translates to:
  /// **'Zastupnik'**
  String get authorizedRepresentative;

  /// No description provided for @registeredAddressLabel.
  ///
  /// In sr, this message translates to:
  /// **'Sedište'**
  String get registeredAddressLabel;

  /// No description provided for @idJmbgLabel.
  ///
  /// In sr, this message translates to:
  /// **'Broj l.k./JMBG'**
  String get idJmbgLabel;

  /// No description provided for @secondaryContactPrefix.
  ///
  /// In sr, this message translates to:
  /// **'Drugi kontakt: '**
  String get secondaryContactPrefix;

  /// No description provided for @supportingDocumentsColon.
  ///
  /// In sr, this message translates to:
  /// **'Priložena dokumenta:'**
  String get supportingDocumentsColon;

  /// No description provided for @auditPaymentCreatedRent.
  ///
  /// In sr, this message translates to:
  /// **'Sistem je automatski kreirao zaduženje'**
  String get auditPaymentCreatedRent;

  /// No description provided for @auditPaymentCreatedExpense.
  ///
  /// In sr, this message translates to:
  /// **'Sistem je automatski kreirao stavku troška'**
  String get auditPaymentCreatedExpense;

  /// Localization for auditRentDeclaredCash
  ///
  /// In sr, this message translates to:
  /// **'{actor} je prijavio uplatu (Gotovina){monthSuffix}'**
  String auditRentDeclaredCash(String actor, String monthSuffix);

  /// Localization for auditRentDeclaredReceipt
  ///
  /// In sr, this message translates to:
  /// **'{actor} je učitao uplatnicu i prijavio uplatu{monthSuffix}'**
  String auditRentDeclaredReceipt(String actor, String monthSuffix);

  /// Localization for auditRentApproved
  ///
  /// In sr, this message translates to:
  /// **'{actor} je odobrio plaćanje{monthSuffix}'**
  String auditRentApproved(String actor, String monthSuffix);

  /// Localization for auditRentRejected
  ///
  /// In sr, this message translates to:
  /// **'{actor} je odbio plaćanje{monthSuffix}'**
  String auditRentRejected(String actor, String monthSuffix);

  /// Localization for auditRentDisputed
  ///
  /// In sr, this message translates to:
  /// **'{actor} je osporio plaćanje{reasonSuffix}'**
  String auditRentDisputed(String actor, String reasonSuffix);

  /// Localization for auditInvoiceUploadedPending
  ///
  /// In sr, this message translates to:
  /// **'{actor} {monthPrefix}je učitao račun (Čeka odobrenje, {amount})'**
  String auditInvoiceUploadedPending(
    String actor,
    String monthPrefix,
    String amount,
  );

  /// Localization for auditInvoiceUploaded
  ///
  /// In sr, this message translates to:
  /// **'{actor} {monthPrefix}je učitao račun ({amount})'**
  String auditInvoiceUploaded(String actor, String monthPrefix, String amount);

  /// Localization for auditInvoiceEnteredPending
  ///
  /// In sr, this message translates to:
  /// **'{actor} {monthPrefix}je uneo iznos troška (Čeka odobrenje, {amount})'**
  String auditInvoiceEnteredPending(
    String actor,
    String monthPrefix,
    String amount,
  );

  /// Localization for auditInvoiceEntered
  ///
  /// In sr, this message translates to:
  /// **'{actor} {monthPrefix}je uneo detalje troška ({amount})'**
  String auditInvoiceEntered(String actor, String monthPrefix, String amount);

  /// Localization for auditInvoiceApproved
  ///
  /// In sr, this message translates to:
  /// **'{actor} {monthPrefix}je odobrio račun ({amount})'**
  String auditInvoiceApproved(String actor, String monthPrefix, String amount);

  /// Localization for auditInvoiceRejected
  ///
  /// In sr, this message translates to:
  /// **'{actor} {monthPrefix}je odbio račun{reasonSuffix}'**
  String auditInvoiceRejected(
    String actor,
    String monthPrefix,
    String reasonSuffix,
  );

  /// Localization for auditPaymentToggle
  ///
  /// In sr, this message translates to:
  /// **'{actor} je označio plaćanje kao {status}'**
  String auditPaymentToggle(String actor, String status);

  /// No description provided for @auditRentAutoApproved.
  ///
  /// In sr, this message translates to:
  /// **'Plaćanje je automatski odobreno od strane sistema'**
  String get auditRentAutoApproved;

  /// Localization for auditMaintenanceCreated
  ///
  /// In sr, this message translates to:
  /// **'{actor} je kreirao zahtev za održavanje{titleSuffix}'**
  String auditMaintenanceCreated(String actor, String titleSuffix);

  /// Localization for auditMaintenanceStatusUpdated
  ///
  /// In sr, this message translates to:
  /// **'{actor} je ažurirao status zahteva za održavanje ({status})'**
  String auditMaintenanceStatusUpdated(String actor, String status);

  /// Localization for auditMaintenanceMessageAdded
  ///
  /// In sr, this message translates to:
  /// **'{actor} je dodao poruku na zahtev za održavanje'**
  String auditMaintenanceMessageAdded(String actor);

  /// Localization for auditMaintenanceReopened
  ///
  /// In sr, this message translates to:
  /// **'{actor} je ponovo otvorio zahtev za održavanje'**
  String auditMaintenanceReopened(String actor);

  /// Localization for contactTenantAsLandlordInfo
  ///
  /// In sr, this message translates to:
  /// **'Ova osoba je registrovana kao stanar ({propertySummary}). Sada se dodaje kao vlasnik.'**
  String contactTenantAsLandlordInfo(String propertySummary);

  /// No description provided for @registeredLandlordDetailsAutofilled.
  ///
  /// In sr, this message translates to:
  /// **'Podaci registrovanog stanodavca su automatski popunjeni.'**
  String get registeredLandlordDetailsAutofilled;

  /// No description provided for @noDocumentsAttachedYet.
  ///
  /// In sr, this message translates to:
  /// **'Nema priloženih dokumenata (Možete dodati l.k., vlasnički list ili ovlašćenje).'**
  String get noDocumentsAttachedYet;

  /// No description provided for @coOwnerEmailHelper.
  ///
  /// In sr, this message translates to:
  /// **'Ukoliko unesete email, suvlasnik će videti nekretninu u svom nalogu.'**
  String get coOwnerEmailHelper;

  /// No description provided for @propertyOwnersUpdatedSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Podaci o vlasnicima su uspešno ažurirani.'**
  String get propertyOwnersUpdatedSuccess;

  /// No description provided for @systemActor.
  ///
  /// In sr, this message translates to:
  /// **'Sistem'**
  String get systemActor;

  /// No description provided for @agencyRole.
  ///
  /// In sr, this message translates to:
  /// **'Agencija'**
  String get agencyRole;

  /// No description provided for @editPropertyOwners.
  ///
  /// In sr, this message translates to:
  /// **'Uredi vlasnike nekretnine'**
  String get editPropertyOwners;

  /// No description provided for @auditInvitationAccepted.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je prihvatio/la poziv za nekretninu'**
  String auditInvitationAccepted(Object actor);

  /// No description provided for @auditContractAccepted.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je odobrio/la i potpisao/la ugovor o zakupu'**
  String auditContractAccepted(Object actor);

  /// No description provided for @auditContractTerminationRequested.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je zatražio/la prevremeni raskid ugovora'**
  String auditContractTerminationRequested(Object actor);

  /// No description provided for @auditContractChangesAccepted.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je prihvatio/la predložene izmene ugovora'**
  String auditContractChangesAccepted(Object actor);

  /// No description provided for @auditContractChangesDeclined.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je odbio/la ili povukao/la predložene izmene ugovora'**
  String auditContractChangesDeclined(Object actor);

  /// No description provided for @auditLandlordOwnershipClaimed.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je preuzeo/la vlasništvo i upravljanje nekretninom'**
  String auditLandlordOwnershipClaimed(Object actor);

  /// No description provided for @auditTenantRemoved.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je uklonio/la stanara sa nekretnine'**
  String auditTenantRemoved(Object actor);

  /// No description provided for @auditPropertyOwnersUpdated.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je ažurirao/la podatke o vlasnicima nekretnine'**
  String auditPropertyOwnersUpdated(Object actor);

  /// No description provided for @auditMaintenanceFinancialsUpdated.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je ažurirao/la troškove i finansijske detalje održavanja'**
  String auditMaintenanceFinancialsUpdated(Object actor);

  /// No description provided for @auditMaintenanceFinancialsDeleted.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je izbrisao/la troškove održavanja i poništio/la prebijanja'**
  String auditMaintenanceFinancialsDeleted(Object actor);

  /// No description provided for @auditMaintenanceChargeCreated.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je dodao/la novu stavku troška održavanja'**
  String auditMaintenanceChargeCreated(Object actor);

  /// No description provided for @auditMaintenanceChargeStatusUpdated.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je ažurirao/la status troška održavanja'**
  String auditMaintenanceChargeStatusUpdated(Object actor);

  /// No description provided for @auditMaintenanceChargeSettled.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je namirio/la trošak održavanja'**
  String auditMaintenanceChargeSettled(Object actor);

  /// No description provided for @auditMaintenanceDeleted.
  ///
  /// In sr, this message translates to:
  /// **'{actor} je izbrisao/la zahtev za održavanje'**
  String auditMaintenanceDeleted(Object actor);

  /// No description provided for @tenantInviteEmailTitle.
  ///
  /// In sr, this message translates to:
  /// **'Obaveštenje za zakupca (imejl)'**
  String get tenantInviteEmailTitle;

  /// No description provided for @landlordInviteEmailTitle.
  ///
  /// In sr, this message translates to:
  /// **'Obaveštenje za vlasnika (imejl)'**
  String get landlordInviteEmailTitle;

  /// No description provided for @statusNotSent.
  ///
  /// In sr, this message translates to:
  /// **'Nije poslato'**
  String get statusNotSent;

  /// No description provided for @statusNoEmail.
  ///
  /// In sr, this message translates to:
  /// **'Nema imejl'**
  String get statusNoEmail;

  /// No description provided for @lastSentAt.
  ///
  /// In sr, this message translates to:
  /// **'Poslednje slanje: {date}'**
  String lastSentAt(String date);

  /// No description provided for @noEmailSpecified.
  ///
  /// In sr, this message translates to:
  /// **'Imejl adresa nije navedena'**
  String get noEmailSpecified;

  /// No description provided for @ownersConfirmedRatio.
  ///
  /// In sr, this message translates to:
  /// **'{confirmed}/{total} Potvrđeno'**
  String ownersConfirmedRatio(String confirmed, String total);

  /// No description provided for @ownerConfirmedBanner.
  ///
  /// In sr, this message translates to:
  /// **'{name} je prihvatio/la pozivnicu i odobrio/la upravljanje nekretninom.'**
  String ownerConfirmedBanner(String name);

  /// No description provided for @emailPreviewTitle.
  ///
  /// In sr, this message translates to:
  /// **'Pregled imejla za slanje'**
  String get emailPreviewTitle;

  /// No description provided for @emailPreviewForOwner.
  ///
  /// In sr, this message translates to:
  /// **'Pregled imejla ({name})'**
  String emailPreviewForOwner(String name);

  /// No description provided for @tabVisual.
  ///
  /// In sr, this message translates to:
  /// **'Vizuelno'**
  String get tabVisual;

  /// No description provided for @tabPlainText.
  ///
  /// In sr, this message translates to:
  /// **'Običan tekst'**
  String get tabPlainText;

  /// No description provided for @emailCopiedToast.
  ///
  /// In sr, this message translates to:
  /// **'Tekst imejla je kopiran u privremenu memoriju.'**
  String get emailCopiedToast;

  /// No description provided for @languageLabel.
  ///
  /// In sr, this message translates to:
  /// **'Jezik:'**
  String get languageLabel;

  /// No description provided for @subjectHeader.
  ///
  /// In sr, this message translates to:
  /// **'PREDMET'**
  String get subjectHeader;

  /// No description provided for @contentHeader.
  ///
  /// In sr, this message translates to:
  /// **'SADRŽAJ'**
  String get contentHeader;

  /// No description provided for @recipientWillReceiveThisFormat.
  ///
  /// In sr, this message translates to:
  /// **'Primalac će dobiti u ovom formatu'**
  String get recipientWillReceiveThisFormat;

  /// No description provided for @sendTenantInviteEmailBtn.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji imejl zakupcu'**
  String get sendTenantInviteEmailBtn;

  /// No description provided for @resendInviteEmailBtn.
  ///
  /// In sr, this message translates to:
  /// **'Ponovo pošalji imejl'**
  String get resendInviteEmailBtn;

  /// No description provided for @sendLandlordInviteEmailBtn.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji imejl vlasniku'**
  String get sendLandlordInviteEmailBtn;

  /// No description provided for @sendInviteForOwnerBtn.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji imejl za {name}'**
  String sendInviteForOwnerBtn(String name);

  /// No description provided for @resendInviteForOwnerBtn.
  ///
  /// In sr, this message translates to:
  /// **'Ponovo pošalji za {name}'**
  String resendInviteForOwnerBtn(String name);

  /// No description provided for @sendToAllBtn.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji svima'**
  String get sendToAllBtn;

  /// No description provided for @sendToAllOwnersBtn.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji pojedinačno svim vlasnicima ({count})'**
  String sendToAllOwnersBtn(String count);

  /// No description provided for @resendToAllOwnersBtn.
  ///
  /// In sr, this message translates to:
  /// **'Ponovo pošalji svim vlasnicima ({count})'**
  String resendToAllOwnersBtn(String count);

  /// No description provided for @sendingState.
  ///
  /// In sr, this message translates to:
  /// **'Slanje u toku...'**
  String get sendingState;

  /// No description provided for @sendingAllState.
  ///
  /// In sr, this message translates to:
  /// **'Slanje svima u toku...'**
  String get sendingAllState;

  /// No description provided for @noEmailAddressDefined.
  ///
  /// In sr, this message translates to:
  /// **'Imejl adresa nije definisana'**
  String get noEmailAddressDefined;

  /// No description provided for @tenantInviteSentSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Pozivni imejl je uspešno poslat na {email}.'**
  String tenantInviteSentSuccess(String email);

  /// No description provided for @landlordInviteSentSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Pozivni imejl je uspešno poslat na {email}.'**
  String landlordInviteSentSuccess(String email);

  /// No description provided for @noEmailForUserError.
  ///
  /// In sr, this message translates to:
  /// **'Nema imejl adrese za {name}.'**
  String noEmailForUserError(String name);

  /// No description provided for @tenantNoEmailError.
  ///
  /// In sr, this message translates to:
  /// **'Imejl adresa zakupca nije definisana.'**
  String get tenantNoEmailError;

  /// No description provided for @emailSendFailedError.
  ///
  /// In sr, this message translates to:
  /// **'Slanje imejla nije uspelo. Proverite podešavanja Brevo API-ja.'**
  String get emailSendFailedError;

  /// No description provided for @emailSendGenericError.
  ///
  /// In sr, this message translates to:
  /// **'Došlo je do greške prilikom slanja imejla: {error}'**
  String emailSendGenericError(String error);

  /// No description provided for @tenantInviteEmailBtn.
  ///
  /// In sr, this message translates to:
  /// **'Imejl pozivnica za zakupca'**
  String get tenantInviteEmailBtn;

  /// No description provided for @allOwnersInviteSentSuccess.
  ///
  /// In sr, this message translates to:
  /// **'Imejlovi sa pozivom uspešno poslati za {successCount} / {totalCount} vlasnika.'**
  String allOwnersInviteSentSuccess(String successCount, String totalCount);

  /// No description provided for @landlordsListHeader.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnici nekretnine ({count})'**
  String landlordsListHeader(String count);
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
      <String>['en', 'ru', 'sr', 'tr'].contains(locale.languageCode);

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
    case 'ru':
      return AppLocalizationsRu();
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
