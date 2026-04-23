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
  String get zzplConsent => 'I agree to the processing of my data in accordance with the Law on Personal Data Protection (ZZPL) of Serbia.';

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
  String get deleteAccountWarning => 'This action is permanent and cannot be undone. All your data will be deleted.';

  @override
  String get confirmPasswordForDeletion => 'Please enter your password to confirm deletion';

  @override
  String get deleteButtonLabel => 'Permanently Delete My Account';

  @override
  String get cancel => 'Cancel';

  @override
  String get invalidPassword => 'Invalid password';

  @override
  String get welcomeToStanomer => 'Welcome to Stanomer';

  @override
  String get consentTextFullTitle => 'Consent for Personal Data Processing (ZZPL)';

  @override
  String get profile => 'Profile';

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
  String get addYourFirstProperty => 'Add your first property to start tracking!';

  @override
  String get editProperty => 'Edit Property';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDeleteTitle => 'Delete Property';

  @override
  String get confirmDeleteMessage => 'Are you sure you want to delete this property? This action cannot be undone.';

  @override
  String get propertyDeletedSuccess => 'Property deleted successfully';

  @override
  String get inviteTenant => 'Invite Tenant';

  @override
  String get emailHint => 'Enter tenant\'s email address';

  @override
  String get inviteCreatedSuccess => 'Invite link created! You can now share it.';

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
  String get myProperties => 'My Properties';

  @override
  String get tenantEmptyStateTitle => 'No property assigned yet';

  @override
  String get tenantEmptyStateMessage => 'If your landlord has sent you an invitation, it will appear here. Tap the button below to check for new invites.';

  @override
  String get refresh => 'Refresh';

  @override
  String get invitationDeclinedSuccess => 'Invitation declined.';

  @override
  String get confirmDeclineInviteTitle => 'Decline Invitation?';

  @override
  String get confirmDeclineInviteMessage => 'Are you sure you want to decline this invitation? It will be removed from your pending list.';

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
  String get tenantMode => 'Tenant Mode';

  @override
  String get landlordMode => 'Landlord Mode';

  @override
  String get whatAreYou => 'What would you like to continue as?';

  @override
  String get selectRoleToContinue => 'Select a role to get started. You can switch anytime from the header above.';

  @override
  String get consentTextFullBody => 'By using the Stanomer application, you provide explicit consent for the processing of your personal data in accordance with the Law on Personal Data Protection (ZZPL) of the Republic of Serbia.\n\nWhat data is collected: Your name, e-mail address, IP address, and real estate lease agreement data.\n\nPurpose of processing: The data is used exclusively to facilitate communication between the landlord and the tenant, keep payment records, and create legally valid logs.\n\nData sharing: Your data is not sold to third parties. It is stored on secure servers in the EU (Supabase Frankfurt).\n\nYour rights: You have the right at any time to request access to your data or permanent deletion of your account and all associated data directly through the app.';

  @override
  String get removeTenant => 'Remove Tenant';

  @override
  String get removeTenantConfirmation => 'Are you sure you want to remove this tenant from the property? This will detach them and delete the invitation record.';

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
  String get noContractsMessage => 'To track rent and expenses for your property, first invite a tenant by entering contract details.';

  @override
  String get inviteFirstTenant => 'Invite First Tenant';

  @override
  String get confirmCancelInvitationTitle => 'Cancel Invitation';

  @override
  String get confirmCancelInvitationMessage => 'Are you sure you want to withdraw this invitation? This action will permanently delete it.';

  @override
  String get confirmDeclineRevisionTitle => 'Decline Revision Request';

  @override
  String get confirmDeclineRevisionMessage => 'Are you sure you want to decline the tenant\'s revision request? The contract will remain pending with its original terms.';

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
  String get paidHeader => 'PAID';

  @override
  String get waitingForTenantPayment => 'Waiting for tenant payment';

  @override
  String get waitingForYourApproval => 'Waiting for your approval';

  @override
  String get waitingForOwnerApproval => 'Waiting for owner approval';

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
  String get uploadInvoice => 'Upload Invoice';

  @override
  String get awaitingInvoice => 'Awaiting invoice';

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
  String get activeContractTermsInfo => 'Active contract terms. All updates made here take effect only when both tenant and landlord agree.';

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
  String get uploadReceipt => 'Upload Receipt';

  @override
  String get paidInCash => 'Paid in Cash';

  @override
  String get noFinancialRecords => 'No financial records found yet';

  @override
  String get noActiveContract => 'No uploaded contract found';

  @override
  String get contractTermsInfo => 'Active contract terms. All updates made here take effect only when both tenant and landlord agree.';

  @override
  String get send => 'Send';

  @override
  String get totalRent => 'Total Rent';

  @override
  String get infoTooltip => 'Covers pooled public utilities like heating, water, and waste.';

  @override
  String get electricityTooltip => 'Individual electricity consumption cost.';

  @override
  String get internetTooltip => 'Subscription-based internet and TV packages.';

  @override
  String get maintenanceTooltip => 'Building cleaning, elevator maintenance, and common area costs.';

  @override
  String get declare => 'Declare';

  @override
  String get viewReceipt => 'View Receipt';

  @override
  String proposesChanges(String name) {
    return '$name proposes the following changes:';
  }

  @override
  String get awaitingApprovalInfo => 'Your change proposal is awaiting the other party\'s approval.';

  @override
  String get propertyDetails => 'PROPERTY DETAILS';

  @override
  String get defaultLeaseTerms => 'DEFAULT LEASE TERMS';

  @override
  String get defaultLeaseTermsSubtitle => 'Target terms used as a template for new invitations.';

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
  String get setAmountAndUploadInvoice => 'Set Amount & Upload Invoice';

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
  String get existingContractTermsInfo => 'Existing agreed contract terms (rent, dates, and expenses) will apply to this tenant as well.';

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
  String get statusPending => 'Pending Approval';

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
  String get viewInvoice => 'View Invoice';

  @override
  String get paymentResponsibility => 'PAYMENT RESPONSIBILITY';

  @override
  String get tenantPaysDirectlyToUtility => 'Tenant pays directly to the utility';

  @override
  String get tenantPaysToLandlord => 'Tenant pays to the landlord';

  @override
  String get selectPaymentReceiverWarning => 'Please select the payment receiver before continuing.';

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
  String get categoryOther => 'Other';

  @override
  String get noIssuesTitle => 'No issues reported yet';

  @override
  String get noIssuesMessage => 'All good! No maintenance requests for this property.';

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
  String get logMaintenanceMessageAdded => 'New message added to maintenance request';

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
  String get deleteDocumentConfirm => 'Are you sure you want to delete this document?';

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
  String get confirmApprovePaymentMessage => 'Are you sure you want to approve this payment?';

  @override
  String get confirmRejectPaymentTitle => 'Reject Payment';

  @override
  String get confirmRejectPaymentMessage => 'Do you want to reject this declaration and ask the tenant to re-declare?';

  @override
  String get confirm => 'Confirm';

  @override
  String get terminateContract => 'Terminate Contract';

  @override
  String get terminationDate => 'Termination Date';

  @override
  String get confirmTerminationTitle => 'Terminate Contract?';

  @override
  String get confirmTerminationMessage => 'Are you sure you want to send a termination request to end this contract on the selected date?';

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
  String get disputeSentSuccess => 'Your dispute has been sent to the landlord.';

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
  String get maintenanceRequestSuccess => 'Maintenance request sent successfully.';

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
  String get propertyDetailsHeader => 'PROPERTY DETAILS';

  @override
  String get defaultLeaseTermsHeader => 'DEFAULT LEASE TERMS';

  @override
  String get proposeRevision => 'Propose Revision';

  @override
  String get revisionTermsQuestion => 'Which terms would you like to change? (Rent, due day, expenses, etc.)';

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
  String get acceptTermsAndDistribution => 'I accept the contract terms and expense distribution.';

  @override
  String get datesMandatory => 'Start and end dates are mandatory';

  @override
  String get partiesHeader => 'PARTIES';

  @override
  String get leaseLockedWarning => 'Existing agreed contract terms (rent, dates, and expenses) will apply to this tenant as well.';

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
  String get setAmountUploadInvoice => 'Set Amount & Upload Invoice';

  @override
  String get yourMessage => 'Your message:';

  @override
  String get revisionRequestLabel => 'Revision Request:';

  @override
  String get noActivityLogs => 'No activity logs found yet';

  @override
  String get landlordProposedChanges => 'Landlord proposed contract changes. Tap to review.';

  @override
  String get tenantProposedChanges => 'Tenant proposed contract changes. Tap to review.';

  @override
  String dueOn(String date) {
    return 'Due on $date';
  }

  @override
  String get item => 'item';

  @override
  String get items => 'items';

  @override
  String get waitingForOtherParty => 'Awaiting approval from the other party...';

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
  String get unlimitedProperties => 'Unlimited property addition and management';

  @override
  String get detailedReporting => 'Faster and more detailed reporting';

  @override
  String get extraStorage => 'More storage space';

  @override
  String get pdfContracts => 'PDF contract generation (Coming Soon)';

  @override
  String get automatedRenewal => 'Automated rent calculation and renewal (Coming Soon)';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get limitReachedTitle => 'You\'ve reached your free limit';

  @override
  String get limitReachedSubtitle => 'Upgrade to Stanomer Premium to manage multiple properties.';

  @override
  String get discoverPremium => 'Discover Premium';

  @override
  String get optionsLoadFailed => 'Could not load subscription options.';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get premiumMobileOnly => 'Mobile App Required';

  @override
  String get premiumMobileOnlyDesc => 'Stanomer Premium subscriptions can only be purchased through the mobile app. Download the app below to get started with Premium.';

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
  String get termsOfServiceContent => 'Stanomer – End User License Agreement (EULA) & Terms of Service\nLast Updated: April 23, 2026\n\n1. Introduction\nThis End User License Agreement (\"Agreement\") is a legal agreement between you (\"User\") and Stanomer (\"we,\" \"us,\" or \"our\"). By installing or using the Stanomer mobile application (\"App\"), you agree to be bound by the terms of this Agreement.\n\n2. Apple and Google Terms\nApple App Store: This Agreement is concluded between the User and Stanomer only, and not with Apple Inc. This agreement incorporates Apple’s Standard Licensed Application End User License Agreement (Standard EULA) by reference: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/\n\nGoogle Play Store: This Agreement is concluded between the User and Stanomer only, and not with Google LLC.\n\nYou acknowledge that Apple and Google have no obligation whatsoever to furnish any maintenance and support services with respect to the App.\n\n3. Subscription and Billing (Auto-Renewable Subscriptions)\nStanomer offers premium features via auto-renewable subscriptions.\n\nPayment: Payment will be charged to your iTunes Account (Apple) or Google Play Account at confirmation of purchase.\n\nRenewal: Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period.\n\nManagement: You can manage or turn off auto-renew in your Account Settings (App Store or Play Store) after purchase.\n\n4. User Content & Conduct\nYou are responsible for the data you enter (rental amounts, damage reports, contracts).\n\nYou may not upload illegal, offensive, or infringing content.\n\nStanomer reserves the right to remove any content that violates Serbian laws or these terms.\n\n5. Privacy and Global Data Protection (ZZPL, GDPR, KVKK Compliance)\nYour use of the App is governed by our Privacy Policy. We are committed to protecting your personal data in compliance with:\n\nSerbian Law (ZZPL): Zakon o zaštiti podataka o ličnosti.\n\nGDPR: General Data Protection Regulation (EU).\n\nKVKK: Personal Data Protection Law (Turkey).\n\nOther International Standards: We adhere to global data privacy principles to ensure your information is handled securely regardless of your location.\n\n6. Limitation of Liability\nStanomer provides a platform for rental management and is not a party to the actual rental agreements between landlords and tenants. We are not liable for disputes arising between users or for financial transactions conducted outside the platform.\n\n7. Termination\nThis Agreement is effective until terminated by you or Stanomer. Your rights under this license will terminate automatically if you fail to comply with any of its terms.';
}
