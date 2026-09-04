// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stanomer';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get landlord => 'Landlord';

  @override
  String get tenant => 'Tenant';

  @override
  String get zzplConsent =>
      'I agree to the processing of my data in accordance with the Law on Personal Data Protection (ZZPL) of Serbia.';

  @override
  String get selectRole => 'Select your role';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get consentRequired => 'You must accept the ZZPL consent to continue';

  @override
  String get loginToAccount => 'Login to your account';

  @override
  String get createAccount => 'Create a new account';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get fullName => 'Full Name';

  @override
  String get errorSelectRole => 'Please select your role';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountWarning =>
      'This action is permanent and cannot be undone. All your data will be deleted.';

  @override
  String get confirmPasswordForDeletion =>
      'Please enter your password to confirm deletion';

  @override
  String get deleteButtonLabel => 'Permanently Delete My Account';

  @override
  String get cancel => 'Cancel';

  @override
  String get invalidPassword => 'Invalid password';

  @override
  String get welcomeToStanomer => 'Welcome to Stanomer';

  @override
  String get consentTextFullTitle =>
      'Consent for Personal Data Processing (ZZPL)';

  @override
  String get profile => 'Profile';

  @override
  String get settingsHeader => 'Settings';

  @override
  String get accountHeader => 'Account';

  @override
  String get discoverPremium => 'Discover Premium';

  @override
  String get unlimitedLeaseContracts => 'Unlimited lease contracts';

  @override
  String get updateName => 'Update Name';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get oldPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get passwordChangedSuccess => 'Password updated successfully';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get role => 'Role';

  @override
  String get roleLandlord => 'Landlord';

  @override
  String get roleTenant => 'Tenant';

  @override
  String get logout => 'Sign Out';

  @override
  String get addProperty => 'Add Property';

  @override
  String get address => 'Address';

  @override
  String get monthlyRent => 'Monthly Rent';

  @override
  String get depositAmount => 'Deposit Amount';

  @override
  String get currency => 'Currency';

  @override
  String get propertyName => 'Property Name';

  @override
  String get propertyNameHint => 'e.g. Belgrad Apartment';

  @override
  String get propertyAddedSuccess => 'Property added successfully';

  @override
  String get propertyUpdatedSuccess => 'Property updated successfully';

  @override
  String get noProperties => 'No properties found';

  @override
  String get addYourFirstProperty =>
      'Add your first property to start tracking!';

  @override
  String get editProperty => 'Edit Property';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDeleteTitle => 'Delete Property';

  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to delete this property? This action cannot be undone.';

  @override
  String get propertyDeletedSuccess => 'Property deleted successfully';

  @override
  String get inviteTenant => 'Invite Tenant';

  @override
  String get emailHint => 'Enter tenant\'s email address';

  @override
  String get inviteCreatedSuccess =>
      'Invite link created! You can now share it.';

  @override
  String get shareInviteLink => 'Share Invite Link';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get noInvitesYet => 'No invitations sent yet';

  @override
  String get cancelInvitation => 'Cancel Invitation';

  @override
  String get invitationCancelledSuccess => 'Invitation cancelled successfully';

  @override
  String get pendingInvite => 'Pending Invite';

  @override
  String get contractSentToTenant => 'Contract sent to tenant';

  @override
  String get overview => 'Overview';

  @override
  String get financials => 'Financials';

  @override
  String get propertySettings => 'Settings';

  @override
  String get invitationHistory => 'Invite History';

  @override
  String get invitationDetails => 'Invitation Details';

  @override
  String get acceptInvitation => 'Yes, I rented this place';

  @override
  String get declineInvitation => 'Decline Invitation';

  @override
  String get inviteNotFound => 'Invitation not found or expired';

  @override
  String get invitationAcceptedSuccess => 'Welcome home! Invitation accepted.';

  @override
  String pendingInvitationBanner(String property) {
    return 'You have a pending invitation for $property';
  }

  @override
  String invitedBy(String name) {
    return 'Invited by $name';
  }

  @override
  String get yourName => 'Your Name';

  @override
  String get yourNameHint => 'Enter your full name';

  @override
  String get viewInvite => 'View Invite';

  @override
  String get myProperty => 'My Property';

  @override
  String get myProperties => 'My Properties';

  @override
  String get tenantEmptyStateTitle => 'No property assigned yet';

  @override
  String get tenantEmptyStateMessage =>
      'If your landlord has sent you an invitation, it will appear here. Tap the button below to check for new invites.';

  @override
  String get refresh => 'Refresh';

  @override
  String get invitationDeclinedSuccess => 'Invitation declined.';

  @override
  String get confirmDeclineInviteTitle => 'Decline Invitation?';

  @override
  String get confirmDeclineInviteMessage =>
      'Are you sure you want to decline this invitation? It will be removed from your pending list.';

  @override
  String get contractStartDate => 'Contract Start Date';

  @override
  String get contractEndDate => 'Contract End Date';

  @override
  String get uploadContract => 'Upload Contract';

  @override
  String get viewContract => 'View Contract';

  @override
  String get contractFile => 'Contract File';

  @override
  String get selectDate => 'Select Date';

  @override
  String get appLanguage => 'App Language';

  @override
  String get english => 'English';

  @override
  String get serbianLatin => 'Serbian (Latin)';

  @override
  String get serbianCyrillic => 'Serbian (Cyrillic)';

  @override
  String get turkish => 'Turkish';

  @override
  String get russian => 'Russian';

  @override
  String get tenantMode => 'Tenant Mode';

  @override
  String get landlordMode => 'Landlord Mode';

  @override
  String get whatAreYou => 'What would you like to continue as?';

  @override
  String get selectRoleToContinue =>
      'Select a role to get started. You can switch anytime from the header above.';

  @override
  String get consentTextFullBody =>
      'By using the Stanomer application, you provide explicit consent for the processing of your personal data in accordance with the Law on Personal Data Protection (ZZPL) of the Republic of Serbia.\n\nWhat data is collected: Your name, e-mail address, IP address, and real estate lease agreement data.\n\nPurpose of processing: The data is used exclusively to facilitate communication between the landlord and the tenant, keep payment records, and create legally valid logs.\n\nData sharing: Your data is not sold to third parties. It is stored on secure servers in the EU (Supabase Frankfurt).\n\nYour rights: You have the right at any time to request access to your data or permanent deletion of your account and all associated data directly through the app.';

  @override
  String get removeTenant => 'Remove Tenant';

  @override
  String get removeTenantConfirmation =>
      'Are you sure you want to remove this tenant from the property? This will detach them and delete the invitation record.';

  @override
  String get remove => 'Remove';

  @override
  String logRentDeclared(String month) {
    return 'Tenant declared $month rent as paid.';
  }

  @override
  String logRentApproved(String month) {
    return 'Landlord approved $month rent.';
  }

  @override
  String logRentRejected(String month) {
    return 'Landlord rejected $month rent.';
  }

  @override
  String logMarkedAsPaid(String month) {
    return 'Landlord marked $month as paid.';
  }

  @override
  String logMarkedAsPending(String month) {
    return 'Landlord marked $month as pending.';
  }

  @override
  String logAutoApproved(String month) {
    return '$month rent was auto-approved by system after 5 days.';
  }

  @override
  String get activity => 'Activity';

  @override
  String get noContractsTitle => 'No contracts yet';

  @override
  String get noContractsMessage =>
      'To track rent and expenses for your property, first invite a tenant by entering contract details.';

  @override
  String get inviteFirstTenant => 'Invite Tenant';

  @override
  String get confirmCancelInvitationTitle => 'Cancel Invitation';

  @override
  String get confirmCancelInvitationMessage =>
      'Are you sure you want to withdraw this invitation? This action will permanently delete it.';

  @override
  String get confirmDeclineRevisionTitle => 'Decline Revision Request';

  @override
  String get confirmDeclineRevisionMessage =>
      'Are you sure you want to decline the tenant\'s revision request? The contract will remain pending with its original terms.';

  @override
  String get activeContract => 'Active Lease';

  @override
  String get activeLease => 'ACTIVE LEASE';

  @override
  String get invitationSent => 'Invitation Sent';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get declineRevisionRequest => 'Decline revision request';

  @override
  String get pendingHeader => 'PENDING';

  @override
  String get awaitingHeader => 'AWAITING';

  @override
  String get awaitingExplanation =>
      'Landlord approval is required to mark payments as paid.';

  @override
  String get paidHeader => 'PAID';

  @override
  String get waitingForTenantPayment => 'Waiting for tenant payment';

  @override
  String get waitingForYourApproval => 'Waiting for your approval';

  @override
  String get waitingForOwnerApproval => 'Waiting for owner approval';

  @override
  String get waitingForAgency => 'Waiting for agency to respond...';

  @override
  String get waitingForAgencyApproval => 'Waiting for agency approval';

  @override
  String get waitingForYourPayment => 'Waiting for your payment';

  @override
  String get processCompleted => 'Process completed';

  @override
  String get declared => 'declared';

  @override
  String get sent => 'sent';

  @override
  String get noInvoice => 'No Invoice';

  @override
  String get uploadInvoice => 'Upload Bill';

  @override
  String get awaitingInvoice => 'Awaiting bill';

  @override
  String get updateLabel => 'Update';

  @override
  String get statusVacant => 'Vacant';

  @override
  String get pendingApproval => 'PENDING APPROVAL';

  @override
  String get targetRent => 'TARGET RENT';

  @override
  String get contractInfo => 'Contract Info';

  @override
  String get term => 'Term';

  @override
  String get dueDay => 'Due Day';

  @override
  String get contractDetails => 'Contract Details';

  @override
  String get pastContracts => 'Past contracts';

  @override
  String previousLeasesCount(int count) {
    return '$count previous leases';
  }

  @override
  String get propertySettingsLabel => 'Property settings';

  @override
  String get propertyActions => 'Property Actions';

  @override
  String get leavePropertyConfirm => 'Do you want to leave this property?';

  @override
  String get leaveProperty => 'Leave Property';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get pendingInvitations => 'Pending Invitations';

  @override
  String get contractSettings => 'Contract Settings';

  @override
  String get activeContractTermsInfo =>
      'Active contract terms. All updates made here take effect only when both tenant and landlord agree.';

  @override
  String get dueDayOfMonth => 'Due Day of Month';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get taxConfiguration => 'Tax Configuration';

  @override
  String get included => 'Included';

  @override
  String get addedVat => 'Added (+15%)';

  @override
  String get expensesHeader => 'EXPENSES';

  @override
  String get extraPayment => 'Extra payment';

  @override
  String get utility => 'Utility';

  @override
  String get owner => 'Owner';

  @override
  String proposeChangesInfo(String role) {
    return 'Changes will be sent for $role approval. Current terms remain active until accepted.';
  }

  @override
  String get proposeChanges => 'Propose Changes';

  @override
  String get declarePayment => 'Declare Payment';

  @override
  String get uploadReceipt => 'Upload Payment Receipt';

  @override
  String get paidInCash => 'Paid in Cash';

  @override
  String get noFinancialRecords => 'No financial records found yet';

  @override
  String get noActiveContract => 'No uploaded contract found';

  @override
  String get contractTermsInfo =>
      'Active contract terms. All updates made here take effect only when both tenant and landlord agree.';

  @override
  String get send => 'Send';

  @override
  String get totalRent => 'Total Rent';

  @override
  String get infoTooltip =>
      'Covers pooled public utilities like heating, water, and waste.';

  @override
  String get electricityTooltip => 'Individual electricity consumption cost.';

  @override
  String get internetTooltip => 'Subscription-based internet and TV packages.';

  @override
  String get maintenanceTooltip =>
      'Building cleaning, elevator maintenance, and common area costs.';

  @override
  String get declare => 'Declare';

  @override
  String get viewReceipt => 'View Receipt';

  @override
  String proposesChanges(String name) {
    return '$name proposes the following changes:';
  }

  @override
  String get awaitingApprovalInfo =>
      'Your change proposal is awaiting the other party\'s approval.';

  @override
  String get propertyDetails => 'PROPERTY DETAILS';

  @override
  String get defaultLeaseTerms => 'DEFAULT LEASE TERMS';

  @override
  String get defaultLeaseTermsSubtitle =>
      'Target terms used as a template for new invitations.';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get enterDayBetween1and31 => 'Enter a day between 1-31';

  @override
  String get expenseConfiguration => 'EXPENSE CONFIGURATION';

  @override
  String get expenseInfostan => 'Infostan';

  @override
  String get expenseElectricity => 'Electricity';

  @override
  String get expenseInternetTV => 'Internet/TV';

  @override
  String get expenseMaintenance => 'Building Maintenance';

  @override
  String get expenseTax => 'Tax';

  @override
  String get tenantPaysTo => 'Tenant pays to:';

  @override
  String get fileSelected => 'File Selected';

  @override
  String get selectInvoice => 'Select Invoice';

  @override
  String get amount => 'Amount';

  @override
  String get setAmountAndUploadInvoice => 'Enter bill details';

  @override
  String get save => 'Save';

  @override
  String get paymentDeclared => 'Payment declared successfully.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get parties => 'PARTIES';

  @override
  String get tenantEmail => 'Tenant Email';

  @override
  String get existingContractTermsInfo =>
      'Existing agreed contract terms (rent, dates, and expenses) will apply to this tenant as well.';

  @override
  String get rentAndPayment => 'RENT & PAYMENT';

  @override
  String get datesAndContract => 'DATES & CONTRACT';

  @override
  String get expenseSettingsHeader => 'EXPENSE SETTINGS';

  @override
  String get editContract => 'Edit Contract';

  @override
  String get sendRevision => 'Send Revision';

  @override
  String get revisionSent => 'Revision sent';

  @override
  String get existingFileKept => 'Existing File Kept';

  @override
  String get done => 'Done';

  @override
  String get startAndEndDatesMandatory => 'Start and end dates are mandatory';

  @override
  String get revisionRequested => 'Revision Requested';

  @override
  String get statusActive => 'Active';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusDeclined => 'Declined';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusNegotiating => 'Negotiating';

  @override
  String get tenantPaysLandlord => 'Tenant pays landlord';

  @override
  String get tenantPaysUtility => 'Tenant pays utility';

  @override
  String get includedInRent => 'Included in rent';

  @override
  String get changesAccepted => 'Changes accepted';

  @override
  String get changesDeclined => 'Changes declined';

  @override
  String get contractChangeProposal => 'Contract Change Proposal';

  @override
  String get cancelProposal => 'Cancel Proposal';

  @override
  String get viewInvoice => 'View Bill';

  @override
  String get paymentResponsibility => 'PAYMENT RESPONSIBILITY';

  @override
  String get tenantPaysDirectlyToUtility =>
      'Tenant pays directly to the utility';

  @override
  String get tenantPaysToLandlord => 'Tenant pays to the landlord';

  @override
  String get selectPaymentReceiverWarning =>
      'Please select the payment receiver before continuing.';

  @override
  String progressSummary(int completed, int total, int sent) {
    return '$completed / $total paid • $sent sent';
  }

  @override
  String get maintenance => 'Maintenance';

  @override
  String get issues => 'Issues';

  @override
  String get newRequest => 'New Request';

  @override
  String get reportIssue => 'Report an Issue';

  @override
  String get issueTitle => 'Title';

  @override
  String get issueDescription => 'Description';

  @override
  String get issueCategory => 'Category';

  @override
  String get issuePriority => 'Priority';

  @override
  String get statusInvestigating => 'Investigating';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get categoryPlumbing => 'Plumbing';

  @override
  String get categoryElectrical => 'Electrical';

  @override
  String get categoryHeating => 'Heating';

  @override
  String get categoryInternet => 'Internet';

  @override
  String get categoryAppliance => 'Appliance & Equipment';

  @override
  String get categoryStructural => 'Structural & Building';

  @override
  String get categoryOther => 'Other';

  @override
  String get noIssuesTitle => 'No issues reported yet';

  @override
  String get noIssuesMessage =>
      'All good! No maintenance requests for this property.';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get issueDetails => 'Issue Details';

  @override
  String logMaintenanceCreated(String title) {
    return 'Maintenance request created: $title';
  }

  @override
  String logMaintenanceStatusUpdated(String status) {
    return 'Maintenance status updated to $status';
  }

  @override
  String get logMaintenanceReopened => 'Maintenance request reopened';

  @override
  String get logMaintenanceMessageAdded =>
      'New message added to maintenance request';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get documents => 'Documents';

  @override
  String get mainContract => 'Main Contract';

  @override
  String get addDocument => 'Add Document';

  @override
  String get enterDocumentName => 'Enter document name';

  @override
  String get noDocumentsYet => 'No documents yet';

  @override
  String get additionalDocuments => 'Additional Documents';

  @override
  String get deleteDocument => 'Delete Document';

  @override
  String get deleteDocumentConfirm =>
      'Are you sure you want to delete this document?';

  @override
  String get uploadMainContract => 'Upload Contract';

  @override
  String get manageDocuments => 'Manage Documents';

  @override
  String get monthlyCollected => 'Collected';

  @override
  String get totalRentShort => 'Rent';

  @override
  String get delays => 'Delays';

  @override
  String get vacant => 'Vacant';

  @override
  String get overdueReceivables => 'Overdue';

  @override
  String get collectedByType => 'Collected';

  @override
  String propertiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count properties',
      one: '$count property',
    );
    return '$_temp0';
  }

  @override
  String get hasDebt => 'Has Debt';

  @override
  String get paymentAwaitingApproval => 'Awaiting Approval';

  @override
  String get rent => 'Rent';

  @override
  String get bills => 'Bills';

  @override
  String get waiting => 'Waiting';

  @override
  String get debtLabel => 'Debt';

  @override
  String get totalDebt => 'Total Debt';

  @override
  String get paidLabel => 'Paid';

  @override
  String get enterBill => 'Enter Bill';

  @override
  String get addContractAndTenant => 'Add Contract & Tenant';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get confirmApprovePaymentTitle => 'Approve Payment';

  @override
  String get confirmApprovePaymentMessage =>
      'Are you sure you want to approve this payment?';

  @override
  String get confirmRejectPaymentTitle => 'Reject Payment';

  @override
  String get confirmRejectPaymentMessage =>
      'Do you want to reject this declaration and ask the tenant to re-declare?';

  @override
  String get confirm => 'Confirm';

  @override
  String get terminateContract => 'Terminate Contract';

  @override
  String get terminationDate => 'Termination Date';

  @override
  String get confirmTerminationTitle => 'Terminate Contract?';

  @override
  String get confirmTerminationMessage =>
      'Are you sure you want to send a termination request to end this contract on the selected date?';

  @override
  String get terminationRequestSent => 'Termination request sent successfully.';

  @override
  String get statusInactive => 'Inactive / Finished';

  @override
  String get terminationRequested => 'Awaiting Termination';

  @override
  String get approveTermination => 'Approve Termination';

  @override
  String get declineTermination => 'Decline Termination';

  @override
  String contractTerminatedOn(Object date) {
    return 'Contract terminated on: $date';
  }

  @override
  String contractWillEndOn(String date) {
    return 'Contract will end on: $date';
  }

  @override
  String get dispute => 'Dispute';

  @override
  String get disputeReason => 'Dispute Reason';

  @override
  String get disputeReasonHint => 'Enter your reason for disputing...';

  @override
  String get disputedHeader => 'DISPUTED';

  @override
  String logRentDisputed(String month, String reason) {
    return 'Tenant disputed $month payment: $reason';
  }

  @override
  String get confirmDisputeTitle => 'Dispute Payment';

  @override
  String get disputeSentSuccess =>
      'Your dispute has been sent to the landlord.';

  @override
  String get takeAction => 'Take Action';

  @override
  String get ownerNote => 'Owner Note';

  @override
  String get explanationOptional => 'Explanation (Optional)';

  @override
  String get explanationHint => 'e.g. Checked the meter...';

  @override
  String get units => 'Units';

  @override
  String get tenantsLabel => 'Tenants';

  @override
  String get portfolioManagement => 'Portfolio Management';

  @override
  String get paymentRequests => 'Payment & Requests';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get confirmSignOutMessage => 'Are you sure you want to sign out?';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String syncError(String error) {
    return 'Sync Error: $error';
  }

  @override
  String get acceptTermsWarning => 'Please accept the terms before proceeding.';

  @override
  String get maintenanceRequestSuccess =>
      'Maintenance request sent successfully.';

  @override
  String get ok => 'OK';

  @override
  String get orLabel => 'OR';

  @override
  String errorUploadingPhoto(String error) {
    return 'Error uploading photo: $error';
  }

  @override
  String errorUpdatingStatus(String error) {
    return 'Error updating status: $error';
  }

  @override
  String errorReopeningRequest(String error) {
    return 'Error reopening request: $error';
  }

  @override
  String errorOpeningDetails(String error) {
    return 'Could not open details: $error';
  }

  @override
  String get nextPayment => 'Next Payment';

  @override
  String get payNow => 'Pay Now';

  @override
  String get upcomingLabel => 'Upcoming';

  @override
  String get joinPropertyInvitation => 'Join Property Invitation';

  @override
  String get feedbackSent => 'Feedback Sent';

  @override
  String get rentalProposal => 'Rental Proposal';

  @override
  String get reviewContractTerms => 'Please review the contract terms.';

  @override
  String get expenseDistribution => 'Expense Distribution';

  @override
  String get yourNote => 'Your Note:';

  @override
  String get backToDashboard => 'Back to Dashboard';

  @override
  String get propertyDetailsHeader => 'PROPERTY INFO';

  @override
  String get defaultLeaseTermsHeader => 'DEFAULT LEASE TERMS';

  @override
  String get proposeRevision => 'Propose Revision';

  @override
  String get revisionTermsQuestion =>
      'Which terms would you like to change? (Rent, due day, expenses, etc.)';

  @override
  String get enterNotesHint => 'Enter your notes here...';

  @override
  String get submit => 'Submit';

  @override
  String invitedToJoinProperty(String property) {
    return 'You have been invited to join $property.';
  }

  @override
  String get waitingForLandlord => 'Waiting for landlord to respond...';

  @override
  String get day => 'Day';

  @override
  String get notSelected => 'Not selected';

  @override
  String get acceptTermsAndDistribution =>
      'I accept the contract terms and expense distribution.';

  @override
  String get datesMandatory => 'Start and end dates are mandatory';

  @override
  String get partiesHeader => 'PARTIES';

  @override
  String get leaseLockedWarning =>
      'Existing agreed contract terms (rent, dates, and expenses) will apply to this tenant as well.';

  @override
  String get rentPaymentHeader => 'RENT & PAYMENT';

  @override
  String get loadingPlaceholder => 'Loading...';

  @override
  String get photos => 'Photos';

  @override
  String get add => 'Add';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get viewAll => 'View All';

  @override
  String get ended => 'Ended';

  @override
  String plannedEnd(String date) {
    return 'Planned End: $date';
  }

  @override
  String get yourApartment => 'Your Apartment';

  @override
  String get commentHint => 'Add a comment...';

  @override
  String get issueResolvedStatus => 'This issue has been marked as resolved.';

  @override
  String get reopenIssue => 'Still an Issue (Reopen)';

  @override
  String get deleteRequest => 'Delete Request';

  @override
  String get terminationApproved => 'Termination Approved';

  @override
  String get paymentDeclaredHand => 'Payment declared as hand delivery.';

  @override
  String get fileUnreadable => 'Could not read file.';

  @override
  String paymentDeclaredSuccess(String title) {
    return '$title payment declared.';
  }

  @override
  String get setAmountUploadInvoice => 'Enter bill details';

  @override
  String get yourMessage => 'Your message:';

  @override
  String get revisionRequestLabel => 'Revision Request:';

  @override
  String get noActivityLogs => 'No activity logs found yet';

  @override
  String get landlordProposedChanges =>
      'Landlord proposed contract changes. Tap to review.';

  @override
  String get tenantProposedChanges =>
      'Tenant proposed contract changes. Tap to review.';

  @override
  String dueOn(String date) {
    return 'Due on $date';
  }

  @override
  String get item => 'item';

  @override
  String get items => 'items';

  @override
  String get waitingForOtherParty =>
      'Awaiting approval from the other party...';

  @override
  String get awaitingApproval => 'Awaiting approval...';

  @override
  String get contract => 'Contract';

  @override
  String paidOn(Object date) {
    return 'Paid on $date';
  }

  @override
  String get cannotInviteSelf => 'You cannot invite yourself as a tenant.';

  @override
  String get paywallTitle => 'Stanomer Premium';

  @override
  String get paywallSubtitle => 'Remove limits in property management.';

  @override
  String get unlimitedProperties =>
      'Unlimited property addition and management';

  @override
  String get detailedReporting => 'Faster and more detailed reporting';

  @override
  String get extraStorage => 'More storage space';

  @override
  String get pdfContracts => 'PDF contract generation (Coming Soon)';

  @override
  String get automatedRenewal =>
      'Automated rent calculation and renewal (Coming Soon)';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get limitReachedTitle => 'You\'ve reached your free limit';

  @override
  String get limitReachedSubtitle =>
      'Upgrade to Stanomer Premium to manage multiple properties.';

  @override
  String get optionsLoadFailed => 'Could not load subscription options.';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get premiumMobileOnly => 'Mobile App Required';

  @override
  String get premiumMobileOnlyDesc =>
      'Stanomer Premium subscriptions can only be purchased through the mobile app. Download the app below to get started with Premium.';

  @override
  String get downloadOnAppStore => 'Download on the App Store';

  @override
  String get downloadOnPlayStore => 'Get it on Google Play';

  @override
  String get premiumFeatures => 'Premium Features';

  @override
  String get premiumFeature1 => 'Unlimited property management';

  @override
  String get premiumFeature2 => 'Advanced financial reporting';

  @override
  String get premiumFeature3 => 'Priority support';

  @override
  String get premiumFeature4 => 'Access across all platforms';

  @override
  String get termsOfService => 'Terms of Service & EULA';

  @override
  String get termsOfServiceContent =>
      'Stanomer – End User License Agreement (EULA) & Terms of Service\nLast Updated: April 23, 2026\n\n1. Introduction\nThis End User License Agreement (\"Agreement\") is a legal agreement between you (\"User\") and Stanomer (\"we,\" \"us,\" or \"our\"). By installing or using the Stanomer mobile application (\"App\"), you agree to be bound by the terms of this Agreement.\n\n2. Apple and Google Terms\nApple App Store: This Agreement is concluded between the User and Stanomer only, and not with Apple Inc. This agreement incorporates Apple’s Standard Licensed Application End User License Agreement (Standard EULA) by reference: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/\n\nGoogle Play Store: This Agreement is concluded between the User and Stanomer only, and not with Google LLC.\n\nYou acknowledge that Apple and Google have no obligation whatsoever to furnish any maintenance and support services with respect to the App.\n\n3. Subscription and Billing (Auto-Renewable Subscriptions)\nStanomer offers premium features via auto-renewable subscriptions.\n\nPayment: Payment will be charged to your iTunes Account (Apple) or Google Play Account at confirmation of purchase.\n\nRenewal: Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period.\n\nManagement: You can manage or turn off auto-renew in your Account Settings (App Store or Play Store) after purchase.\n\n4. User Content & Conduct\nYou are responsible for the data you enter (rental amounts, damage reports, contracts).\n\nYou may not upload illegal, offensive, or infringing content.\n\nStanomer reserves the right to remove any content that violates Serbian laws or these terms.\n\n5. Privacy and Global Data Protection (ZZPL, GDPR, KVKK Compliance)\nYour use of the App is governed by our Privacy Policy. We are committed to protecting your personal data in compliance with:\n\nSerbian Law (ZZPL): Zakon o zaštiti podataka o ličnosti.\n\nGDPR: General Data Protection Regulation (EU).\n\nKVKK: Personal Data Protection Law (Turkey).\n\nOther International Standards: We adhere to global data privacy principles to ensure your information is handled securely regardless of your location.\n\n6. Limitation of Liability\nStanomer provides a platform for rental management and is not a party to the actual rental agreements between landlords and tenants. We are not liable for disputes arising between users or for financial transactions conducted outside the platform.\n\n7. Termination\nThis Agreement is effective until terminated by you or Stanomer. Your rights under this license will terminate automatically if you fail to comply with any of its terms.';

  @override
  String get support_title => 'Support';

  @override
  String get support_desc => 'Contact us for technical support or feedback.';

  @override
  String get subject => 'Subject';

  @override
  String get category => 'Category';

  @override
  String get message => 'Message';

  @override
  String get support => 'Support';

  @override
  String get bug => 'Bug';

  @override
  String get other => 'Other';

  @override
  String get messageSent => 'Message sent successfully!';

  @override
  String get errorSendingMessage => 'Failed to send message. Please try again.';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get offlineMessage =>
      'You are currently offline. You can continue with existing data. It will be updated when connected.';

  @override
  String get retry => 'RETRY';

  @override
  String get zzplConsentTitle => 'Personal Data Protection Consent';

  @override
  String get zzplAgreeAndContinue => 'I Read and Approve';

  @override
  String get share => 'Share';

  @override
  String get optional => 'Optional';

  @override
  String get sentInvitation => 'Sent Invitation';

  @override
  String invitedOn(String date) {
    return 'Invited on $date';
  }

  @override
  String get noEmailProvided => 'No email provided';

  @override
  String get invoiceLocalOnlyDesc =>
      'Document is stored only on this device. You can enable cloud upload in settings.';

  @override
  String get invoiceCloudSecureDesc =>
      'Document is securely stored with encryption. Only you and the tenant can see it.';

  @override
  String get invoiceUploadLimitDesc => 'JPEG, PNG or PDF · max 10 MB';

  @override
  String get billMissingLocalDesc =>
      'This bill was saved locally on another device. You cannot view it here since cloud upload is disabled.';

  @override
  String get documentMissingLocalDesc =>
      'This document was saved locally on another device. You cannot view it here since cloud upload is disabled.';

  @override
  String get cannotOpenDocument => 'Cannot Open Document';

  @override
  String get agencyAccount => 'Agency Account';

  @override
  String get managedProperties => 'Managed Properties';

  @override
  String get paymentApprovalQueue => 'Payment Approval Queue';

  @override
  String get noPendingPaymentApprovals => 'No pending payment approvals';

  @override
  String get noManagedPropertiesYet => 'No managed properties yet';

  @override
  String get occupied => 'Occupied';

  @override
  String dueDateShort(String date) {
    return 'Due: $date';
  }

  @override
  String get payment => 'Payment';

  @override
  String get insightPendingApprovalsTitle => 'Pending Approvals';

  @override
  String get insightPendingApprovalsDesc =>
      'You have properties where the landlord or tenants have not yet approved the invitation.';

  @override
  String get insightPendingApprovalsAction => 'View Related Properties';

  @override
  String get insightWithoutContractsTitle => 'Properties Without Contracts';

  @override
  String get insightWithoutContractsDesc =>
      'You have properties registered in the system but no contracts have been attached yet.';

  @override
  String get insightWithoutContractsAction => 'View Related Properties';

  @override
  String get insightExpiredContractsTitle => 'Expired Contracts';

  @override
  String get insightExpiredContractsDesc =>
      'You have properties with expired and unrenewed contracts. Please take action.';

  @override
  String get insightExpiredContractsAction => 'View Related Properties';

  @override
  String get insightExpiringContractsTitle => 'Expiring Contracts';

  @override
  String get insightExpiringContractsDesc =>
      'You have properties with less than one month remaining on their latest active contract.';

  @override
  String get insightExpiringContractsAction => 'View Related Properties';

  @override
  String get tabHome => 'Home';

  @override
  String get tabFinance => 'Finance';

  @override
  String get tabRequests => 'Requests';

  @override
  String get tabPortfolio => 'Portfolio';

  @override
  String get agencyAddProperty => 'Add Property';

  @override
  String get searchAndFilterPanel => 'Search & Detailed Filters';

  @override
  String get searchPlaceholder =>
      'Search landlord, tenant, city or property...';

  @override
  String filterAppliedLabel(String title) {
    return 'Filter Applied: $title';
  }

  @override
  String get noPropertiesMatchingFilter =>
      'No properties match the selected filter';

  @override
  String get groupNone => 'No Grouping';

  @override
  String get groupByLandlord => 'Group: Landlord';

  @override
  String get groupByCity => 'Group: City';

  @override
  String get groupByStatus => 'Group: Status';

  @override
  String get groupByDebtConsent => 'Group: Debt / Approval';

  @override
  String get sortByNewest => 'Sort: Newest';

  @override
  String get sortByOldest => 'Sort: Oldest';

  @override
  String get sortByDebt => 'Sort: Debtors First';

  @override
  String get sortByRentDesc => 'Sort: Rent (High-Low)';

  @override
  String get sortByRentAsc => 'Sort: Rent (Low-High)';

  @override
  String get sortByAmountDesc => 'Sort: Amount (High-Low)';

  @override
  String get sortByAmountAsc => 'Sort: Amount (Low-High)';

  @override
  String get sortByNameAsc => 'Sort: Property A-Z';

  @override
  String get sortByCityAsc => 'Sort: City A-Z';

  @override
  String get sortByLandlordAsc => 'Sort: Landlord A-Z';

  @override
  String get viewModeTable => 'Table View';

  @override
  String get viewModeGrid => 'Grid View';

  @override
  String get statusLabel => 'STATUS';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusClean => 'Clean';

  @override
  String get colPropertyAndType => 'PROPERTY & TYPE';

  @override
  String get colDueDate => 'DUE DATE';

  @override
  String get colAmount => 'AMOUNT';

  @override
  String get colAction => 'ACTION';

  @override
  String get unenteredBillsTitle => 'Unentered Bills';

  @override
  String get cashBadge => 'Cash';

  @override
  String get filterRent => 'Rent';

  @override
  String get filterBills => 'Bills';

  @override
  String get filterDeposit => 'Deposit';

  @override
  String get filterDues => 'Building Dues';

  @override
  String get allPropertiesGroup => 'All Properties';

  @override
  String get groupLandlordPendingInvite => 'Landlords Pending Invite';

  @override
  String get groupUnspecifiedCity => 'Unspecified City';

  @override
  String get groupStatusOccupied => 'Occupied Properties';

  @override
  String get groupStatusVacant => 'Vacant Properties';

  @override
  String get groupStatusLandlordPending => 'Landlord Invite Pending';

  @override
  String get groupDebtPending => 'Properties with Outstanding Debt';

  @override
  String get groupConsentPending => 'Consent / Approval Pending';

  @override
  String get groupActiveClean => 'Clean / Debt-Free Properties';

  @override
  String filterAllCount(int count) {
    return 'All ($count)';
  }

  @override
  String filterHasDebtCount(int count) {
    return '⚠️ Has Debt ($count)';
  }

  @override
  String filterOccupiedCount(int count) {
    return '🟢 Occupied ($count)';
  }

  @override
  String filterVacantCount(int count) {
    return '🟡 Vacant ($count)';
  }

  @override
  String get filterActiveLabel => 'Filter Active ✓';

  @override
  String get financeAndPaymentsHeader => 'Finance & Payments';

  @override
  String get financialSummaryTitle => 'Financial Summary';

  @override
  String pendingPaymentsSummary(int count) {
    return '$count pending payment approvals';
  }

  @override
  String get financePlaceholderDesc =>
      'Financial charts, rent tracking and payment history will be listed here soon.';

  @override
  String get maintenanceRequestsHeader => 'Maintenance & Repairs';

  @override
  String get requestManagementTitle => 'Request Management';

  @override
  String get requestsPlaceholderDesc =>
      'Maintenance and support requests from tenants and landlords will soon be managed from this tab.';

  @override
  String get noOpenRequestsYet => 'No open requests yet';

  @override
  String get actionableInsightsHeader => 'Actionable Insights';

  @override
  String get inviteTenantOrAddContract => 'Invite Tenant / Add Contract';

  @override
  String get ownershipQrOrLink => 'Ownership QR / Link';

  @override
  String get changeLandlord => 'Change Landlord';

  @override
  String get pendingDebtWarning =>
      'Pending Debt Awaiting Agency Approval or Tenant Payment';

  @override
  String get landlordLabel => 'Landlord: ';

  @override
  String get invitePending => 'Invite Pending';

  @override
  String get tenantLabel => 'Tenant: ';

  @override
  String get vacantLabel => 'Vacant';

  @override
  String get latestContractNone => 'Latest Contract: None';

  @override
  String get unlimited => 'Unlimited';

  @override
  String contractDateRange(String dates) {
    return 'Contract: $dates';
  }

  @override
  String get cashPayment => 'Cash Payment';

  @override
  String get changeLandlordDialogTitle => 'Change Landlord / Send Invite';

  @override
  String get changeLandlordDialogDesc =>
      'Enter the new landlord contact info. Existing ownership will be reset and a new QR/Link generated.';

  @override
  String get phone => 'Phone Number';

  @override
  String get error => 'Error';

  @override
  String get changeAndGenerateQr => 'Change & Generate QR';

  @override
  String get financePendingApprovals => 'Pending Approvals';

  @override
  String get financeOverduePayments => 'Overdue Payments';

  @override
  String get financePaidThisMonth => 'Paid This Month';

  @override
  String get financeRentCollected => 'Rent Collected from Tenants';

  @override
  String get financeBillsCollected => 'Bills Collected from Tenants';

  @override
  String get financeBillsToInstitutions => 'Bills Paid to Institutions';

  @override
  String get financeBillsToInstitutionsTooltip =>
      'Bills collected from tenants are assumed to have been paid to the institutions.';

  @override
  String get financeMaintenancePaid => 'Maintenance Costs Paid';

  @override
  String get financeMaintenanceOwedToAgency => 'Maintenance Owed to Agency';

  @override
  String get financeMaintenanceOwedToAgencyTooltip =>
      'Bills collected from tenants are assumed to have been paid to the agency.';

  @override
  String get periodThisMonth => 'This Month';

  @override
  String get periodLastMonth => 'Last Month';

  @override
  String get periodThisYear => 'This Year';

  @override
  String get periodLastYear => 'Last Year';

  @override
  String get periodAllTime => 'All Time';

  @override
  String get periodCustom => 'Custom';

  @override
  String get financeUpcoming7Days => 'Upcoming (7 Days)';

  @override
  String get tabPendingQueue => 'Approval Queue';

  @override
  String get tabOverdueList => 'Overdue Debtors';

  @override
  String get tabAllHistory => 'Payment History';

  @override
  String get approvePayment => 'Approve';

  @override
  String get rejectPayment => 'Reject';

  @override
  String get markAsCashPaid => 'Mark as Cash Paid';

  @override
  String get sendReminder => 'Send Reminder';

  @override
  String daysOverdue(int count) {
    return '$count days overdue';
  }

  @override
  String get noFinanceRecords => 'No records found in this category';

  @override
  String get reminderMessageCopied => 'Reminder message copied';

  @override
  String get tenantNoPropertyTitle =>
      'You are not yet connected to a property.';

  @override
  String get tenantNoPropertyTooltip =>
      'You are not yet connected to a property.';

  @override
  String get tenantNoPropertyMaintenanceTooltip =>
      'You are not yet connected to a property.\nYou need to join a property first to create a maintenance request.';

  @override
  String get joinWithQrCode => 'Join Home with QR / Invite Code';

  @override
  String get agencyPropertyTakeoverQr => 'Take Over Agency\'s Property via QR';

  @override
  String welcomeUser(String userName) {
    return 'Welcome, $userName 👋';
  }

  @override
  String overduePaymentReminderMessage(
    String tenantName,
    String propertyName,
    String amount,
    String currency,
  ) {
    return 'Dear $tenantName, your payment of $amount $currency for $propertyName property is overdue. Please make the payment and upload your receipt.';
  }

  @override
  String get heroHeadline =>
      'Manage your rental properties from a single panel';

  @override
  String get heroSubtitle =>
      'Tenant tracking, payment records, and property details — all in one place.';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get copy => 'Copy';

  @override
  String get showLandlordInviteQrOrLink =>
      'Show Ownership QR Code / Invitation Link';

  @override
  String get showLandlordInviteQrOrLinkClaimed =>
      'Ownership QR Code / Invitation Link';

  @override
  String get landlordOwnershipInviteTitle => 'Landlord Ownership Invitation';

  @override
  String becomeLandlordTitle(String propertyName) {
    return 'Become the Landlord of $propertyName';
  }

  @override
  String get landlordInviteAcceptDesc =>
      'Approve the invitation to be assigned as and manage the landlord of this property managed by the agency.';

  @override
  String get acceptAsLandlord => 'Accept as Landlord';

  @override
  String get landlordAcceptedInviteTitle => 'Landlord Accepted the Invitation!';

  @override
  String landlordOwnershipTransferredDesc(String propertyName) {
    return 'Ownership of $propertyName has been successfully transferred.';
  }

  @override
  String get landlordShareQrInstruction =>
      'Have the landlord scan this QR code or send them the link.';

  @override
  String get ownershipLinkCopied => 'Ownership link copied!';

  @override
  String landlordShareMessage(
    String landlordName,
    String propertyName,
    String inviteUrl,
  ) {
    return 'Hello $landlordName, click this link to take over ownership of \"$propertyName\" on Stanomer:\n$inviteUrl';
  }

  @override
  String get joinHomeTitle => 'Join Home';

  @override
  String get joinHomeSubtitle =>
      'Scan the QR code or enter the invite link/code.';

  @override
  String get closeCamera => 'Close Camera';

  @override
  String get scanQrCodeBtn => 'Scan QR Code';

  @override
  String get inviteLinkOrTokenLabel => 'Invite Link or Token Code';

  @override
  String get inviteLinkOrTokenHint => 'https://.../invite?token=... or code';

  @override
  String get paste => 'Paste';

  @override
  String get joinAndReview => 'Join and Review';

  @override
  String get invalidInviteCodeOrLink =>
      'Please enter a valid invite link or invite code.';

  @override
  String get landlordOwnershipTransferredSuccess =>
      'Congratulations! Property ownership successfully transferred to your account.';

  @override
  String get landlordOwnershipInviteInvalid =>
      'Ownership invite is invalid, expired or already accepted.';

  @override
  String get statusApproved => 'Confirmed';

  @override
  String get referringAgency => 'Referring Agency';

  @override
  String get noReferringAgency => 'No Referring Agency';

  @override
  String get noReferringAgencyDesc =>
      'If you were referred by a real estate agency, scan your agency\'s QR code to link your account.';

  @override
  String get scanAgencyReferralQrBtn => 'Scan Agency Referral QR Code';

  @override
  String get referralCodeLabel => 'Referral Code';

  @override
  String get detailedEntry => 'Advanced Info';

  @override
  String get detailedEntrySubtitle =>
      'All property specifications, structural metrics and details.';

  @override
  String get propertyAndLocationInfo => 'Property & Location Information';

  @override
  String get propertyTypeLabel => 'Property Type';

  @override
  String get propertyTypeApartment => 'Apartment';

  @override
  String get propertyTypeHouse => 'House';

  @override
  String get propertyTypeCommercial => 'Commercial';

  @override
  String get propertyTypeGarage => 'Garage';

  @override
  String get unitNumberLabel => 'Unit / Flat No';

  @override
  String get unitNumberHint => 'e.g. 4 or 12B';

  @override
  String get addressDetailedHint =>
      'Enter city, district, neighborhood or street...';

  @override
  String get structuralAndFinancialMetrics => 'Structural & Financial Metrics';

  @override
  String get roomCountLabel => 'Room Count';

  @override
  String get areaSqmLabel => 'Area';

  @override
  String get floorLevelLabel => 'Floor Level';

  @override
  String get totalFloorsLabel => 'Total Building Floors';

  @override
  String get equipmentAndHeatingStandards => 'Equipment & Heating Standards';

  @override
  String get furnishingLabel => 'Furnishing Status';

  @override
  String get furnishingFurnished => 'Furnished';

  @override
  String get furnishingFurnishedDesc => 'Fully Furnished';

  @override
  String get furnishingSemi => 'Semi-Furnished';

  @override
  String get furnishingSemiDesc => 'Kitchen/Bathroom only';

  @override
  String get furnishingUnfurnished => 'Unfurnished';

  @override
  String get furnishingUnfurnishedDesc => 'Unfurnished';

  @override
  String get heatingTypeLabel => 'Heating Type';

  @override
  String get heatingCg => 'District / Central Heating';

  @override
  String get heatingEg => 'Individual Electric Heating';

  @override
  String get heatingGas => 'Natural Gas';

  @override
  String get heatingUnderfloor => 'Underfloor Heating';

  @override
  String get heatingTa => 'Storage Heater / AC / Other';

  @override
  String get featuredAmenitiesLabel => 'Featured Amenities';

  @override
  String get amenityPets => 'Pet Friendly';

  @override
  String get amenityElevator => 'Elevator';

  @override
  String get amenityBalcony => 'Balcony / Terrace';

  @override
  String get amenityParking => 'Garage / Parking Space';

  @override
  String get amenityStorage => 'Storage / Basement';

  @override
  String get extendedDescriptionLabel => 'Extended Description';

  @override
  String get extendedDescriptionHint =>
      'Enter info on transport, building age, layout and special conditions...';

  @override
  String get clearFormBtn => 'Clear Form';

  @override
  String get floorSuteren => 'Semi-Basement';

  @override
  String get floorPrizemlje => 'Ground Floor';

  @override
  String get floorVisokoPrizemlje => 'Raised Ground Floor';

  @override
  String floorNth(String floor) {
    return 'Floor $floor';
  }

  @override
  String get floorPotkrovlje => 'Attic / Top Floor';

  @override
  String get floorOther => 'Other';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInProgress => 'Technician Sent';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get financialDetails => 'Financial Details';

  @override
  String get financialStatusPendingReview => 'Pending Review';

  @override
  String get financialStatusPendingAgencyApproval => 'Awaiting Agency Approval';

  @override
  String get financialStatusPendingOppositeApproval =>
      'Awaiting Settlement Approval';

  @override
  String get financialStatusPendingPayment => 'Pending Payment';

  @override
  String get financialStatusPaid => 'Paid';

  @override
  String get financialStatusRejected => 'Rejected';

  @override
  String get rejectionReasonRequired => 'Please enter a rejection reason';

  @override
  String get payerTenant => 'Tenant';

  @override
  String get payerLandlord => 'Landlord';

  @override
  String get payerTenantPaidOrWillPay => 'Tenant Paid / To Pay';

  @override
  String get payerLandlordWillCover => 'Landlord to Cover';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get noFinancialRecordTitle => 'No Financial Record';

  @override
  String get noFinancialRecordDesc =>
      'No cost or receipt document has been entered for this maintenance request.';

  @override
  String get iPaidSubmitReceipt => 'I Paid (Submit Receipt)';

  @override
  String get resubmitExpenseIPaid => 'Resubmit Expense (I Paid)';

  @override
  String get addCostInvoice => 'Add Cost / Invoice';

  @override
  String get costPayerLabel => 'Cost Payer';

  @override
  String get receiptInvoiceDocument => 'Receipt / Invoice Document';

  @override
  String get clickToViewDocument => 'Click to view document';

  @override
  String get agencyExpenseApproval => 'Agency Approval';

  @override
  String get landlordExpenseApproval => 'Landlord Approval';

  @override
  String get tenantExpenseApproval => 'Tenant Approval';

  @override
  String get expenseApprovedSuccess => 'Expense approved successfully.';

  @override
  String get expenseRejectedSuccess => 'Expense declaration rejected.';

  @override
  String get rejectExpenseTitle => 'Reject Expense';

  @override
  String get rejectExpenseConfirm =>
      'Are you sure you want to reject this expense declaration?';

  @override
  String get rejectionReasonOptional => 'Reason (optional)';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get descriptionOrNoteOptional => 'Description / Note (Optional)';

  @override
  String get enterExpenseNoteHint =>
      'e.g. Replaced leaking valve, technician fee included';

  @override
  String get editFinancialDetails => 'Edit Financial Details';

  @override
  String get propertyInfo => 'Property Info';

  @override
  String get coveredByLandlord => 'Covered by Landlord';

  @override
  String get coveredByTenant => 'Covered by Tenant';

  @override
  String get landlordReimbursement => 'Landlord Reimbursement';

  @override
  String get tenantToPay => 'Tenant to Pay';

  @override
  String get landlordReimburseDesc =>
      'Tenant paid in advance. Landlord will reimburse or deduct from next rent.';

  @override
  String get tenantToPayDesc =>
      'Assigned to tenant. Amount will be collected with next rent.';

  @override
  String get coveredByLandlordClosedDesc =>
      'Covered as property fixture and closed.';

  @override
  String get coveredByTenantClosedDesc =>
      'Covered as usage expense and closed.';

  @override
  String get reEditFinancials => 'Re-edit Financials';

  @override
  String get expenseRejectedDesc =>
      'Previously submitted expense was rejected. You can resubmit with corrected amount and receipt.';

  @override
  String get agencyManager => 'Agency Manager';

  @override
  String actorStatusInvestigating(String actor) {
    return '🔍 $actor marked the request as under investigation.';
  }

  @override
  String actorStatusInProgress(String actor) {
    return '🔧 $actor dispatched a technician, work is in progress.';
  }

  @override
  String actorStatusResolved(String actor) {
    return '✅ $actor marked the issue as resolved.';
  }

  @override
  String actorStatusClosed(String actor) {
    return '🔒 $actor closed the request.';
  }

  @override
  String actorStatusReopened(String actor) {
    return '🔄 $actor reopened the request. Issue persists.';
  }

  @override
  String actorMarkedActive(String actor) {
    return '📋 $actor set the request status to active.';
  }

  @override
  String actorUpdatedStatus(String actor, String status) {
    return '📌 $actor updated the status: $status';
  }

  @override
  String get submitExpenseReview => 'Submit Expense (Send for Review)';

  @override
  String get pleaseEnterValidCost => 'Please enter the valid amount paid.';

  @override
  String get pleaseUploadReceipt =>
      'Please upload a receipt or invoice document.';

  @override
  String get pleaseSelectCostPayer => 'Please select who pays.';

  @override
  String get noteLabel => 'Note';

  @override
  String get amountPaid => 'Amount Paid';

  @override
  String get costAmount => 'Cost Amount';

  @override
  String get costResponsibility => 'Who Paid the Cost?';

  @override
  String get whoPaidTheCost => 'Who Paid the Cost?';

  @override
  String get paymentInvoiceStatus => 'Payment & Invoice Status';

  @override
  String get paymentDueDate => 'Payment / Due Date';

  @override
  String get noDate => 'No date';

  @override
  String get uploadReceiptInvoice => 'Upload Receipt / Invoice (PDF, Image)';

  @override
  String get uploadInvoiceDoc => 'Upload Invoice Document';

  @override
  String get existingDocument => 'Existing Document';

  @override
  String get change => 'Change';

  @override
  String get enterAmountAttachReceipt =>
      'Enter amount paid and attach receipt.';

  @override
  String declaredAmountTitle(String amount) {
    return 'Declared Amount: $amount • Please select who paid the cost:';
  }

  @override
  String get expenseApprovalResponsibility =>
      'Expense Approval & Responsibility';

  @override
  String get landlordCoveredPaidTitle => 'Landlord Covered (Mark as Paid)';

  @override
  String get landlordCoveredPaidSub =>
      'Expense belongs to landlord. No reimbursement needed, closed as paid.';

  @override
  String get landlordCoveredPaidBadge => 'Paid • Landlord';

  @override
  String get tenantWillPayTitle => 'Tenant Will Pay (Add to Rent)';

  @override
  String get tenantWillPaySub =>
      'Damage/cost caused by tenant usage. Added to rent as due payment.';

  @override
  String get tenantWillPayBadge => 'Pending Payment • Tenant Due';

  @override
  String get tenantPaidMarkAsPaidTitle => 'Tenant Paid (Mark as Paid)';

  @override
  String get tenantPaidMarkAsPaidSub =>
      'Expense caused by tenant usage. Marked as paid by tenant with no reimbursement.';

  @override
  String get tenantPaidMarkAsPaidBadge => 'Paid • Tenant Usage';

  @override
  String get landlordReimbursesTitle =>
      'Landlord Reimburses (Deduct from Rent)';

  @override
  String get landlordReimbursesSub =>
      'Property fixture expense paid in advance by tenant. Landlord reimburses or deducts from rent.';

  @override
  String get landlordReimbursesBadge => 'Pending Payment • Rent Deduction';

  @override
  String get propertyManagedByAgencyNotice =>
      'Property is managed by an agency. Only the agency can edit financial details.';

  @override
  String agencyExpenseApprovedMsg(String amount, String actor, String details) {
    return '✅ Expense approved: $amount (Approved by $actor • $details)';
  }

  @override
  String agencyExpenseRejectedMsg(String actor) {
    return '❌ Expense declaration rejected by $actor';
  }

  @override
  String reasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get roleYou => 'You';

  @override
  String get roleUser => 'User';

  @override
  String landlordDeclaredExpenseSubtitle(String amount) {
    return 'Landlord declared $amount expense. You can approve or reject.';
  }

  @override
  String tenantDeclaredExpenseSubtitle(String amount) {
    return 'Tenant declared $amount expense. You can approve or reject.';
  }

  @override
  String get expenseSubmittedForLandlordReview =>
      'Your submitted expense is waiting for landlord review.';

  @override
  String get expenseSubmittedForTenantReview =>
      'Your submitted expense is waiting for tenant review.';

  @override
  String get tblRequestProperty => 'Request & Property';

  @override
  String get tblPriority => 'Priority';

  @override
  String get tblIssueStatus => 'Issue Status';

  @override
  String get tblCostPayer => 'Cost & Payer';

  @override
  String get tblFinancialStatus => 'Financial Status';

  @override
  String get tblDate => 'Date';

  @override
  String get dueDatePrefix => 'Due';

  @override
  String get edit => 'Edit';

  @override
  String get update => 'Update';

  @override
  String get paymentDate => 'Payment Date';

  @override
  String get profileUpdated => 'Saved successfully.';

  @override
  String get agencyPropertyTakeoverTitle =>
      'Take Over Property Added by Agency';

  @override
  String get agencyPropertyTakeoverDesc =>
      'Add the property entered by the agency to your account by scanning a QR code or entering an invite code.';

  @override
  String get scanQrOrEnterInviteCodeBtn => 'Scan QR Code / Enter Invite Code';

  @override
  String get settlementIntentTitle => 'Payment Purpose & Settlement Request';

  @override
  String get intentTenantSelfTitle =>
      'Tenant Paid for Own Usage (Tenant Usage Damage)';

  @override
  String get intentTenantSelfSub =>
      'Amount stays with the tenant. No rent deduction requested, closed as paid.';

  @override
  String get intentTenantSelfBadge => 'Paid • Tenant Cost';

  @override
  String get intentTenantReimburseTitle =>
      'Tenant Paid for Property Fixture (To be Covered by Landlord)';

  @override
  String get intentTenantReimburseSub =>
      'Tenant paid fixture repair in advance. Requests deduction from next rent or reimbursement.';

  @override
  String get intentTenantReimburseBadge => 'Deduct from Rent';

  @override
  String get intentLandlordSelfTitle =>
      'Landlord Paid for Property Fixture (Landlord\'s Expense)';

  @override
  String get intentLandlordSelfSub =>
      'Fixture cost covered by landlord. Not charged to tenant, closed as paid.';

  @override
  String get intentLandlordSelfBadge => 'Paid • Landlord';

  @override
  String get intentLandlordTenantDueTitle =>
      'Landlord Paid for Tenant Usage / Damage (Charge to Tenant)';

  @override
  String get intentLandlordTenantDueSub =>
      'Damage caused by tenant usage. Amount requested to be added to tenant\'s next rent.';

  @override
  String get intentLandlordTenantDueBadge => 'Add to Rent';

  @override
  String get pleaseSelectDeclarationIntent =>
      'Please select the purpose of payment and settlement request.';

  @override
  String get confirmTenantReimburseApprovalTitle => 'Offset Approval';

  @override
  String confirmTenantReimburseApprovalMsg(String amount) {
    return 'Do you confirm that the tenant can deduct this $amount fixture expense from rent payments?';
  }

  @override
  String get confirmTenantSelfApprovalTitle => 'Usage Expense Confirmation';

  @override
  String confirmTenantSelfApprovalMsg(String amount) {
    return 'Do you confirm that the tenant covered their $amount usage expense and to close the request as paid without reimbursement?';
  }

  @override
  String get confirmLandlordSelfApprovalTitle =>
      'Landlord Fixture Confirmation';

  @override
  String confirmLandlordSelfApprovalMsg(String amount) {
    return 'Do you confirm that the landlord directly covered the $amount fixture expense and to close the request as paid?';
  }

  @override
  String get confirmLandlordTenantDueApprovalTitle => 'Debt Approval';

  @override
  String confirmLandlordTenantDueApprovalMsg(String amount) {
    return 'Do you confirm that this $amount expense was caused by your usage and will be paid to the landlord?';
  }

  @override
  String get acceptDebtBtn => 'Accept Debt';

  @override
  String get approveOffsetBtn => 'Approve Offset';

  @override
  String get acceptDebtNote =>
      'When accepted, this amount will be added to your pending debts in the payment plan.';

  @override
  String get approveOffsetNote =>
      'When approved, this amount is credited to tenant\'s offset balance and can be deducted from upcoming rent.';

  @override
  String declaredIntentLabel(String intent) {
    return 'Settlement Request: $intent';
  }

  @override
  String get maintenanceSettlementsHeader => 'Maintenance & Repair Settlements';

  @override
  String get maintenanceSettlementsSub =>
      'Approved maintenance expenses to be deducted from or added to rent';

  @override
  String get deductFromRentBadge => 'Deduct from Rent';

  @override
  String get addToRentBadge => 'Add to Rent';

  @override
  String get markAsSettledBtn => 'Mark as Settled / Paid';

  @override
  String get confirmSettlementTitle => 'Close Settlement';

  @override
  String confirmSettlementMsg(String amount) {
    return 'Do you confirm that the maintenance expense of $amount has been settled/paid and should be closed?';
  }

  @override
  String get settlementRecordedSuccess =>
      'Maintenance settlement closed successfully.';

  @override
  String get goToMaintenanceRequest => 'View Request';

  @override
  String maintenanceSettlementActivityMsg(String amount, String role) {
    return '💰 Maintenance expense ($amount) marked as settled/paid by $role.';
  }

  @override
  String get settleExpenseTitle => 'Maintenance Expense Settlement';

  @override
  String get settleExpenseSub => 'Choose payment or deduction method';

  @override
  String get optionOffsetFromRent => 'Deduct / Offset from Debt';

  @override
  String get optionOffsetFromRentDesc =>
      'Automatically deduct this amount from pending rent, bills, or maintenance debts in the same currency';

  @override
  String get optionBankTransfer => 'Pay via Bank Transfer';

  @override
  String get optionBankTransferDesc =>
      'Upload payment receipt and send for confirmation';

  @override
  String get optionCashPayment => 'Pay in Cash';

  @override
  String get optionCashPaymentDesc => 'Declare as handed over in cash';

  @override
  String get selectRentToOffset => 'Select Item to Offset';

  @override
  String noEligiblePendingPayments(String currency) {
    return 'No eligible pending rent, bills, or maintenance debts found to offset ($currency).';
  }

  @override
  String offsetAppliedSuccess(String amount, String paymentTitle) {
    return '$amount was successfully offset from $paymentTitle.';
  }

  @override
  String get confirmReceiptBtn => 'I Received Payment / Confirm';

  @override
  String get waitingForRecipientApproval =>
      'Waiting for recipient\'s confirmation';

  @override
  String get iPaidBtn => 'I Paid / Upload Receipt';

  @override
  String get iPaidCashBtn => 'I Paid in Cash';

  @override
  String maintenanceCashPaidActivityMsg(String role, String amount) {
    return '💵 $role declared paying $amount maintenance expense in cash. Awaiting confirmation.';
  }

  @override
  String maintenanceBankPaidActivityMsg(String role, String amount) {
    return '📄 $role declared paying $amount maintenance expense via bank transfer (Receipt attached). Awaiting confirmation.';
  }

  @override
  String maintenanceOffsetActivityMsg(String amount, String paymentTitle) {
    return '🏠 $amount maintenance expense was offset from $paymentTitle.';
  }

  @override
  String agencyReferralBoundSuccess(String agencyName) {
    return 'Agency referral linked: $agencyName';
  }

  @override
  String get invalidAgencyReferralCode =>
      'Invalid or not found agency referral code.';

  @override
  String get occupancyRate => 'Occupancy';

  @override
  String get allPropertiesUpToDate =>
      'All properties and payments are up to date. No pending approvals.';

  @override
  String overduePaymentsAlert(int count) {
    return 'There are $count overdue payment(s). Check the property list for details.';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterRented => 'Rented';

  @override
  String get filterVacant => 'Vacant';

  @override
  String get noPropertiesForFilter => 'No properties found for this filter.';

  @override
  String get attentionTag => 'ATTENTION';

  @override
  String get reviewAction => 'Review';

  @override
  String get detailsAction => 'Details';

  @override
  String get noActiveContractTapToInvite =>
      'No active contract. Tap to invite tenant.';

  @override
  String get activeTenantsCount => 'Active Tenants';

  @override
  String get totalPropertiesCount => 'Total Properties';

  @override
  String get collectedRentSubtitle => 'Collected Rent';

  @override
  String get awaitingApprovalSubtitle => 'Receipt Approval';

  @override
  String get overduePaymentsSubtitle => 'Overdue';

  @override
  String get vacantUnitsSubtitle => 'Available for Rent';

  @override
  String get portfolioRateSubtitle => 'Portfolio Rate';

  @override
  String get rentedStatusTag => 'Rented';

  @override
  String get invitedStatusTag => 'Invited';

  @override
  String get settlementCredit => 'Settlement Credit';

  @override
  String get noDebtLabel => 'No Debt';

  @override
  String daysLeftBadge(int count) {
    return '$count days left';
  }

  @override
  String get dueTodayBadge => 'Due today';

  @override
  String get overdueBadge => 'Overdue';

  @override
  String allTenantPaymentsUpToDate(String date) {
    return 'All your payments are up to date. Next rent due on $date.';
  }

  @override
  String tenantAwaitingReceiptApprovalMsg(int count) {
    return 'Receipt uploaded for $count payment(s), awaiting approval.';
  }

  @override
  String tenantOutstandingDebtMsg(int count) {
    return 'You have $count outstanding payment(s).';
  }

  @override
  String get quickActionFinance => 'Rent & Bills';

  @override
  String get quickActionMaintenance => 'Maintenance';

  @override
  String get quickActionContract => 'Contract';

  @override
  String get quickActionHistory => 'Payment History';

  @override
  String get monthlyBaseRent => 'Monthly Rent';

  @override
  String get payNowAction => 'Pay Now';

  @override
  String get depositSecuredLabel => 'Deposit Secured';

  @override
  String get maintenanceTitle => 'Maintenance & Repair Requests';

  @override
  String get maintenanceSubtitle =>
      'Track reported issues, technician visits and expense settlements.';

  @override
  String get filterActive => 'Active & In Progress';

  @override
  String get filterInvestigating => 'Investigating';

  @override
  String get filterUrgent => 'Urgent';

  @override
  String get filterCompleted => 'Resolved';

  @override
  String get filterCost => 'With Cost / Refund';

  @override
  String get searchMaintenancePlaceholder => 'Search requests...';

  @override
  String get statActiveIssues => 'Active / In Progress';

  @override
  String get statUrgentIssues => 'Urgent Issues';

  @override
  String get statResolvedIssues => 'Resolved';

  @override
  String get statPendingSettlement => 'Cost / Settlement';

  @override
  String get progressReported => 'Reported';

  @override
  String get progressInvestigating => 'Reviewing';

  @override
  String get progressInProgress => 'Technician';

  @override
  String get progressResolved => 'Resolved';

  @override
  String get statusInProgressTechnician => 'Technician Sent';

  @override
  String get costDeductFromRent => 'Deduct from Rent';

  @override
  String get costAddToRent => 'Add to Rent';

  @override
  String get costPaidByTenant => 'Paid by Tenant';

  @override
  String get costPaidByLandlord => 'Paid by Landlord';

  @override
  String get costPendingReview => 'Pending Review';

  @override
  String get costRejected => 'Cost Rejected';

  @override
  String get viewInvoiceAction => 'View Invoice';

  @override
  String get noMatchingIssues => 'No matching maintenance requests found';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '$count photo',
    );
    return '$_temp0';
  }

  @override
  String get viewDetailsAction => 'View Details';

  @override
  String get reportIssueSubtitle =>
      'Submit issue or maintenance details with photos for quick resolution.';

  @override
  String get issueTitleHint => 'e.g. Water leaking under the kitchen sink';

  @override
  String get issueDescriptionHint =>
      'Describe the exact location, when it started, and any details...';

  @override
  String get priorityNormalDesc => 'Standard repair and maintenance process';

  @override
  String get priorityUrgentDesc =>
      'Water flood, electrical hazard, or emergency';

  @override
  String get photosSubtitle => 'Add clear photos showing the issue (Max 5)';

  @override
  String get addPhotoFromGallery => 'Upload Photos';

  @override
  String get sendRequestBtn => 'Submit Issue Report';

  @override
  String get categorySelectorTitle => 'Issue Category';

  @override
  String get prioritySelectorTitle => 'Priority Level';

  @override
  String get financialSectionTitle => 'FINANCIAL DETAILS & INVOICE';

  @override
  String get financialSectionSubtitle =>
      'Record maintenance cost and vendor invoice (Optional).';

  @override
  String get costAmountLabel => 'Cost Amount';

  @override
  String get paidByLabel => 'Cost Responsibility';

  @override
  String get unassignedLabel => 'Unassigned';

  @override
  String get paymentStatusLabel => 'Invoice & Payment Status';

  @override
  String get pendingReviewHint => 'Under review (Not reflected on balance)';

  @override
  String get pendingPaymentHint => 'Approved • Reflected as debt/expense';

  @override
  String get paymentCompletedSubtitle => 'Payment completed';

  @override
  String get paymentRejectedSubtitle => 'Invalid / Rejected';

  @override
  String get invoicePdfLabel => 'Invoice / Receipt';

  @override
  String get uploadPdfTitle => 'Upload Invoice PDF';

  @override
  String get uploadPdfSubtitle => 'Tap to select PDF file (Max 10MB)';

  @override
  String get tenantLockedStatusNotice =>
      'Tenants cannot change payment status unless paying themselves (submitted as Pending Review).';

  @override
  String get payerRequiredError =>
      'Please select who pays before setting payment status.';

  @override
  String get tabRentAndFinance => 'Rent & Finance';

  @override
  String get tabLeaseAndTenant => 'Lease & Tenant';

  @override
  String get tabMaintenance => 'Maintenance';

  @override
  String get tabAuditLog => 'Audit Log';

  @override
  String get paymentMethodBank => 'Bank';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodLabel => 'Payment Method:';

  @override
  String get managedByAgencyTitle => 'Managed by Agency';

  @override
  String get managedByAgencyDesc =>
      'Your properties are managed by an agency. Adding new properties can only be done by your managing agency.';

  @override
  String get structuralAndFinancialMetricsSubtitle =>
      'Property type, room count, unit number & floor metrics';

  @override
  String get equipmentAndHeatingStandardsSubtitle =>
      'Furnishing status and heating infrastructure';

  @override
  String get featuredAmenitiesSubtitle =>
      'Featured amenities and extended description';

  @override
  String get roomTypeStudio => 'Studio';

  @override
  String get secondaryContacts => 'Secondary Contacts';

  @override
  String get addSecondaryContact => 'Add Contact';

  @override
  String get secondaryContactsOptionalDesc =>
      'Optional: You can add secondary contacts like an assistant, PR, or family member.';

  @override
  String get roleOrRelation => 'Role / Relationship';

  @override
  String get tenantFullName => 'Tenant Full Name';

  @override
  String get tenantIdOrPassport => 'ID / Passport / JMBG';

  @override
  String get tenantNotes => 'Tenant Notes';

  @override
  String get tenantIdDocument => 'Tenant ID Document / Passport';

  @override
  String get uploadPdfOrPhoto => 'Upload PDF or photo copy';

  @override
  String get uploadAction => 'Upload';

  @override
  String get idDocumentUploaded => 'ID document uploaded';

  @override
  String copiedId(String id) {
    return 'ID copied: $id';
  }

  @override
  String get rolePersonalAssistant => 'Personal Assistant';

  @override
  String get rolePrRep => 'PR / Representative';

  @override
  String get roleFamilyMember => 'Family Member';

  @override
  String get roleAuthorizedContact => 'Authorized Contact';

  @override
  String get clearAllAction => 'Clear All';

  @override
  String get selectAllAction => 'Select All';

  @override
  String get applyAction => 'Apply';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String selectedItemsCount(int count) {
    return '$count Selected';
  }

  @override
  String get propertyOwnerInfoTitle => 'Property Owner Information';

  @override
  String get propertyOwnerInfoSubtitle =>
      'You can add multiple co-owners, corporate or individual, and attach ownership and authorization documents.';

  @override
  String get addCoOwner => '+ Add Co-Owner';

  @override
  String get primaryOwnerLabel => '1. Owner (Primary)';

  @override
  String coOwnerIndexedLabel(int index) {
    return '$index. Co-Owner';
  }

  @override
  String get sharePercentage => 'Share %';

  @override
  String get removeOwner => 'Remove Owner';

  @override
  String get ownerType => 'Owner Type';

  @override
  String get ownerIndividual => 'Individual';

  @override
  String get ownerCompany => 'Company / Legal Entity';

  @override
  String get firstNameRequired => 'First Name *';

  @override
  String get lastNameRequired => 'Last Name *';

  @override
  String get idOrPassportOrJmbg => 'ID / Passport / JMBG No';

  @override
  String get idIssuingAuthority => 'ID Issuing Authority / Details';

  @override
  String get companyLegalNameRequired => 'Full Legal Company Name *';

  @override
  String get registeredOfficeAddress => 'Registered Office Address';

  @override
  String get taxIdPibRequired => 'Tax ID (PIB) *';

  @override
  String get companyRegNo => 'Company Reg No (Matični broj)';

  @override
  String get legalRepFullNameRequired => 'Legal Representative Full Name *';

  @override
  String get repIdJmbg => 'Rep. ID / JMBG Number';

  @override
  String get repAuthorityDetails => 'Representative Authority Details / Title';

  @override
  String get contactPhoneRequired => 'Contact Phone *';

  @override
  String get secondaryContactOptional => 'Secondary Contact (Optional)';

  @override
  String get altPhoneOrNote => 'Alt. Phone / Note';

  @override
  String get emailAddressRequiredForPrimary =>
      'Email Address (Required for Primary) *';

  @override
  String get emailAddressOptional => 'Email Address (Optional)';

  @override
  String get selectExistingAgencyContact =>
      'Or select from existing agency contacts...';

  @override
  String get clearSelectionTooltip => 'Clear selection';

  @override
  String get supportingPdfDocuments => 'Supporting PDF Documents';

  @override
  String get uploadDocumentTooltip => 'Upload Document';

  @override
  String get docTypePassportCopy => 'ID Document Copy (PDF)';

  @override
  String get docTypeProofOfOwnership => 'Proof of Ownership / Title Deed (PDF)';

  @override
  String get docTypePowerOfAttorney => 'Power of Attorney / POA (PDF)';

  @override
  String get docTypeOtherDocument => 'Other Document (PDF)';

  @override
  String get addPdfDocument => '+ Add PDF Document';

  @override
  String get docTypeLabelId => 'ID';

  @override
  String get docTypeLabelTitleDeed => 'Deed';

  @override
  String get docTypeLabelPoa => 'POA';

  @override
  String get docTypeLabelOther => 'Doc';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String markAsPaidSubtitle(String title, String month) {
    return 'Payment confirmation for $title ($month)';
  }

  @override
  String get bankTransferOption => 'Bank Transfer';

  @override
  String get receiptOrDocOptional => 'Receipt / Document (Optional)';

  @override
  String get uploadReceiptOrImage => 'Upload receipt or image';

  @override
  String get uploadReceiptHint => 'Choose PDF, PNG, JPG or camera photo';

  @override
  String get noteOptional => 'Note (Optional)';

  @override
  String get noteOptionalRentHint => 'E.g. Paid in cash / Receipt attached';

  @override
  String get paymentMarkedPaidSuccess => 'Payment successfully marked as paid.';

  @override
  String get saveAsPaid => 'Save as Paid';

  @override
  String get collectSettleExpenseTitle => 'Collect & Settle Expense';

  @override
  String collectSettleExpenseSubtitle(String cost) {
    return 'Confirm collection of $cost and settle this charge.';
  }

  @override
  String get collectionMethod => 'Collection Method';

  @override
  String get collectionMethodBank => 'Bank Transfer';

  @override
  String get collectionMethodCash => 'Cash';

  @override
  String get collectionMethodPayoutDeduction => 'Deducted from Payout';

  @override
  String get attachReceiptOrVoucher => 'Attach receipt or voucher';

  @override
  String get noteOptionalAgencyHint =>
      'E.g. Paid in cash / Bank transfer confirmed';

  @override
  String get payoutDeductionLabel => 'Payout Deduction';

  @override
  String get collectionConfirmedAndSettled =>
      'Collection confirmed and settled.';

  @override
  String get confirmAndSettle => 'Confirm & Settle';

  @override
  String propertyOwnersCountTitle(int count) {
    return 'Property Owners ($count)';
  }

  @override
  String get editOwners => 'Edit Owners';

  @override
  String get primaryOwnerBadge => 'Primary';

  @override
  String get authorizedRepresentative => 'Representative';

  @override
  String get registeredAddressLabel => 'Registered Address';

  @override
  String get idJmbgLabel => 'ID/JMBG';

  @override
  String get secondaryContactPrefix => 'Alt Contact: ';

  @override
  String get supportingDocumentsColon => 'Supporting Documents:';

  @override
  String get auditPaymentCreatedRent =>
      'System automatically created the due record';

  @override
  String get auditPaymentCreatedExpense =>
      'System automatically created the expense record';

  @override
  String auditRentDeclaredCash(String actor, String monthSuffix) {
    return '$actor declared payment (Cash)$monthSuffix';
  }

  @override
  String auditRentDeclaredReceipt(String actor, String monthSuffix) {
    return '$actor declared payment by uploading a receipt$monthSuffix';
  }

  @override
  String auditRentApproved(String actor, String monthSuffix) {
    return '$actor approved payment$monthSuffix';
  }

  @override
  String auditRentRejected(String actor, String monthSuffix) {
    return '$actor rejected payment$monthSuffix';
  }

  @override
  String auditRentDisputed(String actor, String reasonSuffix) {
    return '$actor objected to the payment$reasonSuffix';
  }

  @override
  String auditInvoiceUploadedPending(
    String actor,
    String monthPrefix,
    String amount,
  ) {
    return '$actor ${monthPrefix}uploaded a bill (Awaiting approval, $amount)';
  }

  @override
  String auditInvoiceUploaded(String actor, String monthPrefix, String amount) {
    return '$actor ${monthPrefix}uploaded a bill ($amount)';
  }

  @override
  String auditInvoiceEnteredPending(
    String actor,
    String monthPrefix,
    String amount,
  ) {
    return '$actor ${monthPrefix}entered bill details (Awaiting approval, $amount)';
  }

  @override
  String auditInvoiceEntered(String actor, String monthPrefix, String amount) {
    return '$actor ${monthPrefix}entered bill details ($amount)';
  }

  @override
  String auditInvoiceApproved(String actor, String monthPrefix, String amount) {
    return '$actor ${monthPrefix}approved bill ($amount)';
  }

  @override
  String auditInvoiceRejected(
    String actor,
    String monthPrefix,
    String reasonSuffix,
  ) {
    return '$actor ${monthPrefix}rejected bill$reasonSuffix';
  }

  @override
  String auditPaymentToggle(String actor, String status) {
    return '$actor marked payment as $status';
  }

  @override
  String get auditRentAutoApproved =>
      'Payment was automatically approved by the system';

  @override
  String auditMaintenanceCreated(String actor, String titleSuffix) {
    return '$actor created a maintenance request$titleSuffix';
  }

  @override
  String auditMaintenanceStatusUpdated(String actor, String status) {
    return '$actor updated maintenance status ($status)';
  }

  @override
  String auditMaintenanceMessageAdded(String actor) {
    return '$actor added a message to maintenance request';
  }

  @override
  String auditMaintenanceReopened(String actor) {
    return '$actor reopened maintenance request';
  }

  @override
  String contactTenantAsLandlordInfo(String propertySummary) {
    return 'This contact is registered as a tenant ($propertySummary). Now being added as a landlord.';
  }

  @override
  String get registeredLandlordDetailsAutofilled =>
      'Registered landlord details auto-filled.';

  @override
  String get noDocumentsAttachedYet =>
      'No documents attached yet (You can attach ID, Title deed or POA).';

  @override
  String get coOwnerEmailHelper =>
      'If entered, the co-owner will see the property in their landlord dashboard upon login.';

  @override
  String get propertyOwnersUpdatedSuccess =>
      'Property owners updated successfully.';

  @override
  String get systemActor => 'System';

  @override
  String get agencyRole => 'Agency';

  @override
  String get editPropertyOwners => 'Edit Property Owners';

  @override
  String auditInvitationAccepted(Object actor) {
    return '$actor accepted the property invitation';
  }

  @override
  String auditContractAccepted(Object actor) {
    return '$actor approved and signed the lease contract';
  }

  @override
  String auditContractTerminationRequested(Object actor) {
    return '$actor requested early contract termination';
  }

  @override
  String auditContractChangesAccepted(Object actor) {
    return '$actor accepted the proposed contract changes';
  }

  @override
  String auditContractChangesDeclined(Object actor) {
    return '$actor declined or withdrew the proposed contract changes';
  }

  @override
  String auditLandlordOwnershipClaimed(Object actor) {
    return '$actor claimed property ownership and management';
  }

  @override
  String auditTenantRemoved(Object actor) {
    return '$actor removed the tenant from the property';
  }

  @override
  String auditPropertyOwnersUpdated(Object actor) {
    return '$actor updated property owner details';
  }

  @override
  String auditMaintenanceFinancialsUpdated(Object actor) {
    return '$actor updated maintenance cost and financial details';
  }

  @override
  String auditMaintenanceFinancialsDeleted(Object actor) {
    return '$actor deleted maintenance cost details and reverted settlements';
  }

  @override
  String auditMaintenanceChargeCreated(Object actor) {
    return '$actor added a new maintenance expense item';
  }

  @override
  String auditMaintenanceChargeStatusUpdated(Object actor) {
    return '$actor updated maintenance charge status';
  }

  @override
  String auditMaintenanceChargeSettled(Object actor) {
    return '$actor settled maintenance charge';
  }

  @override
  String auditMaintenanceDeleted(Object actor) {
    return '$actor deleted the maintenance request';
  }

  @override
  String get tenantInviteEmailTitle => 'Tenant Invitation Email';

  @override
  String get landlordInviteEmailTitle => 'Landlord Invitation Email';

  @override
  String get statusNotSent => 'Not Sent';

  @override
  String get statusNoEmail => 'No Email';

  @override
  String lastSentAt(String date) {
    return 'Last sent: $date';
  }

  @override
  String get noEmailSpecified => 'No email address specified';

  @override
  String ownersConfirmedRatio(String confirmed, String total) {
    return '$confirmed/$total Confirmed';
  }

  @override
  String ownerConfirmedBanner(String name) {
    return '$name accepted the invitation and confirmed property management.';
  }

  @override
  String get emailPreviewTitle => 'Outgoing Email Preview';

  @override
  String emailPreviewForOwner(String name) {
    return 'Email Preview ($name)';
  }

  @override
  String get tabVisual => 'Visual';

  @override
  String get tabPlainText => 'Plain Text';

  @override
  String get emailCopiedToast => 'Email text copied to clipboard.';

  @override
  String get languageLabel => 'Language:';

  @override
  String get subjectHeader => 'SUBJECT';

  @override
  String get contentHeader => 'CONTENT';

  @override
  String get recipientWillReceiveThisFormat =>
      'Recipient will receive this format';

  @override
  String get sendTenantInviteEmailBtn => 'Send Invitation Email to Tenant';

  @override
  String get resendInviteEmailBtn => 'Resend Invitation Email';

  @override
  String get sendLandlordInviteEmailBtn => 'Send Invitation Email to Landlord';

  @override
  String sendInviteForOwnerBtn(String name) {
    return 'Send Invitation Email for $name';
  }

  @override
  String resendInviteForOwnerBtn(String name) {
    return 'Resend for $name';
  }

  @override
  String get sendToAllBtn => 'Send to All';

  @override
  String sendToAllOwnersBtn(String count) {
    return 'Send to All Landlords Individually ($count)';
  }

  @override
  String resendToAllOwnersBtn(String count) {
    return 'Resend to All Landlords ($count)';
  }

  @override
  String get sendingState => 'Sending...';

  @override
  String get sendingAllState => 'Sending to all...';

  @override
  String get noEmailAddressDefined => 'No Email Address Defined';

  @override
  String tenantInviteSentSuccess(String email) {
    return 'Invitation email successfully sent to $email.';
  }

  @override
  String landlordInviteSentSuccess(String email) {
    return 'Invitation email successfully sent to $email.';
  }

  @override
  String noEmailForUserError(String name) {
    return 'No email address found for $name.';
  }

  @override
  String get tenantNoEmailError => 'Tenant email address is not defined.';

  @override
  String get emailSendFailedError =>
      'Failed to send invitation email. Please check Brevo API settings.';

  @override
  String emailSendGenericError(String error) {
    return 'Error occurred while sending email: $error';
  }

  @override
  String get tenantInviteEmailBtn => 'Tenant Invite Email';

  @override
  String allOwnersInviteSentSuccess(String successCount, String totalCount) {
    return 'Invitation emails successfully sent to $successCount / $totalCount property owners.';
  }

  @override
  String landlordsListHeader(String count) {
    return 'Property Owners ($count)';
  }
}
