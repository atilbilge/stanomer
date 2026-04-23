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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Stanomer'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @landlord.
  ///
  /// In en, this message translates to:
  /// **'Landlord'**
  String get landlord;

  /// No description provided for @tenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// No description provided for @zzplConsent.
  ///
  /// In en, this message translates to:
  /// **'I agree to the processing of my data in accordance with the Law on Personal Data Protection (ZZPL) of Serbia.'**
  String get zzplConsent;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectRole;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @consentRequired.
  ///
  /// In en, this message translates to:
  /// **'You must accept the ZZPL consent to continue'**
  String get consentRequired;

  /// No description provided for @loginToAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get loginToAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get createAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @errorSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Please select your role'**
  String get errorSelectRole;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data will be deleted.'**
  String get deleteAccountWarning;

  /// No description provided for @confirmPasswordForDeletion.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password to confirm deletion'**
  String get confirmPasswordForDeletion;

  /// No description provided for @deleteButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete My Account'**
  String get deleteButtonLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid password'**
  String get invalidPassword;

  /// No description provided for @welcomeToStanomer.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Stanomer'**
  String get welcomeToStanomer;

  /// No description provided for @consentTextFullTitle.
  ///
  /// In en, this message translates to:
  /// **'Consent for Personal Data Processing (ZZPL)'**
  String get consentTextFullTitle;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @updateName.
  ///
  /// In en, this message translates to:
  /// **'Update Name'**
  String get updateName;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @roleLandlord.
  ///
  /// In en, this message translates to:
  /// **'Landlord'**
  String get roleLandlord;

  /// No description provided for @roleTenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get roleTenant;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logout;

  /// No description provided for @addProperty.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addProperty;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @monthlyRent.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent'**
  String get monthlyRent;

  /// No description provided for @depositAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposit Amount'**
  String get depositAmount;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @propertyName.
  ///
  /// In en, this message translates to:
  /// **'Property Name'**
  String get propertyName;

  /// No description provided for @propertyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Belgrad Apartment'**
  String get propertyNameHint;

  /// No description provided for @propertyAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Property added successfully'**
  String get propertyAddedSuccess;

  /// No description provided for @propertyUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Property updated successfully'**
  String get propertyUpdatedSuccess;

  /// No description provided for @noProperties.
  ///
  /// In en, this message translates to:
  /// **'No properties found'**
  String get noProperties;

  /// No description provided for @addYourFirstProperty.
  ///
  /// In en, this message translates to:
  /// **'Add your first property to start tracking!'**
  String get addYourFirstProperty;

  /// No description provided for @editProperty.
  ///
  /// In en, this message translates to:
  /// **'Edit Property'**
  String get editProperty;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Property'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this property? This action cannot be undone.'**
  String get confirmDeleteMessage;

  /// No description provided for @propertyDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Property deleted successfully'**
  String get propertyDeletedSuccess;

  /// No description provided for @inviteTenant.
  ///
  /// In en, this message translates to:
  /// **'Invite Tenant'**
  String get inviteTenant;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tenant\'s email address'**
  String get emailHint;

  /// No description provided for @inviteCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invite link created! You can now share it.'**
  String get inviteCreatedSuccess;

  /// No description provided for @shareInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Share Invite Link'**
  String get shareInviteLink;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @noInvitesYet.
  ///
  /// In en, this message translates to:
  /// **'No invitations sent yet'**
  String get noInvitesYet;

  /// No description provided for @cancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invitation'**
  String get cancelInvitation;

  /// No description provided for @invitationCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation cancelled successfully'**
  String get invitationCancelledSuccess;

  /// No description provided for @pendingInvite.
  ///
  /// In en, this message translates to:
  /// **'Pending Invite'**
  String get pendingInvite;

  /// No description provided for @contractSentToTenant.
  ///
  /// In en, this message translates to:
  /// **'Contract sent to tenant'**
  String get contractSentToTenant;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @financials.
  ///
  /// In en, this message translates to:
  /// **'Financials'**
  String get financials;

  /// No description provided for @propertySettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get propertySettings;

  /// No description provided for @invitationHistory.
  ///
  /// In en, this message translates to:
  /// **'Invite History'**
  String get invitationHistory;

  /// No description provided for @invitationDetails.
  ///
  /// In en, this message translates to:
  /// **'Invitation Details'**
  String get invitationDetails;

  /// No description provided for @acceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Yes, I rented this place'**
  String get acceptInvitation;

  /// No description provided for @declineInvitation.
  ///
  /// In en, this message translates to:
  /// **'Decline Invitation'**
  String get declineInvitation;

  /// No description provided for @inviteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Invitation not found or expired'**
  String get inviteNotFound;

  /// No description provided for @invitationAcceptedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome home! Invitation accepted.'**
  String get invitationAcceptedSuccess;

  /// No description provided for @pendingInvitationBanner.
  ///
  /// In en, this message translates to:
  /// **'You have a pending invitation for {property}'**
  String pendingInvitationBanner(String property);

  /// No description provided for @invitedBy.
  ///
  /// In en, this message translates to:
  /// **'Invited by {name}'**
  String invitedBy(String name);

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get yourNameHint;

  /// No description provided for @viewInvite.
  ///
  /// In en, this message translates to:
  /// **'View Invite'**
  String get viewInvite;

  /// No description provided for @myProperties.
  ///
  /// In en, this message translates to:
  /// **'My Properties'**
  String get myProperties;

  /// No description provided for @tenantEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No property assigned yet'**
  String get tenantEmptyStateTitle;

  /// No description provided for @tenantEmptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'If your landlord has sent you an invitation, it will appear here. Tap the button below to check for new invites.'**
  String get tenantEmptyStateMessage;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @invitationDeclinedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined.'**
  String get invitationDeclinedSuccess;

  /// No description provided for @confirmDeclineInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline Invitation?'**
  String get confirmDeclineInviteTitle;

  /// No description provided for @confirmDeclineInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this invitation? It will be removed from your pending list.'**
  String get confirmDeclineInviteMessage;

  /// No description provided for @contractStartDate.
  ///
  /// In en, this message translates to:
  /// **'Contract Start Date'**
  String get contractStartDate;

  /// No description provided for @contractEndDate.
  ///
  /// In en, this message translates to:
  /// **'Contract End Date'**
  String get contractEndDate;

  /// No description provided for @uploadContract.
  ///
  /// In en, this message translates to:
  /// **'Upload Contract'**
  String get uploadContract;

  /// No description provided for @viewContract.
  ///
  /// In en, this message translates to:
  /// **'View Contract'**
  String get viewContract;

  /// No description provided for @contractFile.
  ///
  /// In en, this message translates to:
  /// **'Contract File'**
  String get contractFile;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @serbianLatin.
  ///
  /// In en, this message translates to:
  /// **'Serbian (Latin)'**
  String get serbianLatin;

  /// No description provided for @serbianCyrillic.
  ///
  /// In en, this message translates to:
  /// **'Serbian (Cyrillic)'**
  String get serbianCyrillic;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @tenantMode.
  ///
  /// In en, this message translates to:
  /// **'Tenant Mode'**
  String get tenantMode;

  /// No description provided for @landlordMode.
  ///
  /// In en, this message translates to:
  /// **'Landlord Mode'**
  String get landlordMode;

  /// No description provided for @whatAreYou.
  ///
  /// In en, this message translates to:
  /// **'What would you like to continue as?'**
  String get whatAreYou;

  /// No description provided for @selectRoleToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a role to get started. You can switch anytime from the header above.'**
  String get selectRoleToContinue;

  /// No description provided for @consentTextFullBody.
  ///
  /// In en, this message translates to:
  /// **'By using the Stanomer application, you provide explicit consent for the processing of your personal data in accordance with the Law on Personal Data Protection (ZZPL) of the Republic of Serbia.\n\nWhat data is collected: Your name, e-mail address, IP address, and real estate lease agreement data.\n\nPurpose of processing: The data is used exclusively to facilitate communication between the landlord and the tenant, keep payment records, and create legally valid logs.\n\nData sharing: Your data is not sold to third parties. It is stored on secure servers in the EU (Supabase Frankfurt).\n\nYour rights: You have the right at any time to request access to your data or permanent deletion of your account and all associated data directly through the app.'**
  String get consentTextFullBody;

  /// No description provided for @removeTenant.
  ///
  /// In en, this message translates to:
  /// **'Remove Tenant'**
  String get removeTenant;

  /// No description provided for @removeTenantConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this tenant from the property? This will detach them and delete the invitation record.'**
  String get removeTenantConfirmation;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @logRentDeclared.
  ///
  /// In en, this message translates to:
  /// **'Tenant declared {month} rent as paid.'**
  String logRentDeclared(String month);

  /// No description provided for @logRentApproved.
  ///
  /// In en, this message translates to:
  /// **'Landlord approved {month} rent.'**
  String logRentApproved(String month);

  /// No description provided for @logRentRejected.
  ///
  /// In en, this message translates to:
  /// **'Landlord rejected {month} rent.'**
  String logRentRejected(String month);

  /// No description provided for @logMarkedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Landlord marked {month} as paid.'**
  String logMarkedAsPaid(String month);

  /// No description provided for @logMarkedAsPending.
  ///
  /// In en, this message translates to:
  /// **'Landlord marked {month} as pending.'**
  String logMarkedAsPending(String month);

  /// No description provided for @logAutoApproved.
  ///
  /// In en, this message translates to:
  /// **'{month} rent was auto-approved by system after 5 days.'**
  String logAutoApproved(String month);

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @noContractsTitle.
  ///
  /// In en, this message translates to:
  /// **'No contracts yet'**
  String get noContractsTitle;

  /// No description provided for @noContractsMessage.
  ///
  /// In en, this message translates to:
  /// **'To track rent and expenses for your property, first invite a tenant by entering contract details.'**
  String get noContractsMessage;

  /// No description provided for @inviteFirstTenant.
  ///
  /// In en, this message translates to:
  /// **'Invite First Tenant'**
  String get inviteFirstTenant;

  /// No description provided for @confirmCancelInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invitation'**
  String get confirmCancelInvitationTitle;

  /// No description provided for @confirmCancelInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to withdraw this invitation? This action will permanently delete it.'**
  String get confirmCancelInvitationMessage;

  /// No description provided for @confirmDeclineRevisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline Revision Request'**
  String get confirmDeclineRevisionTitle;

  /// No description provided for @confirmDeclineRevisionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline the tenant\'s revision request? The contract will remain pending with its original terms.'**
  String get confirmDeclineRevisionMessage;

  /// No description provided for @activeContract.
  ///
  /// In en, this message translates to:
  /// **'Active Lease'**
  String get activeContract;

  /// No description provided for @activeLease.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE LEASE'**
  String get activeLease;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation Sent'**
  String get invitationSent;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @declineRevisionRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline revision request'**
  String get declineRevisionRequest;

  /// No description provided for @pendingHeader.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingHeader;

  /// No description provided for @awaitingHeader.
  ///
  /// In en, this message translates to:
  /// **'AWAITING'**
  String get awaitingHeader;

  /// No description provided for @paidHeader.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paidHeader;

  /// No description provided for @waitingForTenantPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for tenant payment'**
  String get waitingForTenantPayment;

  /// No description provided for @waitingForYourApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your approval'**
  String get waitingForYourApproval;

  /// No description provided for @waitingForOwnerApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for owner approval'**
  String get waitingForOwnerApproval;

  /// No description provided for @waitingForYourPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your payment'**
  String get waitingForYourPayment;

  /// No description provided for @processCompleted.
  ///
  /// In en, this message translates to:
  /// **'Process completed'**
  String get processCompleted;

  /// No description provided for @declared.
  ///
  /// In en, this message translates to:
  /// **'declared'**
  String get declared;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'sent'**
  String get sent;

  /// No description provided for @noInvoice.
  ///
  /// In en, this message translates to:
  /// **'No Invoice'**
  String get noInvoice;

  /// No description provided for @uploadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Upload Invoice'**
  String get uploadInvoice;

  /// No description provided for @awaitingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Awaiting invoice'**
  String get awaitingInvoice;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateLabel;

  /// No description provided for @statusVacant.
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get statusVacant;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'PENDING APPROVAL'**
  String get pendingApproval;

  /// No description provided for @targetRent.
  ///
  /// In en, this message translates to:
  /// **'TARGET RENT'**
  String get targetRent;

  /// No description provided for @contractInfo.
  ///
  /// In en, this message translates to:
  /// **'Contract Info'**
  String get contractInfo;

  /// No description provided for @term.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get term;

  /// No description provided for @dueDay.
  ///
  /// In en, this message translates to:
  /// **'Due Day'**
  String get dueDay;

  /// No description provided for @contractDetails.
  ///
  /// In en, this message translates to:
  /// **'Contract Details'**
  String get contractDetails;

  /// No description provided for @pastContracts.
  ///
  /// In en, this message translates to:
  /// **'Past contracts'**
  String get pastContracts;

  /// No description provided for @previousLeasesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} previous leases'**
  String previousLeasesCount(int count);

  /// No description provided for @propertySettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Property settings'**
  String get propertySettingsLabel;

  /// No description provided for @propertyActions.
  ///
  /// In en, this message translates to:
  /// **'Property Actions'**
  String get propertyActions;

  /// No description provided for @leavePropertyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to leave this property?'**
  String get leavePropertyConfirm;

  /// No description provided for @leaveProperty.
  ///
  /// In en, this message translates to:
  /// **'Leave Property'**
  String get leaveProperty;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @pendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitations'**
  String get pendingInvitations;

  /// No description provided for @contractSettings.
  ///
  /// In en, this message translates to:
  /// **'Contract Settings'**
  String get contractSettings;

  /// No description provided for @activeContractTermsInfo.
  ///
  /// In en, this message translates to:
  /// **'Active contract terms. All updates made here take effect only when both tenant and landlord agree.'**
  String get activeContractTermsInfo;

  /// No description provided for @dueDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Due Day of Month'**
  String get dueDayOfMonth;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @taxConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Tax Configuration'**
  String get taxConfiguration;

  /// No description provided for @included.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get included;

  /// No description provided for @addedVat.
  ///
  /// In en, this message translates to:
  /// **'Added (+15%)'**
  String get addedVat;

  /// No description provided for @expensesHeader.
  ///
  /// In en, this message translates to:
  /// **'EXPENSES'**
  String get expensesHeader;

  /// No description provided for @extraPayment.
  ///
  /// In en, this message translates to:
  /// **'Extra payment'**
  String get extraPayment;

  /// No description provided for @utility.
  ///
  /// In en, this message translates to:
  /// **'Utility'**
  String get utility;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @proposeChangesInfo.
  ///
  /// In en, this message translates to:
  /// **'Changes will be sent for {role} approval. Current terms remain active until accepted.'**
  String proposeChangesInfo(String role);

  /// No description provided for @proposeChanges.
  ///
  /// In en, this message translates to:
  /// **'Propose Changes'**
  String get proposeChanges;

  /// No description provided for @declarePayment.
  ///
  /// In en, this message translates to:
  /// **'Declare Payment'**
  String get declarePayment;

  /// No description provided for @uploadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload Receipt'**
  String get uploadReceipt;

  /// No description provided for @paidInCash.
  ///
  /// In en, this message translates to:
  /// **'Paid in Cash'**
  String get paidInCash;

  /// No description provided for @noFinancialRecords.
  ///
  /// In en, this message translates to:
  /// **'No financial records found yet'**
  String get noFinancialRecords;

  /// No description provided for @noActiveContract.
  ///
  /// In en, this message translates to:
  /// **'No uploaded contract found'**
  String get noActiveContract;

  /// No description provided for @contractTermsInfo.
  ///
  /// In en, this message translates to:
  /// **'Active contract terms. All updates made here take effect only when both tenant and landlord agree.'**
  String get contractTermsInfo;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @totalRent.
  ///
  /// In en, this message translates to:
  /// **'Total Rent'**
  String get totalRent;

  /// No description provided for @infoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Covers pooled public utilities like heating, water, and waste.'**
  String get infoTooltip;

  /// No description provided for @electricityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Individual electricity consumption cost.'**
  String get electricityTooltip;

  /// No description provided for @internetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Subscription-based internet and TV packages.'**
  String get internetTooltip;

  /// No description provided for @maintenanceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Building cleaning, elevator maintenance, and common area costs.'**
  String get maintenanceTooltip;

  /// No description provided for @declare.
  ///
  /// In en, this message translates to:
  /// **'Declare'**
  String get declare;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get viewReceipt;

  /// No description provided for @proposesChanges.
  ///
  /// In en, this message translates to:
  /// **'{name} proposes the following changes:'**
  String proposesChanges(String name);

  /// No description provided for @awaitingApprovalInfo.
  ///
  /// In en, this message translates to:
  /// **'Your change proposal is awaiting the other party\'s approval.'**
  String get awaitingApprovalInfo;

  /// No description provided for @propertyDetails.
  ///
  /// In en, this message translates to:
  /// **'PROPERTY DETAILS'**
  String get propertyDetails;

  /// No description provided for @defaultLeaseTerms.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT LEASE TERMS'**
  String get defaultLeaseTerms;

  /// No description provided for @defaultLeaseTermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Target terms used as a template for new invitations.'**
  String get defaultLeaseTermsSubtitle;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @enterDayBetween1and31.
  ///
  /// In en, this message translates to:
  /// **'Enter a day between 1-31'**
  String get enterDayBetween1and31;

  /// No description provided for @expenseConfiguration.
  ///
  /// In en, this message translates to:
  /// **'EXPENSE CONFIGURATION'**
  String get expenseConfiguration;

  /// No description provided for @expenseInfostan.
  ///
  /// In en, this message translates to:
  /// **'Infostan'**
  String get expenseInfostan;

  /// No description provided for @expenseElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get expenseElectricity;

  /// No description provided for @expenseInternetTV.
  ///
  /// In en, this message translates to:
  /// **'Internet/TV'**
  String get expenseInternetTV;

  /// No description provided for @expenseMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Building Maintenance'**
  String get expenseMaintenance;

  /// No description provided for @expenseTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get expenseTax;

  /// No description provided for @tenantPaysTo.
  ///
  /// In en, this message translates to:
  /// **'Tenant pays to:'**
  String get tenantPaysTo;

  /// No description provided for @fileSelected.
  ///
  /// In en, this message translates to:
  /// **'File Selected'**
  String get fileSelected;

  /// No description provided for @selectInvoice.
  ///
  /// In en, this message translates to:
  /// **'Select Invoice'**
  String get selectInvoice;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @setAmountAndUploadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Set Amount & Upload Invoice'**
  String get setAmountAndUploadInvoice;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @paymentDeclared.
  ///
  /// In en, this message translates to:
  /// **'Payment declared successfully.'**
  String get paymentDeclared;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @parties.
  ///
  /// In en, this message translates to:
  /// **'PARTIES'**
  String get parties;

  /// No description provided for @tenantEmail.
  ///
  /// In en, this message translates to:
  /// **'Tenant Email'**
  String get tenantEmail;

  /// No description provided for @existingContractTermsInfo.
  ///
  /// In en, this message translates to:
  /// **'Existing agreed contract terms (rent, dates, and expenses) will apply to this tenant as well.'**
  String get existingContractTermsInfo;

  /// No description provided for @rentAndPayment.
  ///
  /// In en, this message translates to:
  /// **'RENT & PAYMENT'**
  String get rentAndPayment;

  /// No description provided for @datesAndContract.
  ///
  /// In en, this message translates to:
  /// **'DATES & CONTRACT'**
  String get datesAndContract;

  /// No description provided for @expenseSettingsHeader.
  ///
  /// In en, this message translates to:
  /// **'EXPENSE SETTINGS'**
  String get expenseSettingsHeader;

  /// No description provided for @editContract.
  ///
  /// In en, this message translates to:
  /// **'Edit Contract'**
  String get editContract;

  /// No description provided for @sendRevision.
  ///
  /// In en, this message translates to:
  /// **'Send Revision'**
  String get sendRevision;

  /// No description provided for @revisionSent.
  ///
  /// In en, this message translates to:
  /// **'Revision sent'**
  String get revisionSent;

  /// No description provided for @existingFileKept.
  ///
  /// In en, this message translates to:
  /// **'Existing File Kept'**
  String get existingFileKept;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @startAndEndDatesMandatory.
  ///
  /// In en, this message translates to:
  /// **'Start and end dates are mandatory'**
  String get startAndEndDatesMandatory;

  /// No description provided for @revisionRequested.
  ///
  /// In en, this message translates to:
  /// **'Revision Requested'**
  String get revisionRequested;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get statusPending;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusNegotiating.
  ///
  /// In en, this message translates to:
  /// **'Negotiating'**
  String get statusNegotiating;

  /// No description provided for @tenantPaysLandlord.
  ///
  /// In en, this message translates to:
  /// **'Tenant pays landlord'**
  String get tenantPaysLandlord;

  /// No description provided for @tenantPaysUtility.
  ///
  /// In en, this message translates to:
  /// **'Tenant pays utility'**
  String get tenantPaysUtility;

  /// No description provided for @includedInRent.
  ///
  /// In en, this message translates to:
  /// **'Included in rent'**
  String get includedInRent;

  /// No description provided for @changesAccepted.
  ///
  /// In en, this message translates to:
  /// **'Changes accepted'**
  String get changesAccepted;

  /// No description provided for @changesDeclined.
  ///
  /// In en, this message translates to:
  /// **'Changes declined'**
  String get changesDeclined;

  /// No description provided for @contractChangeProposal.
  ///
  /// In en, this message translates to:
  /// **'Contract Change Proposal'**
  String get contractChangeProposal;

  /// No description provided for @cancelProposal.
  ///
  /// In en, this message translates to:
  /// **'Cancel Proposal'**
  String get cancelProposal;

  /// No description provided for @viewInvoice.
  ///
  /// In en, this message translates to:
  /// **'View Invoice'**
  String get viewInvoice;

  /// No description provided for @paymentResponsibility.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT RESPONSIBILITY'**
  String get paymentResponsibility;

  /// No description provided for @tenantPaysDirectlyToUtility.
  ///
  /// In en, this message translates to:
  /// **'Tenant pays directly to the utility'**
  String get tenantPaysDirectlyToUtility;

  /// No description provided for @tenantPaysToLandlord.
  ///
  /// In en, this message translates to:
  /// **'Tenant pays to the landlord'**
  String get tenantPaysToLandlord;

  /// No description provided for @selectPaymentReceiverWarning.
  ///
  /// In en, this message translates to:
  /// **'Please select the payment receiver before continuing.'**
  String get selectPaymentReceiverWarning;

  /// No description provided for @progressSummary.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} paid • {sent} sent'**
  String progressSummary(int completed, int total, int sent);

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issues;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get newRequest;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get reportIssue;

  /// No description provided for @issueTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get issueTitle;

  /// No description provided for @issueDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get issueDescription;

  /// No description provided for @issueCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get issueCategory;

  /// No description provided for @issuePriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get issuePriority;

  /// No description provided for @statusInvestigating.
  ///
  /// In en, this message translates to:
  /// **'Investigating'**
  String get statusInvestigating;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @priorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get priorityNormal;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @categoryPlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get categoryPlumbing;

  /// No description provided for @categoryElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get categoryElectrical;

  /// No description provided for @categoryHeating.
  ///
  /// In en, this message translates to:
  /// **'Heating'**
  String get categoryHeating;

  /// No description provided for @categoryInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get categoryInternet;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @noIssuesTitle.
  ///
  /// In en, this message translates to:
  /// **'No issues reported yet'**
  String get noIssuesTitle;

  /// No description provided for @noIssuesMessage.
  ///
  /// In en, this message translates to:
  /// **'All good! No maintenance requests for this property.'**
  String get noIssuesMessage;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @issueDetails.
  ///
  /// In en, this message translates to:
  /// **'Issue Details'**
  String get issueDetails;

  /// No description provided for @logMaintenanceCreated.
  ///
  /// In en, this message translates to:
  /// **'Maintenance request created: {title}'**
  String logMaintenanceCreated(String title);

  /// No description provided for @logMaintenanceStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Maintenance status updated to {status}'**
  String logMaintenanceStatusUpdated(String status);

  /// No description provided for @logMaintenanceReopened.
  ///
  /// In en, this message translates to:
  /// **'Maintenance request reopened'**
  String get logMaintenanceReopened;

  /// No description provided for @logMaintenanceMessageAdded.
  ///
  /// In en, this message translates to:
  /// **'New message added to maintenance request'**
  String get logMaintenanceMessageAdded;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @mainContract.
  ///
  /// In en, this message translates to:
  /// **'Main Contract'**
  String get mainContract;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocument;

  /// No description provided for @enterDocumentName.
  ///
  /// In en, this message translates to:
  /// **'Enter document name'**
  String get enterDocumentName;

  /// No description provided for @noDocumentsYet.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get noDocumentsYet;

  /// No description provided for @additionalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Additional Documents'**
  String get additionalDocuments;

  /// No description provided for @deleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Delete Document'**
  String get deleteDocument;

  /// No description provided for @deleteDocumentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this document?'**
  String get deleteDocumentConfirm;

  /// No description provided for @uploadMainContract.
  ///
  /// In en, this message translates to:
  /// **'Upload Contract'**
  String get uploadMainContract;

  /// No description provided for @manageDocuments.
  ///
  /// In en, this message translates to:
  /// **'Manage Documents'**
  String get manageDocuments;

  /// No description provided for @monthlyCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get monthlyCollected;

  /// No description provided for @totalRentShort.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get totalRentShort;

  /// No description provided for @delays.
  ///
  /// In en, this message translates to:
  /// **'Delays'**
  String get delays;

  /// No description provided for @vacant.
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get vacant;

  /// No description provided for @overdueReceivables.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueReceivables;

  /// No description provided for @collectedByType.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collectedByType;

  /// No description provided for @propertiesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} property} other{{count} properties}}'**
  String propertiesCount(int count);

  /// No description provided for @hasDebt.
  ///
  /// In en, this message translates to:
  /// **'Has Debt'**
  String get hasDebt;

  /// No description provided for @paymentAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Approval'**
  String get paymentAwaitingApproval;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @debtLabel.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debtLabel;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @enterBill.
  ///
  /// In en, this message translates to:
  /// **'Enter Bill'**
  String get enterBill;

  /// No description provided for @addContractAndTenant.
  ///
  /// In en, this message translates to:
  /// **'Add Contract & Tenant'**
  String get addContractAndTenant;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @confirmApprovePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Payment'**
  String get confirmApprovePaymentTitle;

  /// No description provided for @confirmApprovePaymentMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this payment?'**
  String get confirmApprovePaymentMessage;

  /// No description provided for @confirmRejectPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Payment'**
  String get confirmRejectPaymentTitle;

  /// No description provided for @confirmRejectPaymentMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to reject this declaration and ask the tenant to re-declare?'**
  String get confirmRejectPaymentMessage;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @terminateContract.
  ///
  /// In en, this message translates to:
  /// **'Terminate Contract'**
  String get terminateContract;

  /// No description provided for @terminationDate.
  ///
  /// In en, this message translates to:
  /// **'Termination Date'**
  String get terminationDate;

  /// No description provided for @confirmTerminationTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminate Contract?'**
  String get confirmTerminationTitle;

  /// No description provided for @confirmTerminationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to send a termination request to end this contract on the selected date?'**
  String get confirmTerminationMessage;

  /// No description provided for @terminationRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Termination request sent successfully.'**
  String get terminationRequestSent;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive / Finished'**
  String get statusInactive;

  /// No description provided for @terminationRequested.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Termination'**
  String get terminationRequested;

  /// No description provided for @approveTermination.
  ///
  /// In en, this message translates to:
  /// **'Approve Termination'**
  String get approveTermination;

  /// No description provided for @declineTermination.
  ///
  /// In en, this message translates to:
  /// **'Decline Termination'**
  String get declineTermination;

  /// No description provided for @contractTerminatedOn.
  ///
  /// In en, this message translates to:
  /// **'Contract terminated on: {date}'**
  String contractTerminatedOn(Object date);

  /// No description provided for @contractWillEndOn.
  ///
  /// In en, this message translates to:
  /// **'Contract will end on: {date}'**
  String contractWillEndOn(String date);

  /// No description provided for @dispute.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get dispute;

  /// No description provided for @disputeReason.
  ///
  /// In en, this message translates to:
  /// **'Dispute Reason'**
  String get disputeReason;

  /// No description provided for @disputeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your reason for disputing...'**
  String get disputeReasonHint;

  /// No description provided for @disputedHeader.
  ///
  /// In en, this message translates to:
  /// **'DISPUTED'**
  String get disputedHeader;

  /// No description provided for @logRentDisputed.
  ///
  /// In en, this message translates to:
  /// **'Tenant disputed {month} payment: {reason}'**
  String logRentDisputed(String month, String reason);

  /// No description provided for @confirmDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute Payment'**
  String get confirmDisputeTitle;

  /// No description provided for @disputeSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your dispute has been sent to the landlord.'**
  String get disputeSentSuccess;

  /// No description provided for @takeAction.
  ///
  /// In en, this message translates to:
  /// **'Take Action'**
  String get takeAction;

  /// No description provided for @ownerNote.
  ///
  /// In en, this message translates to:
  /// **'Owner Note'**
  String get ownerNote;

  /// No description provided for @explanationOptional.
  ///
  /// In en, this message translates to:
  /// **'Explanation (Optional)'**
  String get explanationOptional;

  /// No description provided for @explanationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Checked the meter...'**
  String get explanationHint;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @tenantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tenants'**
  String get tenantsLabel;

  /// No description provided for @portfolioManagement.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Management'**
  String get portfolioManagement;

  /// No description provided for @paymentRequests.
  ///
  /// In en, this message translates to:
  /// **'Payment & Requests'**
  String get paymentRequests;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @confirmSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmSignOutMessage;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync Error: {error}'**
  String syncError(String error);

  /// No description provided for @acceptTermsWarning.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms before proceeding.'**
  String get acceptTermsWarning;

  /// No description provided for @maintenanceRequestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Maintenance request sent successfully.'**
  String get maintenanceRequestSuccess;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orLabel;

  /// No description provided for @errorUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error uploading photo: {error}'**
  String errorUploadingPhoto(String error);

  /// No description provided for @errorUpdatingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error updating status: {error}'**
  String errorUpdatingStatus(String error);

  /// No description provided for @errorReopeningRequest.
  ///
  /// In en, this message translates to:
  /// **'Error reopening request: {error}'**
  String errorReopeningRequest(String error);

  /// No description provided for @errorOpeningDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not open details: {error}'**
  String errorOpeningDetails(String error);

  /// No description provided for @nextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next Payment'**
  String get nextPayment;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @upcomingLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingLabel;

  /// No description provided for @joinPropertyInvitation.
  ///
  /// In en, this message translates to:
  /// **'Join Property Invitation'**
  String get joinPropertyInvitation;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback Sent'**
  String get feedbackSent;

  /// No description provided for @rentalProposal.
  ///
  /// In en, this message translates to:
  /// **'Rental Proposal'**
  String get rentalProposal;

  /// No description provided for @reviewContractTerms.
  ///
  /// In en, this message translates to:
  /// **'Please review the contract terms.'**
  String get reviewContractTerms;

  /// No description provided for @expenseDistribution.
  ///
  /// In en, this message translates to:
  /// **'Expense Distribution'**
  String get expenseDistribution;

  /// No description provided for @yourNote.
  ///
  /// In en, this message translates to:
  /// **'Your Note:'**
  String get yourNote;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @propertyDetailsHeader.
  ///
  /// In en, this message translates to:
  /// **'PROPERTY DETAILS'**
  String get propertyDetailsHeader;

  /// No description provided for @defaultLeaseTermsHeader.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT LEASE TERMS'**
  String get defaultLeaseTermsHeader;

  /// No description provided for @proposeRevision.
  ///
  /// In en, this message translates to:
  /// **'Propose Revision'**
  String get proposeRevision;

  /// No description provided for @revisionTermsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which terms would you like to change? (Rent, due day, expenses, etc.)'**
  String get revisionTermsQuestion;

  /// No description provided for @enterNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your notes here...'**
  String get enterNotesHint;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @invitedToJoinProperty.
  ///
  /// In en, this message translates to:
  /// **'You have been invited to join {property}.'**
  String invitedToJoinProperty(String property);

  /// No description provided for @waitingForLandlord.
  ///
  /// In en, this message translates to:
  /// **'Waiting for landlord to respond...'**
  String get waitingForLandlord;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @acceptTermsAndDistribution.
  ///
  /// In en, this message translates to:
  /// **'I accept the contract terms and expense distribution.'**
  String get acceptTermsAndDistribution;

  /// No description provided for @datesMandatory.
  ///
  /// In en, this message translates to:
  /// **'Start and end dates are mandatory'**
  String get datesMandatory;

  /// No description provided for @partiesHeader.
  ///
  /// In en, this message translates to:
  /// **'PARTIES'**
  String get partiesHeader;

  /// No description provided for @leaseLockedWarning.
  ///
  /// In en, this message translates to:
  /// **'Existing agreed contract terms (rent, dates, and expenses) will apply to this tenant as well.'**
  String get leaseLockedWarning;

  /// No description provided for @rentPaymentHeader.
  ///
  /// In en, this message translates to:
  /// **'RENT & PAYMENT'**
  String get rentPaymentHeader;

  /// No description provided for @loadingPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingPlaceholder;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get ended;

  /// No description provided for @plannedEnd.
  ///
  /// In en, this message translates to:
  /// **'Planned End: {date}'**
  String plannedEnd(String date);

  /// No description provided for @yourApartment.
  ///
  /// In en, this message translates to:
  /// **'Your Apartment'**
  String get yourApartment;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get commentHint;

  /// No description provided for @issueResolvedStatus.
  ///
  /// In en, this message translates to:
  /// **'This issue has been marked as resolved.'**
  String get issueResolvedStatus;

  /// No description provided for @reopenIssue.
  ///
  /// In en, this message translates to:
  /// **'Still an Issue (Reopen)'**
  String get reopenIssue;

  /// No description provided for @deleteRequest.
  ///
  /// In en, this message translates to:
  /// **'Delete Request'**
  String get deleteRequest;

  /// No description provided for @terminationApproved.
  ///
  /// In en, this message translates to:
  /// **'Termination Approved'**
  String get terminationApproved;

  /// No description provided for @paymentDeclaredHand.
  ///
  /// In en, this message translates to:
  /// **'Payment declared as hand delivery.'**
  String get paymentDeclaredHand;

  /// No description provided for @fileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read file.'**
  String get fileUnreadable;

  /// No description provided for @paymentDeclaredSuccess.
  ///
  /// In en, this message translates to:
  /// **'{title} payment declared.'**
  String paymentDeclaredSuccess(String title);

  /// No description provided for @setAmountUploadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Set Amount & Upload Invoice'**
  String get setAmountUploadInvoice;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message:'**
  String get yourMessage;

  /// No description provided for @revisionRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Revision Request:'**
  String get revisionRequestLabel;

  /// No description provided for @noActivityLogs.
  ///
  /// In en, this message translates to:
  /// **'No activity logs found yet'**
  String get noActivityLogs;

  /// No description provided for @landlordProposedChanges.
  ///
  /// In en, this message translates to:
  /// **'Landlord proposed contract changes. Tap to review.'**
  String get landlordProposedChanges;

  /// No description provided for @tenantProposedChanges.
  ///
  /// In en, this message translates to:
  /// **'Tenant proposed contract changes. Tap to review.'**
  String get tenantProposedChanges;

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due on {date}'**
  String dueOn(String date);

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get item;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @waitingForOtherParty.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval from the other party...'**
  String get waitingForOtherParty;

  /// No description provided for @awaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval...'**
  String get awaitingApproval;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String paidOn(Object date);

  /// No description provided for @cannotInviteSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot invite yourself as a tenant.'**
  String get cannotInviteSelf;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Stanomer Premium'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove limits in property management.'**
  String get paywallSubtitle;

  /// No description provided for @unlimitedProperties.
  ///
  /// In en, this message translates to:
  /// **'Unlimited property addition and management'**
  String get unlimitedProperties;

  /// No description provided for @detailedReporting.
  ///
  /// In en, this message translates to:
  /// **'Faster and more detailed reporting'**
  String get detailedReporting;

  /// No description provided for @extraStorage.
  ///
  /// In en, this message translates to:
  /// **'More storage space'**
  String get extraStorage;

  /// No description provided for @pdfContracts.
  ///
  /// In en, this message translates to:
  /// **'PDF contract generation (Coming Soon)'**
  String get pdfContracts;

  /// No description provided for @automatedRenewal.
  ///
  /// In en, this message translates to:
  /// **'Automated rent calculation and renewal (Coming Soon)'**
  String get automatedRenewal;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @limitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your free limit'**
  String get limitReachedTitle;

  /// No description provided for @limitReachedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Stanomer Premium to manage multiple properties.'**
  String get limitReachedSubtitle;

  /// No description provided for @discoverPremium.
  ///
  /// In en, this message translates to:
  /// **'Discover Premium'**
  String get discoverPremium;

  /// No description provided for @optionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription options.'**
  String get optionsLoadFailed;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @premiumMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Mobile App Required'**
  String get premiumMobileOnly;

  /// No description provided for @premiumMobileOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Stanomer Premium subscriptions can only be purchased through the mobile app. Download the app below to get started with Premium.'**
  String get premiumMobileOnlyDesc;

  /// No description provided for @downloadOnAppStore.
  ///
  /// In en, this message translates to:
  /// **'Download on the App Store'**
  String get downloadOnAppStore;

  /// No description provided for @downloadOnPlayStore.
  ///
  /// In en, this message translates to:
  /// **'Get it on Google Play'**
  String get downloadOnPlayStore;

  /// No description provided for @premiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get premiumFeatures;

  /// No description provided for @premiumFeature1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited property management'**
  String get premiumFeature1;

  /// No description provided for @premiumFeature2.
  ///
  /// In en, this message translates to:
  /// **'Advanced financial reporting'**
  String get premiumFeature2;

  /// No description provided for @premiumFeature3.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get premiumFeature3;

  /// No description provided for @premiumFeature4.
  ///
  /// In en, this message translates to:
  /// **'Access across all platforms'**
  String get premiumFeature4;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service & EULA'**
  String get termsOfService;

  /// No description provided for @termsOfServiceContent.
  ///
  /// In en, this message translates to:
  /// **'Stanomer – End User License Agreement (EULA) & Terms of Service\nLast Updated: April 23, 2026\n\n1. Introduction\nThis End User License Agreement (\"Agreement\") is a legal agreement between you (\"User\") and Stanomer (\"we,\" \"us,\" or \"our\"). By installing or using the Stanomer mobile application (\"App\"), you agree to be bound by the terms of this Agreement.\n\n2. Apple and Google Terms\nApple App Store: This Agreement is concluded between the User and Stanomer only, and not with Apple Inc. This agreement incorporates Apple’s Standard Licensed Application End User License Agreement (Standard EULA) by reference: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/\n\nGoogle Play Store: This Agreement is concluded between the User and Stanomer only, and not with Google LLC.\n\nYou acknowledge that Apple and Google have no obligation whatsoever to furnish any maintenance and support services with respect to the App.\n\n3. Subscription and Billing (Auto-Renewable Subscriptions)\nStanomer offers premium features via auto-renewable subscriptions.\n\nPayment: Payment will be charged to your iTunes Account (Apple) or Google Play Account at confirmation of purchase.\n\nRenewal: Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period.\n\nManagement: You can manage or turn off auto-renew in your Account Settings (App Store or Play Store) after purchase.\n\n4. User Content & Conduct\nYou are responsible for the data you enter (rental amounts, damage reports, contracts).\n\nYou may not upload illegal, offensive, or infringing content.\n\nStanomer reserves the right to remove any content that violates Serbian laws or these terms.\n\n5. Privacy and Global Data Protection (ZZPL, GDPR, KVKK Compliance)\nYour use of the App is governed by our Privacy Policy. We are committed to protecting your personal data in compliance with:\n\nSerbian Law (ZZPL): Zakon o zaštiti podataka o ličnosti.\n\nGDPR: General Data Protection Regulation (EU).\n\nKVKK: Personal Data Protection Law (Turkey).\n\nOther International Standards: We adhere to global data privacy principles to ensure your information is handled securely regardless of your location.\n\n6. Limitation of Liability\nStanomer provides a platform for rental management and is not a party to the actual rental agreements between landlords and tenants. We are not liable for disputes arising between users or for financial transactions conducted outside the platform.\n\n7. Termination\nThis Agreement is effective until terminated by you or Stanomer. Your rights under this license will terminate automatically if you fail to comply with any of its terms.'**
  String get termsOfServiceContent;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'sr', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'sr': {
  switch (locale.scriptCode) {
    case 'Cyrl': return AppLocalizationsSrCyrl();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'sr': return AppLocalizationsSr();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
