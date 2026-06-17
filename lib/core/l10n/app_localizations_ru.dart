// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Stanomer';

  @override
  String get login => 'Войти';

  @override
  String get signup => 'Зарегистрироваться';

  @override
  String get email => 'Эл. почта';

  @override
  String get password => 'Пароль';

  @override
  String get landlord => 'Арендодатель';

  @override
  String get tenant => 'Арендатор';

  @override
  String get zzplConsent =>
      'Я согласен(на) на обработку моих данных в соответствии с Законом о защите персональных данных (ZZPL) Сербии.';

  @override
  String get selectRole => 'Выберите вашу роль';

  @override
  String get fieldRequired => 'Это поле обязательно для заполнения';

  @override
  String get consentRequired => 'Вы должны согласиться с ZZPL для продолжения';

  @override
  String get loginToAccount => 'Войдите в свой аккаунт';

  @override
  String get createAccount => 'Создать новый аккаунт';

  @override
  String get dontHaveAccount => 'Нет аккаунта? Зарегистрируйтесь';

  @override
  String get alreadyHaveAccount => 'Уже зарегистрированы? Войти';

  @override
  String get continueWithGoogle => 'Войти через Google';

  @override
  String get continueWithApple => 'Войти через Apple';

  @override
  String get fullName => 'Имя и фамилия';

  @override
  String get errorSelectRole => 'Пожалуйста, выберите вашу роль';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountWarning =>
      'Это действие необратимо и его нельзя отменить. Все ваши данные будут удалены.';

  @override
  String get confirmPasswordForDeletion =>
      'Пожалуйста, введите пароль для подтверждения';

  @override
  String get deleteButtonLabel => 'Навсегда удалить мой аккаунт';

  @override
  String get cancel => 'Отмена';

  @override
  String get invalidPassword => 'Неверный пароль';

  @override
  String get welcomeToStanomer => 'Добро пожаловать в Stanomer';

  @override
  String get consentTextFullTitle =>
      'Согласие на обработку персональных данных (ZZPL)';

  @override
  String get profile => 'Профиль';

  @override
  String get settingsHeader => 'Настройки';

  @override
  String get accountHeader => 'Аккаунт';

  @override
  String get discoverPremium => 'Попробовать Premium';

  @override
  String get unlimitedLeaseContracts => 'Безлимитные договоры аренды';

  @override
  String get updateName => 'Обновить имя';

  @override
  String get updatePassword => 'Изменить пароль';

  @override
  String get oldPassword => 'Текущий пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get saveChanges => 'Сохранить';

  @override
  String get passwordChangedSuccess => 'Пароль успешно обновлен';

  @override
  String get profileUpdatedSuccess => 'Профиль обновлен';

  @override
  String get role => 'Роль';

  @override
  String get roleLandlord => 'Арендодатель';

  @override
  String get roleTenant => 'Арендатор';

  @override
  String get logout => 'Выйти';

  @override
  String get addProperty => 'Добавить недвижимость';

  @override
  String get address => 'Адрес';

  @override
  String get monthlyRent => 'Ежемесячная аренда';

  @override
  String get depositAmount => 'Депозит';

  @override
  String get currency => 'Валюта';

  @override
  String get propertyName => 'Название недвижимости';

  @override
  String get propertyNameHint => 'например, Квартира в Белграде';

  @override
  String get propertyAddedSuccess => 'Жилье добавлено';

  @override
  String get propertyUpdatedSuccess => 'Данные обновлены';

  @override
  String get noProperties => 'У вас пока нет добавленного жилья';

  @override
  String get addYourFirstProperty =>
      'Добавьте свое первое жилье, чтобы начать!';

  @override
  String get editProperty => 'Редактировать';

  @override
  String get delete => 'Удалить';

  @override
  String get confirmDeleteTitle => 'Удалить недвижимость';

  @override
  String get confirmDeleteMessage =>
      'Вы уверены, что хотите удалить эту недвижимость? Это действие необратимо.';

  @override
  String get propertyDeletedSuccess => 'Объект удален';

  @override
  String get inviteTenant => 'Пригласить арендатора';

  @override
  String get emailHint => 'Введите эл. почту арендатора';

  @override
  String get inviteCreatedSuccess =>
      'Ссылка для приглашения готова! Вы можете отправить ее жильцу.';

  @override
  String get shareInviteLink => 'Поделиться приглашением';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get noInvitesYet => 'Приглашения еще не отправлены';

  @override
  String get cancelInvitation => 'Отменить приглашение';

  @override
  String get invitationCancelledSuccess => 'Приглашение успешно отменено';

  @override
  String get pendingInvite => 'В ожидании';

  @override
  String get contractSentToTenant => 'Договор отправлен арендатору';

  @override
  String get overview => 'Обзор';

  @override
  String get financials => 'Платежи';

  @override
  String get propertySettings => 'Настройки жилья';

  @override
  String get invitationHistory => 'История приглашений';

  @override
  String get invitationDetails => 'Детали приглашения';

  @override
  String get acceptInvitation => 'Да, я арендую это жилье';

  @override
  String get declineInvitation => 'Отклонить';

  @override
  String get inviteNotFound => 'Приглашение не найдено или истек срок действия';

  @override
  String get invitationAcceptedSuccess =>
      'Добро пожаловать! Приглашение принято.';

  @override
  String pendingInvitationBanner(String property) {
    return 'У вас есть приглашение для $property';
  }

  @override
  String invitedBy(String name) {
    return 'Вас пригласил $name';
  }

  @override
  String get yourName => 'Ваше имя';

  @override
  String get yourNameHint => 'Введите ваши имя и фамилию';

  @override
  String get viewInvite => 'Посмотреть';

  @override
  String get myProperties => 'Моя недвижимость';

  @override
  String get tenantEmptyStateTitle => 'Нет добавленного жилья';

  @override
  String get tenantEmptyStateMessage =>
      'Когда собственник отправит вам приглашение, оно появится здесь.';

  @override
  String get refresh => 'Обновить';

  @override
  String get invitationDeclinedSuccess => 'Приглашение отклонено.';

  @override
  String get confirmDeclineInviteTitle => 'Отклонить приглашение?';

  @override
  String get confirmDeclineInviteMessage =>
      'Вы уверены, что хотите отклонить приглашение? Оно будет удалено.';

  @override
  String get contractStartDate => 'Дата начала договора';

  @override
  String get contractEndDate => 'Дата окончания договора';

  @override
  String get uploadContract => 'Загрузить договор';

  @override
  String get viewContract => 'Посмотреть договор';

  @override
  String get contractFile => 'Файл договора';

  @override
  String get selectDate => 'Выберите дату';

  @override
  String get appLanguage => 'Язык';

  @override
  String get english => 'Английский';

  @override
  String get serbianLatin => 'Сербский (Латиница)';

  @override
  String get serbianCyrillic => 'Сербский (Кириллица)';

  @override
  String get turkish => 'Турецкий';

  @override
  String get russian => 'Русский';

  @override
  String get tenantMode => 'Я арендатор';

  @override
  String get landlordMode => 'Я собственник';

  @override
  String get whatAreYou => 'Выберите вашу роль:';

  @override
  String get selectRoleToContinue =>
      'Выберите вашу роль, чтобы продолжить. Ее можно изменить в любой момент.';

  @override
  String get consentTextFullBody =>
      'Используя приложение Stanomer, вы даете согласие на обработку персональных данных в соответствии с Законом о защите персональных данных (ZZPL) Сербии.';

  @override
  String get removeTenant => 'Удалить арендатора';

  @override
  String get removeTenantConfirmation =>
      'Вы уверены, что хотите удалить арендатора? Связь будет разорвана.';

  @override
  String get remove => 'Удалить';

  @override
  String logRentDeclared(String month) {
    return 'Арендатор сообщил об оплате за $month.';
  }

  @override
  String logRentApproved(String month) {
    return 'Собственник подтвердил оплату за $month.';
  }

  @override
  String logRentRejected(String month) {
    return 'Собственник отклонил подтверждение оплаты за $month.';
  }

  @override
  String logMarkedAsPaid(String month) {
    return 'Собственник отметил $month как оплаченный.';
  }

  @override
  String logMarkedAsPending(String month) {
    return 'Собственник вернул $month в статус ожидания.';
  }

  @override
  String logAutoApproved(String month) {
    return 'Система автоматически подтвердила оплату за $month через 5 дней.';
  }

  @override
  String get activity => 'Активность';

  @override
  String get noContractsTitle => 'Нет активных договоров';

  @override
  String get noContractsMessage =>
      'Чтобы отслеживать аренду и расходы, сначала добавьте договор и пригласите жильца.';

  @override
  String get inviteFirstTenant => 'Пригласить арендатора';

  @override
  String get confirmCancelInvitationTitle => 'Отменить приглашение';

  @override
  String get confirmCancelInvitationMessage =>
      'Вы уверены, что хотите отменить приглашение?';

  @override
  String get confirmDeclineRevisionTitle => 'Отклонить запрос на изменение';

  @override
  String get confirmDeclineRevisionMessage =>
      'Вы уверены, что хотите отклонить предложение жильца об изменениях? Договор останется на прежних условиях.';

  @override
  String get activeContract => 'Активный договор';

  @override
  String get activeLease => 'АКТИВНАЯ АРЕНДА';

  @override
  String get invitationSent => 'Приглашение отправлено';

  @override
  String get accept => 'Принять';

  @override
  String get decline => 'Отклонить';

  @override
  String get declineRevisionRequest => 'Отклонить изменения';

  @override
  String get pendingHeader => 'ЖДЕТ ОПЛАТЫ';

  @override
  String get awaitingHeader => 'НА ПРОВЕРКЕ';

  @override
  String get awaitingExplanation =>
      'Требуется подтверждение арендодателя, чтобы отметить как оплачено.';

  @override
  String get paidHeader => 'ОПЛАЧЕНО';

  @override
  String get waitingForTenantPayment => 'Ожидает оплаты жильцом';

  @override
  String get waitingForYourApproval => 'Ожидает вашего подтверждения';

  @override
  String get waitingForOwnerApproval => 'Ожидает подтверждения владельца';

  @override
  String get waitingForYourPayment => 'Ожидает вашей оплаты';

  @override
  String get processCompleted => 'Готово';

  @override
  String get declared => 'сообщено';

  @override
  String get sent => 'отправлено';

  @override
  String get noInvoice => 'Чек не загружен';

  @override
  String get uploadInvoice => 'Загрузить чек';

  @override
  String get awaitingInvoice => 'Ожидается чек';

  @override
  String get updateLabel => 'Обновить';

  @override
  String get statusVacant => 'Свободно';

  @override
  String get pendingApproval => 'НА ПРОВЕРКЕ';

  @override
  String get targetRent => 'ЦЕЛЕВАЯ АРЕНДА';

  @override
  String get contractInfo => 'О договоре';

  @override
  String get term => 'Срок аренды';

  @override
  String get dueDay => 'День платежа';

  @override
  String get contractDetails => 'Детали договора';

  @override
  String get pastContracts => 'История договоров';

  @override
  String previousLeasesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count прошлых договоров',
      few: '$count прошлых договора',
      one: '$count прошлый договор',
    );
    return '$_temp0';
  }

  @override
  String get propertySettingsLabel => 'Настройки жилья';

  @override
  String get propertyActions => 'Действия с объектом';

  @override
  String get leavePropertyConfirm =>
      'Вы уверены, что хотите покинуть этот объект?';

  @override
  String get leaveProperty => 'Покинуть жилье';

  @override
  String get areYouSure => 'Вы уверены?';

  @override
  String get pendingInvitations => 'Ожидающие приглашения';

  @override
  String get contractSettings => 'Настройки договора';

  @override
  String get activeContractTermsInfo =>
      'Условия активного договора. Любые изменения вступят в силу только после подтверждения обеими сторонами.';

  @override
  String get dueDayOfMonth => 'День оплаты в месяце';

  @override
  String get startDate => 'Дата начала';

  @override
  String get endDate => 'Дата окончания';

  @override
  String get taxConfiguration => 'Налог';

  @override
  String get included => 'Включено';

  @override
  String get addedVat => 'Добавлено (+15%)';

  @override
  String get expensesHeader => 'РАСХОДЫ';

  @override
  String get extraPayment => 'Дополнительный платеж';

  @override
  String get utility => 'Коммунальные услуги';

  @override
  String get owner => 'Собственник';

  @override
  String proposeChangesInfo(String role) {
    return 'Изменения будут отправлены на подтверждение $role. Прежние условия действуют, пока новые не приняты.';
  }

  @override
  String get proposeChanges => 'Предложить изменения';

  @override
  String get declarePayment => 'Сообщить об оплате';

  @override
  String get uploadReceipt => 'Загрузить чек';

  @override
  String get paidInCash => 'Оплачено наличными';

  @override
  String get noFinancialRecords => 'Нет истории платежей';

  @override
  String get noActiveContract => 'Нет загруженного договора';

  @override
  String get contractTermsInfo =>
      'Условия договора. Любые изменения вступят в силу только после согласия обеих сторон.';

  @override
  String get send => 'Отправить';

  @override
  String get totalRent => 'Итого к оплате';

  @override
  String get infoTooltip =>
      'Покрывает общие коммунальные услуги (отопление, вода, вывоз мусора).';

  @override
  String get electricityTooltip => 'Индивидуальное потребление электроэнергии.';

  @override
  String get internetTooltip => 'Интернет и ТВ.';

  @override
  String get maintenanceTooltip =>
      'Обслуживание дома (уборка подъезда, лифт и т.д.).';

  @override
  String get declare => 'Сообщить';

  @override
  String get viewReceipt => 'Посмотреть чек';

  @override
  String proposesChanges(String name) {
    return '$name предлагает следующие изменения:';
  }

  @override
  String get awaitingApprovalInfo =>
      'Ваше предложение об изменениях ожидает подтверждения второй стороны.';

  @override
  String get propertyDetails => 'ДЕТАЛИ ОБЪЕКТА';

  @override
  String get defaultLeaseTerms => 'УСЛОВИЯ АРЕНДЫ ПО УМОЛЧАНИЮ';

  @override
  String get defaultLeaseTermsSubtitle =>
      'Используются как шаблон для новых приглашений арендаторов.';

  @override
  String get invalidNumber => 'Неверный номер';

  @override
  String get enterDayBetween1and31 => 'Введите день с 1 по 31';

  @override
  String get expenseConfiguration => 'НАСТРОЙКА РАСХОДОВ';

  @override
  String get expenseInfostan => 'Инфостан';

  @override
  String get expenseElectricity => 'Электричество';

  @override
  String get expenseInternetTV => 'Интернет/ТВ';

  @override
  String get expenseMaintenance => 'Обслуживание дома';

  @override
  String get expenseTax => 'Налог';

  @override
  String get tenantPaysTo => 'Кому платит арендатор:';

  @override
  String get fileSelected => 'Файл выбран';

  @override
  String get selectInvoice => 'Прикрепить счет';

  @override
  String get amount => 'Сумма';

  @override
  String get setAmountAndUploadInvoice => 'Введите данные счета';

  @override
  String get save => 'Сохранить';

  @override
  String get paymentDeclared => 'Уведомление об оплате отправлено.';

  @override
  String get dashboard => 'Мое жилье';

  @override
  String get parties => 'СТОРОНЫ';

  @override
  String get tenantEmail => 'Email арендатора';

  @override
  String get existingContractTermsInfo =>
      'Для этого жильца будут действовать согласованные условия договора (аренда, даты, распределение расходов).';

  @override
  String get rentAndPayment => 'АРЕНДА И ОПЛАТА';

  @override
  String get datesAndContract => 'ДАТЫ И ДОГОВОР';

  @override
  String get expenseSettingsHeader => 'НАСТРОЙКИ РАСХОДОВ';

  @override
  String get editContract => 'Редактировать договор';

  @override
  String get sendRevision => 'Отправить изменения';

  @override
  String get revisionSent => 'Предложение об изменениях отправлено.';

  @override
  String get existingFileKept => 'Текущий файл сохранен';

  @override
  String get done => 'Готово';

  @override
  String get startAndEndDatesMandatory => 'Даты начала и окончания обязательны';

  @override
  String get revisionRequested => 'Требуются изменения';

  @override
  String get statusActive => 'Активно';

  @override
  String get statusPending => 'На проверке';

  @override
  String get statusDeclined => 'Отклонено';

  @override
  String get statusExpired => 'Истекло';

  @override
  String get statusNegotiating => 'Переговоры';

  @override
  String get tenantPaysLandlord => 'Арендатор платит собственнику';

  @override
  String get tenantPaysUtility => 'Арендатор платит напрямую службам';

  @override
  String get includedInRent => 'Включено в аренду';

  @override
  String get changesAccepted => 'Изменения приняты';

  @override
  String get changesDeclined => 'Изменения отклонены';

  @override
  String get contractChangeProposal => 'Предложение об изменении договора';

  @override
  String get cancelProposal => 'Отозвать предложение';

  @override
  String get viewInvoice => 'Посмотреть счет';

  @override
  String get paymentResponsibility => 'КТО ОПЛАЧИВАЕТ РАСХОДЫ';

  @override
  String get tenantPaysDirectlyToUtility => 'Арендатор платит напрямую службам';

  @override
  String get tenantPaysToLandlord =>
      'Арендатор платит собственнику (вместе с арендой)';

  @override
  String get selectPaymentReceiverWarning =>
      'Пожалуйста, выберите, кому оплачивается этот счет.';

  @override
  String progressSummary(int completed, int total, int sent) {
    return '$completed / $total оплачено • $sent отправлено';
  }

  @override
  String get maintenance => 'Ремонт / Проблемы';

  @override
  String get issues => 'Проблемы';

  @override
  String get newRequest => 'Новая заявка';

  @override
  String get reportIssue => 'Сообщить о проблеме';

  @override
  String get issueTitle => 'Заголовок';

  @override
  String get issueDescription => 'Описание';

  @override
  String get issueCategory => 'Kатегория';

  @override
  String get issuePriority => 'Приоритет';

  @override
  String get statusInvestigating => 'В процессе';

  @override
  String get statusResolved => 'Решено';

  @override
  String get priorityNormal => 'Обычный';

  @override
  String get priorityUrgent => 'Срочный';

  @override
  String get categoryPlumbing => 'Сантехника';

  @override
  String get categoryElectrical => 'Электрика';

  @override
  String get categoryHeating => 'Отопление';

  @override
  String get categoryInternet => 'Интернет';

  @override
  String get categoryOther => 'Другое';

  @override
  String get noIssuesTitle => 'Нет активных проблем';

  @override
  String get noIssuesMessage =>
      'Всё отлично! Для этого жилья не зарегистрировано проблем.';

  @override
  String get updateStatus => 'Изменить статус';

  @override
  String get issueDetails => 'Описание проблемы';

  @override
  String logMaintenanceCreated(String title) {
    return 'Зарегистрирована новая проблема: $title';
  }

  @override
  String logMaintenanceStatusUpdated(String status) {
    return 'Статус поправки изменен на $status';
  }

  @override
  String get logMaintenanceReopened => 'Проблема открыта повторно';

  @override
  String get logMaintenanceMessageAdded => 'Добавлено сообщение по проблеме';

  @override
  String get notifications => 'Уведомления';

  @override
  String get markAllAsRead => 'Отметить все как прочитанные';

  @override
  String get noNotifications => 'Нет новых уведомлений';

  @override
  String get documents => 'Документы';

  @override
  String get mainContract => 'Основной договор';

  @override
  String get addDocument => 'Добавить документ';

  @override
  String get enterDocumentName => 'Название документа';

  @override
  String get noDocumentsYet => 'Нет загруженных документов';

  @override
  String get additionalDocuments => 'Дополнительные документы';

  @override
  String get deleteDocument => 'Удалить документ';

  @override
  String get deleteDocumentConfirm =>
      'Вы уверены, что хотите удалить этот документ?';

  @override
  String get uploadMainContract => 'Прикрепить договор';

  @override
  String get manageDocuments => 'Управление документами';

  @override
  String get monthlyCollected => 'Получено';

  @override
  String get totalRentShort => 'Аренда';

  @override
  String get delays => 'Задержки';

  @override
  String get vacant => 'Свободно';

  @override
  String get overdueReceivables => 'Неоплаченные';

  @override
  String get collectedByType => 'Виды оплат';

  @override
  String propertiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count объектов',
      few: '$count объекта',
      one: '$count объект',
    );
    return '$_temp0';
  }

  @override
  String get hasDebt => 'Есть долг';

  @override
  String get paymentAwaitingApproval => 'Ожидает проверки';

  @override
  String get rent => 'Аренда';

  @override
  String get bills => 'Счета';

  @override
  String get waiting => 'Ожидается';

  @override
  String get debtLabel => 'Долг';

  @override
  String get totalDebt => 'Общий долг';

  @override
  String get paidLabel => 'Оплачено';

  @override
  String get enterBill => 'Ввести счет';

  @override
  String get addContractAndTenant => 'Добавить договор и жильца';

  @override
  String get approve => 'Подтвердить';

  @override
  String get reject => 'Отклонить';

  @override
  String get confirmApprovePaymentTitle => 'Подтвердить оплату';

  @override
  String get confirmApprovePaymentMessage =>
      'Вы уверены, что хотите подтвердить этот платеж?';

  @override
  String get confirmRejectPaymentTitle => 'Отклонить оплату';

  @override
  String get confirmRejectPaymentMessage =>
      'Вы уверены, что хотите отклонить это уведомление об оплате и попросить жильца отправить его заново?';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get terminateContract => 'Расторгнуть договор';

  @override
  String get terminationDate => 'Дата расторжения';

  @override
  String get confirmTerminationTitle => 'Расторгнуть договор?';

  @override
  String get confirmTerminationMessage =>
      'Вы уверены, что хотите отправить запрос на расторжение договора на выбранную дату?';

  @override
  String get terminationRequestSent =>
      'Запрос на расторжение договора отправлен.';

  @override
  String get statusInactive => 'Завершен';

  @override
  String get terminationRequested => 'Расторжение на рассмотрении';

  @override
  String get approveTermination => 'Подтвердить расторжение';

  @override
  String get declineTermination => 'Отклонить расторжение';

  @override
  String contractTerminatedOn(Object date) {
    return 'Договор расторгнут: $date';
  }

  @override
  String contractWillEndOn(String date) {
    return 'Договор закончится: $date';
  }

  @override
  String get dispute => 'Спор';

  @override
  String get disputeReason => 'Причина спора';

  @override
  String get disputeReasonHint => 'Опишите причину спора...';

  @override
  String get disputedHeader => 'ОСПОРЕНО';

  @override
  String logRentDisputed(String month, String reason) {
    return 'Арендатор оспорил платеж за $month: $reason';
  }

  @override
  String get confirmDisputeTitle => 'Оспорить платеж';

  @override
  String get disputeSentSuccess => 'Ваш спор по оплате отправлен собственнику.';

  @override
  String get takeAction => 'Выбрать действие';

  @override
  String get ownerNote => 'Заметка собственника';

  @override
  String get explanationOptional => 'Комментарий (необязательно)';

  @override
  String get explanationHint => 'Например: Проверил счетчик...';

  @override
  String get units => 'Единицы';

  @override
  String get tenantsLabel => 'Жильцы';

  @override
  String get portfolioManagement => 'Мои объекты';

  @override
  String get paymentRequests => 'Запросы и платежи';

  @override
  String get profileSettings => 'Настройки профиля';

  @override
  String get confirmSignOutMessage =>
      'Вы уверены, что хотите выйти из аккаунта?';

  @override
  String errorWithDetails(String error) {
    return 'Ошибка: $error';
  }

  @override
  String syncError(String error) {
    return 'Ошибка синхронизации: $error';
  }

  @override
  String get acceptTermsWarning =>
      'Пожалуйста, примите условия использования для продолжения.';

  @override
  String get maintenanceRequestSuccess => 'Проблема успешно зарегистрирована.';

  @override
  String get ok => 'ОК';

  @override
  String get orLabel => 'ИЛИ';

  @override
  String errorUploadingPhoto(String error) {
    return 'Ошибка загрузки фото: $error';
  }

  @override
  String errorUpdatingStatus(String error) {
    return 'Ошибка обновления статуса: $error';
  }

  @override
  String errorReopeningRequest(String error) {
    return 'Ошибка открытия запроса: $error';
  }

  @override
  String errorOpeningDetails(String error) {
    return 'Не удалось открыть детали: $error';
  }

  @override
  String get nextPayment => 'Следующий платеж';

  @override
  String get payNow => 'Сообщить об оплате';

  @override
  String get upcomingLabel => 'Предстоящие';

  @override
  String get joinPropertyInvitation =>
      'Приглашение присоединиться к недвижимости';

  @override
  String get feedbackSent => 'Спасибо за ваш отзыв!';

  @override
  String get rentalProposal => 'Предложение об аренде';

  @override
  String get reviewContractTerms =>
      'Пожалуйста, ознакомьтесь с условиями договора.';

  @override
  String get expenseDistribution => 'Распределение расходов';

  @override
  String get yourNote => 'Ваш комментарий:';

  @override
  String get backToDashboard => 'На главную';

  @override
  String get propertyDetailsHeader => 'ДЕТАЛИ ОБЪЕКТА';

  @override
  String get defaultLeaseTermsHeader => 'УСЛОВИЯ АРЕНДЫ ПО УМОЛЧАНИЮ';

  @override
  String get proposeRevision => 'Предложить изменения';

  @override
  String get revisionTermsQuestion =>
      'Какие условия вы хотите изменить? (Аренда, день оплаты, счета...)';

  @override
  String get enterNotesHint => 'Введите ваш комментарий здесь...';

  @override
  String get submit => 'Отправить';

  @override
  String invitedToJoinProperty(String property) {
    return 'Вас пригласили заселиться в $property.';
  }

  @override
  String get waitingForLandlord => 'Ожидание ответа собственника...';

  @override
  String get day => 'День';

  @override
  String get notSelected => 'Не выбрано';

  @override
  String get acceptTermsAndDistribution =>
      'Я принимаю условия договора и распределение счетов.';

  @override
  String get datesMandatory => 'Даты начала и окончания обязательны';

  @override
  String get partiesHeader => 'СТОРОНЫ';

  @override
  String get leaseLockedWarning =>
      'Для этого жильца будут действовать согласованные условия договора (аренда, даты, распределение расходов).';

  @override
  String get rentPaymentHeader => 'АРЕНДА И ОПЛАТА';

  @override
  String get loadingPlaceholder => 'Загрузка...';

  @override
  String get photos => 'Фото';

  @override
  String get add => 'Добавить';

  @override
  String get paymentHistory => 'История платежей';

  @override
  String get viewAll => 'Посмотреть все';

  @override
  String get ended => 'Завершено';

  @override
  String plannedEnd(String date) {
    return 'Планируемое окончание: $date';
  }

  @override
  String get yourApartment => 'Ваша квартира';

  @override
  String get commentHint => 'Добавить комментарий...';

  @override
  String get issueResolvedStatus => 'Проблема отмечена как решенная.';

  @override
  String get reopenIssue => 'Проблема не решена (Открыть заново)';

  @override
  String get deleteRequest => 'Удалить запрос';

  @override
  String get terminationApproved => 'Расторжение подтверждено';

  @override
  String get paymentDeclaredHand => 'Платеж объявлен как переданный лично.';

  @override
  String get fileUnreadable => 'Не удалось прочитать файл.';

  @override
  String paymentDeclaredSuccess(String title) {
    return 'Уведомление об оплате $title отправлено.';
  }

  @override
  String get setAmountUploadInvoice => 'Введите данные счета';

  @override
  String get yourMessage => 'Ваше сообщение:';

  @override
  String get revisionRequestLabel => 'Запрос на изменения:';

  @override
  String get noActivityLogs => 'Логов активности пока нет';

  @override
  String get landlordProposedChanges =>
      'Собственник предложил изменения в договоре. Нажмите для просмотра.';

  @override
  String get tenantProposedChanges =>
      'Жилец предложил изменения в договоре. Нажмите для просмотра.';

  @override
  String dueOn(String date) {
    return 'Оплатить до $date';
  }

  @override
  String get item => 'предмет';

  @override
  String get items => 'предметов';

  @override
  String get waitingForOtherParty => 'Ожидание подтверждения второй стороны...';

  @override
  String get awaitingApproval => 'Ожидание подтверждения...';

  @override
  String get contract => 'Договор';

  @override
  String paidOn(Object date) {
    return 'Оплачено $date';
  }

  @override
  String get cannotInviteSelf => 'Вы не можете пригласить сами себя.';

  @override
  String get paywallTitle => 'Stanomer Premium';

  @override
  String get paywallSubtitle => 'Управляйте объектами без ограничений.';

  @override
  String get unlimitedProperties => 'Неограниченное управление недвижимостью';

  @override
  String get detailedReporting => 'Быстрая и подробная отчетность';

  @override
  String get extraStorage => 'Больше места для хранения';

  @override
  String get pdfContracts => 'Создание PDF-договоров (Скоро)';

  @override
  String get automatedRenewal => 'Автоматический расчет аренды (Скоро)';

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get limitReachedTitle => 'Вы достигли бесплатного лимита';

  @override
  String get limitReachedSubtitle =>
      'Перейдите на Stanomer Premium для управления несколькими объектами.';

  @override
  String get optionsLoadFailed => 'Не удалось загрузить варианты подписки.';

  @override
  String get manageSubscription => 'Управление подпиской';

  @override
  String get premiumMobileOnly => 'Требуется мобильное приложение';

  @override
  String get premiumMobileOnlyDesc =>
      'Подписку Stanomer Premium можно приобрести только в мобильном приложении. Скачайте его по ссылкам ниже.';

  @override
  String get downloadOnAppStore => 'Загрузить в App Store';

  @override
  String get downloadOnPlayStore => 'Доступно в Google Play';

  @override
  String get premiumFeatures => 'Премиум-функции';

  @override
  String get premiumFeature1 => 'Неограниченное управление';

  @override
  String get premiumFeature2 => 'Расширенные отчеты';

  @override
  String get premiumFeature3 => 'Приоритетная поддержка';

  @override
  String get premiumFeature4 => 'Доступ на всех платформах';

  @override
  String get termsOfService => 'Условия обслуживания';

  @override
  String get termsOfServiceContent =>
      'Stanomer – Пользовательское соглашение и условия использования\nПоследнее обновление: 23 апреля 2026\n\n1. Введение\nНастоящее Пользовательское соглашение («Соглашение») регулирует отношения между Вами («Пользователь») и приложением Stanomer. Устанавливая или используя приложение, Вы соглашаетесь с условиями настоящего Соглашения.\n\n2. Условия Apple и Google\nApple App Store: Данное Соглашение заключено исключительно между Пользователем и Stanomer. Настоящее Соглашение включает Стандартное лицензионное соглашение с конечным пользователем Apple (Standard EULA) посредством ссылки: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/\n\nGoogle Play Store: Данное Соглашение заключено исключительно между Пользователем и Stanomer.\n\nВы подтверждаете, что Apple и Google не несут никаких обязательств по техническому обслуживанию и поддержке приложения.\n\n3. Подписка и оплата\nОплата: Оплата списывается с Вашего аккаунта iTunes или Google Play после подтверждения покупки.\n\nПродление: Подписка продлевается автоматически, если автопродление не отключено как минимум за 24 часа до окончания текущего периода.\n\nУправление: Вы можете управлять подписками или отключить автопродление в настройках аккаунта после совершения покупки.\n\n4. Контент пользователя и правила поведения\nВы несете полную ответственность за вводимые Вами данные (суммы аренды, отчеты о неисправностях, договоры).\n\nЗапрещено загружать незаконный, оскорбительный или нарушающий чьи-либо права контент.\n\nStanomer оставляет за собой право удалить любой контент, нарушающий законы Республики Сербии или условия настоящего Соглашения.\n\n5. Конфиденциальность и защита данных (ZZPL, GDPR, KVKK)\nЗакон Сербии (ZZPL): Закон о защите персональных данных.\n\nGDPR: Общий регламент по защите данных (ЕС).\n\nKVKK: Закон о защите персональных данных (Турция).\n\nВаши данные защищены в соответствии с международными стандартами конфиденциальности независимо от Вашего местонахождения.\n\n6. Ограничение ответственности\nStanomer предоставляет платформу для управления арендой и не является стороной договоров аренды между собственниками и жильцами. Мы не несем ответственности за споры между пользователями или за транзакции, совершенные вне платформы.\n\n7. Прекращение действия соглашения\nСоглашение действует до тех пор, пока не будет расторгнуто Вами или Stanomer. Ваши права по данной лицензии автоматически аннулируются в случае нарушения любого из условий.';

  @override
  String get support_title => 'Поддержка';

  @override
  String get support_desc =>
      'Свяжитесь с нами, если у вас возникли вопросы или есть отзыв.';

  @override
  String get subject => 'Тема';

  @override
  String get category => 'Категория';

  @override
  String get message => 'Сообщение';

  @override
  String get support => 'Поддержка';

  @override
  String get bug => 'Ошибка';

  @override
  String get other => 'Другое';

  @override
  String get messageSent => 'Сообщение отправлено!';

  @override
  String get errorSendingMessage =>
      'Не удалось отправить сообщение. Пожалуйста, попробуйте еще раз.';

  @override
  String get requiredField => 'Это поле обязательно';

  @override
  String get invalidEmail => 'Неверный адрес эл. почты';

  @override
  String get offlineMessage =>
      'Вы сейчас не в сети. Данные будут синхронизированы при подключении.';

  @override
  String get retry => 'ПОВТОРИТЬ';

  @override
  String get zzplConsentTitle => 'Защита персональных данных (ZZPL)';

  @override
  String get zzplAgreeAndContinue => 'Принять и продолжить';

  @override
  String get share => 'Поделиться';

  @override
  String get optional => 'Необязательно';

  @override
  String get sentInvitation => 'Приглашение отправлено';

  @override
  String invitedOn(String date) {
    return 'Приглашен(а) $date';
  }

  @override
  String get noEmailProvided => 'Почта не указана';

  @override
  String get invoiceLocalOnlyDesc =>
      'Файл сохранен только на этом устройстве. Вы можете включить облачное резервное копирование в настройках.';

  @override
  String get invoiceCloudSecureDesc =>
      'Файл надежно сохранен в облаке. Доступ есть только у вас и жильца.';

  @override
  String get invoiceUploadLimitDesc => 'JPEG, PNG или PDF · макс. 10 МБ';

  @override
  String get billMissingLocalDesc =>
      'Файл сохранен локально на другом устройстве. Включите облачное копирование, чтобы открыть его здесь.';

  @override
  String get documentMissingLocalDesc =>
      'Документ сохранен локально на другом устройстве. Включите облачное копирование, чтобы открыть его здесь.';

  @override
  String get cannotOpenDocument => 'Не удалось открыть документ';
}
