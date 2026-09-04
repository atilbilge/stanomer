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
  String get saveChanges => 'Сохранить изменения';

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
  String get myProperty => 'Мой объект';

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
  String get waitingForAgency => 'Ожидание ответа агентства...';

  @override
  String get waitingForAgencyApproval => 'Ожидает подтверждения агентства';

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
  String get uploadReceipt => 'Загрузить квитанцию об оплате';

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
  String get viewReceipt => 'Посмотреть квитанцию';

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
  String get statusPending => 'В ожидании';

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
  String get categoryAppliance => 'Бытовая техника';

  @override
  String get categoryStructural => 'Конструкция и здание';

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
  String get propertyDetailsHeader => 'ИНФОРМАЦИЯ ОБ ОБЪЕКТЕ';

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
  String get invalidEmail => 'Введите корректный e-mail';

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

  @override
  String get agencyAccount => 'Аккаунт агентства';

  @override
  String get managedProperties => 'Управляемая недвижимость';

  @override
  String get paymentApprovalQueue => 'Очередь подтверждения платежей';

  @override
  String get noPendingPaymentApprovals =>
      'Нет платежей, ожидающих подтверждения';

  @override
  String get noManagedPropertiesYet => 'Пока нет управляемых объектов';

  @override
  String get occupied => 'Занято';

  @override
  String dueDateShort(String date) {
    return 'Срок: $date';
  }

  @override
  String get payment => 'Платеж';

  @override
  String get insightPendingApprovalsTitle => 'Ожидающие подтверждения';

  @override
  String get insightPendingApprovalsDesc =>
      'У вас есть объекты, где арендодатель или арендаторы еще не приняли приглашение.';

  @override
  String get insightPendingApprovalsAction => 'Показать объекты';

  @override
  String get insightWithoutContractsTitle => 'Объекты без контрактов';

  @override
  String get insightWithoutContractsDesc =>
      'У вас есть зарегистрированные в системе объекты, к которым еще не привязан контракт.';

  @override
  String get insightWithoutContractsAction => 'Показать объекты';

  @override
  String get insightExpiredContractsTitle => 'Истекшие контракты';

  @override
  String get insightExpiredContractsDesc =>
      'У вас есть объекты с истекшими и не продленными контрактами. Пожалуйста, примите меры.';

  @override
  String get insightExpiredContractsAction => 'Показать объекты';

  @override
  String get insightExpiringContractsTitle => 'Истекающие контракты';

  @override
  String get insightExpiringContractsDesc =>
      'У вас есть объекты, до окончания текущего контракта которых осталось менее одного месяца.';

  @override
  String get insightExpiringContractsAction => 'Показать объекты';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabFinance => 'Финансы';

  @override
  String get tabRequests => 'Заявки';

  @override
  String get tabPortfolio => 'Портфель';

  @override
  String get agencyAddProperty => 'Добавить объект';

  @override
  String get searchAndFilterPanel => 'Поиск и подробные фильтры';

  @override
  String get searchPlaceholder =>
      'Поиск по владельцу, арендатору, городу или объекту...';

  @override
  String filterAppliedLabel(String title) {
    return 'Применен фильтр: $title';
  }

  @override
  String get noPropertiesMatchingFilter =>
      'Нет объектов, соответствующих фильтру';

  @override
  String get groupNone => 'Без группировки';

  @override
  String get groupByLandlord => 'Группировка: Владелец';

  @override
  String get groupByCity => 'Группировка: Город';

  @override
  String get groupByStatus => 'Группировка: Статус';

  @override
  String get groupByDebtConsent => 'Группировка: Долг / Согласие';

  @override
  String get sortByNewest => 'Сортировка: Сначала новые';

  @override
  String get sortByOldest => 'Сортировка: Сначала старые';

  @override
  String get sortByDebt => 'Сортировка: Сначала должники';

  @override
  String get sortByRentDesc => 'Сортировка: Аренда (по убыванию)';

  @override
  String get sortByRentAsc => 'Сортировка: Аренда (по возрастанию)';

  @override
  String get sortByAmountDesc => 'Сортировка: Сумма (по убыванию)';

  @override
  String get sortByAmountAsc => 'Сортировка: Сумма (по возрастанию)';

  @override
  String get sortByNameAsc => 'Сортировка: Название А-Я';

  @override
  String get sortByCityAsc => 'Сортировка: Город А-Я';

  @override
  String get sortByLandlordAsc => 'Сортировка: Владелец А-Я';

  @override
  String get viewModeTable => 'Таблица';

  @override
  String get viewModeGrid => 'Карточки';

  @override
  String get statusLabel => 'СТАТУС';

  @override
  String get statusOverdue => 'Просрочено';

  @override
  String get statusClean => 'В норме';

  @override
  String get colPropertyAndType => 'ОБЪЕКТ И ТИП';

  @override
  String get colDueDate => 'СРОК';

  @override
  String get colAmount => 'СУММА';

  @override
  String get colAction => 'ДЕЙСТВИЕ';

  @override
  String get unenteredBillsTitle => 'Невнесенные счета';

  @override
  String get cashBadge => 'Наличные';

  @override
  String get filterRent => 'Аренда';

  @override
  String get filterBills => 'Счета';

  @override
  String get filterDeposit => 'Депозит';

  @override
  String get filterDues => 'Коммунальные';

  @override
  String get allPropertiesGroup => 'Все объекты';

  @override
  String get groupLandlordPendingInvite => 'Владельцы, ожидающие приглашения';

  @override
  String get groupUnspecifiedCity => 'Город не указан';

  @override
  String get groupStatusOccupied => 'Сданные объекты';

  @override
  String get groupStatusVacant => 'Свободные объекты';

  @override
  String get groupStatusLandlordPending => 'Ожидает владельца';

  @override
  String get groupDebtPending => 'Объекты с задолженностью';

  @override
  String get groupConsentPending => 'Ожидают согласия / подтверждения';

  @override
  String get groupActiveClean => 'Объекты без задолженностей';

  @override
  String filterAllCount(int count) {
    return 'Все ($count)';
  }

  @override
  String filterHasDebtCount(int count) {
    return '⚠️ С долгом ($count)';
  }

  @override
  String filterOccupiedCount(int count) {
    return '🟢 Занято ($count)';
  }

  @override
  String filterVacantCount(int count) {
    return '🟡 Свободно ($count)';
  }

  @override
  String get filterActiveLabel => 'Фильтр активен ✓';

  @override
  String get financeAndPaymentsHeader => 'Финансы и платежи';

  @override
  String get financialSummaryTitle => 'Финансовая сводка';

  @override
  String pendingPaymentsSummary(int count) {
    return 'Ожидает подтверждения платежей: $count';
  }

  @override
  String get financePlaceholderDesc =>
      'Финансовые графики, учет аренды и история платежей будут отображаться здесь.';

  @override
  String get maintenanceRequestsHeader => 'Заявки на ремонт и обслуживание';

  @override
  String get requestManagementTitle => 'Управление заявками';

  @override
  String get requestsPlaceholderDesc =>
      'Заявки на ремонт и обслуживание от арендаторов и владельцев будут управляться в этой вкладке.';

  @override
  String get noOpenRequestsYet => 'Открытых заявок пока нет';

  @override
  String get actionableInsightsHeader => 'Уведомления к действию';

  @override
  String get inviteTenantOrAddContract =>
      'Пригласить арендатора / Добавить договор';

  @override
  String get ownershipQrOrLink => 'QR / Ссылка на владение';

  @override
  String get changeLandlord => 'Сменить владельца';

  @override
  String get pendingDebtWarning =>
      'Задолженность ожидает подтверждения агентства или оплаты арендатором';

  @override
  String get landlordLabel => 'Владелец: ';

  @override
  String get invitePending => 'Ожидает приглашения';

  @override
  String get tenantLabel => 'Арендатор: ';

  @override
  String get vacantLabel => 'Свободно';

  @override
  String get latestContractNone => 'Последний договор: Отсутствует';

  @override
  String get unlimited => 'Бессрочно';

  @override
  String contractDateRange(String dates) {
    return 'Договор: $dates';
  }

  @override
  String get cashPayment => 'Оплата наличными';

  @override
  String get changeLandlordDialogTitle =>
      'Сменить владельца / Отправить приглашение';

  @override
  String get changeLandlordDialogDesc =>
      'Введите контактные данные нового владельца. Текущие права будут сброшены и создан новый QR/ссылка.';

  @override
  String get phone => 'Номер телефона';

  @override
  String get error => 'Ошибка';

  @override
  String get changeAndGenerateQr => 'Сменить и создать QR';

  @override
  String get financePendingApprovals => 'Ожидают подтверждения';

  @override
  String get financeOverduePayments => 'Просроченные долги';

  @override
  String get financePaidThisMonth => 'Оплачено в этом месяце';

  @override
  String get financeRentCollected => 'Арендная плата от арендаторов';

  @override
  String get financeBillsCollected => 'Счета от арендаторов';

  @override
  String get financeBillsToInstitutions => 'Счета оплачены организациям';

  @override
  String get financeBillsToInstitutionsTooltip =>
      'Счета, собранные с арендаторов, считаются оплаченными организациям.';

  @override
  String get financeMaintenancePaid => 'Оплаченные расходы на обслуживание';

  @override
  String get financeMaintenanceOwedToAgency => 'Задолженность агентству';

  @override
  String get financeMaintenanceOwedToAgencyTooltip =>
      'Счета, собранные с арендаторов, считаются оплаченными агентству.';

  @override
  String get periodThisMonth => 'Этот месяц';

  @override
  String get periodLastMonth => 'Прошлый месяц';

  @override
  String get periodThisYear => 'Этот год';

  @override
  String get periodLastYear => 'Прошлый год';

  @override
  String get periodAllTime => 'За всё время';

  @override
  String get periodCustom => 'Произвольный';

  @override
  String get financeUpcoming7Days => 'Предстоящие (7 дней)';

  @override
  String get tabPendingQueue => 'Очередь подтверждений';

  @override
  String get tabOverdueList => 'Должники';

  @override
  String get tabAllHistory => 'История платежей';

  @override
  String get approvePayment => 'Подтвердить';

  @override
  String get rejectPayment => 'Отклонить';

  @override
  String get markAsCashPaid => 'Отметить оплаченным наличными';

  @override
  String get sendReminder => 'Отправить напоминание';

  @override
  String daysOverdue(int count) {
    return 'Просрочено на $count дн.';
  }

  @override
  String get noFinanceRecords => 'В этой категории нет записей';

  @override
  String get reminderMessageCopied => 'Сообщение-напоминание скопировано';

  @override
  String get tenantNoPropertyTitle => 'Вы ещё не прикреплены к объекту.';

  @override
  String get tenantNoPropertyTooltip => 'Вы ещё не прикреплены к объекту.';

  @override
  String get tenantNoPropertyMaintenanceTooltip =>
      'Вы ещё не прикреплены к объекту.\nЧтобы создать заявку на техобслуживание, сначала присоединитесь к объекту.';

  @override
  String get joinWithQrCode => 'Присоединиться по КР-коду / коду приглашения';

  @override
  String get agencyPropertyTakeoverQr => 'Принять объект агентства по QR-коду';

  @override
  String welcomeUser(String userName) {
    return 'Добро пожаловать, $userName 👋';
  }

  @override
  String overduePaymentReminderMessage(
    String tenantName,
    String propertyName,
    String amount,
    String currency,
  ) {
    return 'Уважаемый(ая) $tenantName, ваш платеж в размере $amount $currency за объект $propertyName просрочен. Пожалуйста, произведите оплату и загрузите квитанцию.';
  }

  @override
  String get heroHeadline =>
      'Управляйте арендной недвижимостью из одной панели';

  @override
  String get heroSubtitle =>
      'Отслеживание жильцов, учет платежей и детали объектов — всё в одном месте.';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get copy => 'Копировать';

  @override
  String get showLandlordInviteQrOrLink =>
      'Показать QR-код / ссылку приглашения';

  @override
  String get showLandlordInviteQrOrLinkClaimed => 'QR-код / ссылка приглашения';

  @override
  String get landlordOwnershipInviteTitle =>
      'Приглашение на владение недвижимостью';

  @override
  String becomeLandlordTitle(String propertyName) {
    return 'Станьте арендодателем объекта $propertyName';
  }

  @override
  String get landlordInviteAcceptDesc =>
      'Подтвердите приглашение, чтобы стать арендодателем и управлять этим объектом под управлением агентства.';

  @override
  String get acceptAsLandlord => 'Принять как арендодатель';

  @override
  String get landlordAcceptedInviteTitle => 'Арендодатель принял приглашение!';

  @override
  String landlordOwnershipTransferredDesc(String propertyName) {
    return 'Право собственности на $propertyName успешно передано.';
  }

  @override
  String get landlordShareQrInstruction =>
      'Попросите арендодателя отсканировать этот QR-код или отправьте ему ссылку.';

  @override
  String get ownershipLinkCopied => 'Ссылка на владение скопирована!';

  @override
  String landlordShareMessage(
    String landlordName,
    String propertyName,
    String inviteUrl,
  ) {
    return 'Здравствуйте $landlordName, перейдите по этой ссылке, чтобы принять управление объектом \"$propertyName\" на Stanomer:\n$inviteUrl';
  }

  @override
  String get joinHomeTitle => 'Присоединиться к дому';

  @override
  String get joinHomeSubtitle =>
      'Отсканируйте QR-код или введите ссылку/код приглашения.';

  @override
  String get closeCamera => 'Закрыть камеру';

  @override
  String get scanQrCodeBtn => 'Сканировать QR-код';

  @override
  String get inviteLinkOrTokenLabel => 'Ссылка приглашения или токен-код';

  @override
  String get inviteLinkOrTokenHint => 'https://.../invite?token=... или код';

  @override
  String get paste => 'Вставить';

  @override
  String get joinAndReview => 'Присоединиться и проверить';

  @override
  String get invalidInviteCodeOrLink =>
      'Пожалуйста, введите действительную ссылку или код приглашения.';

  @override
  String get landlordOwnershipTransferredSuccess =>
      'Поздравляем! Права владельца объекта успешно переданы на ваш аккаунт.';

  @override
  String get landlordOwnershipInviteInvalid =>
      'Приглашение на владение недействительно, истекло или уже принято.';

  @override
  String get statusApproved => 'Подтверждено';

  @override
  String get referringAgency => 'Рекомендующее Агентство';

  @override
  String get noReferringAgency => 'Нет Рекомендующего Агентства';

  @override
  String get noReferringAgencyDesc =>
      'Если вас рекомендовало агентство недвижимости, отсканируйте QR-код агентства для привязки аккаунта.';

  @override
  String get scanAgencyReferralQrBtn => 'Сканировать Referral QR-код Агентства';

  @override
  String get referralCodeLabel => 'Реферальный Код';

  @override
  String get detailedEntry => 'Расширенная информация';

  @override
  String get detailedEntrySubtitle =>
      'Все характеристики объекта, структурные метрики и детали.';

  @override
  String get propertyAndLocationInfo => 'Информация об объекте и локации';

  @override
  String get propertyTypeLabel => 'Тип объекта';

  @override
  String get propertyTypeApartment => 'Квартира';

  @override
  String get propertyTypeHouse => 'Частный дом';

  @override
  String get propertyTypeCommercial => 'Коммерческая';

  @override
  String get propertyTypeGarage => 'Гараж';

  @override
  String get unitNumberLabel => 'Номер квартиры / помещения';

  @override
  String get unitNumberHint => 'Напр: 4 или 12B';

  @override
  String get addressDetailedHint => 'Введите город, район или улицу...';

  @override
  String get structuralAndFinancialMetrics =>
      'Структурные и финансовые метрики';

  @override
  String get roomCountLabel => 'Количество комнат';

  @override
  String get areaSqmLabel => 'Площадь (м²)';

  @override
  String get floorLevelLabel => 'Этаж';

  @override
  String get totalFloorsLabel => 'Всего этажей в здании';

  @override
  String get equipmentAndHeatingStandards => 'Стандарты оснащения и отопления';

  @override
  String get furnishingLabel => 'Меблировка';

  @override
  String get furnishingFurnished => 'С мебелью';

  @override
  String get furnishingFurnishedDesc =>
      'Полностью меблирована и укомплектована техникой';

  @override
  String get furnishingSemi => 'Частично с мебелью';

  @override
  String get furnishingSemiDesc => 'Только кухня и ванная комната';

  @override
  String get furnishingUnfurnished => 'Без мебели';

  @override
  String get furnishingUnfurnishedDesc => 'Пустая квартира';

  @override
  String get heatingTypeLabel => 'Тип отопления';

  @override
  String get heatingCg => 'Центральное отопление (CG)';

  @override
  String get heatingEg => 'Индивидуальное электроотопление (EG)';

  @override
  String get heatingGas => 'Газовое отопление / Котел';

  @override
  String get heatingUnderfloor => 'Теплый пол';

  @override
  String get heatingTa => 'Кондиционер / ТА печь / Другое';

  @override
  String get featuredAmenitiesLabel => 'Дополнительные удобства';

  @override
  String get amenityPets => 'Разрешены домашние животные';

  @override
  String get amenityElevator => 'Лифт';

  @override
  String get amenityBalcony => 'Терраса / Балкон / Лоджия';

  @override
  String get amenityParking => 'Гараж / Парковочное место';

  @override
  String get amenityStorage => 'Подвал / Кладовая';

  @override
  String get extendedDescriptionLabel => 'Описание объекта и примечания';

  @override
  String get extendedDescriptionHint =>
      'Укажите информацию о транспорте, здании, планировке и условиях...';

  @override
  String get clearFormBtn => 'Очистить форму';

  @override
  String get floorSuteren => 'Цокольный этаж';

  @override
  String get floorPrizemlje => 'Первый этаж';

  @override
  String get floorVisokoPrizemlje => 'Высокий 1-й этаж';

  @override
  String floorNth(String floor) {
    return '$floor-й этаж';
  }

  @override
  String get floorPotkrovlje => 'Мансарда';

  @override
  String get floorOther => 'Другой этаж';

  @override
  String get statusOpen => 'Открыто';

  @override
  String get statusInProgress => 'Мастер отправлен';

  @override
  String get statusClosed => 'Закрыта';

  @override
  String get statusCancelled => 'Отменена';

  @override
  String get financialDetails => 'Финансовые детали';

  @override
  String get financialStatusPendingReview => 'На рассмотрении';

  @override
  String get financialStatusPendingAgencyApproval =>
      'Ожидает подтверждения агентства';

  @override
  String get financialStatusPendingOppositeApproval =>
      'Ожидает подтверждения взаимозачета';

  @override
  String get financialStatusPendingPayment => 'Ожидает оплаты';

  @override
  String get financialStatusPaid => 'Оплачено';

  @override
  String get financialStatusRejected => 'Отклонено';

  @override
  String get rejectionReasonRequired =>
      'Пожалуйста, укажите причину отклонения';

  @override
  String get payerTenant => 'Арендатор';

  @override
  String get payerLandlord => 'Владелец';

  @override
  String get payerTenantPaidOrWillPay => 'Арендатор оплатил / оплатит';

  @override
  String get payerLandlordWillCover => 'Владелец покроет';

  @override
  String get unassigned => 'Не указано';

  @override
  String get noFinancialRecordTitle => 'Нет финансовых записей';

  @override
  String get noFinancialRecordDesc =>
      'По этой заявке на ремонт еще не добавлены расходы или чеки.';

  @override
  String get iPaidSubmitReceipt => 'Я оплатил (Прикрепить чек)';

  @override
  String get resubmitExpenseIPaid => 'Повторно заявить расход (Я оплатил)';

  @override
  String get addCostInvoice => 'Добавить расход / счет';

  @override
  String get costPayerLabel => 'Ответственный за оплату';

  @override
  String get receiptInvoiceDocument => 'Чек / Счет';

  @override
  String get clickToViewDocument => 'Нажмите для просмотра';

  @override
  String get agencyExpenseApproval => 'Одобрение агентства';

  @override
  String get landlordExpenseApproval => 'Одобрение владельца';

  @override
  String get tenantExpenseApproval => 'Одобрение арендатора';

  @override
  String get expenseApprovedSuccess => 'Расход успешно подтвержден.';

  @override
  String get expenseRejectedSuccess => 'Заявка на расход отклонена.';

  @override
  String get rejectExpenseTitle => 'Отклонить расход';

  @override
  String get rejectExpenseConfirm =>
      'Вы уверены, что хотите отклонить эту заявку на расход?';

  @override
  String get rejectionReasonOptional => 'Причина отказа (необязательно)';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get descriptionOrNoteOptional =>
      'Описание / Примечание (необязательно)';

  @override
  String get enterExpenseNoteHint =>
      'напр. Заменен смеситель, включая работу мастера';

  @override
  String get editFinancialDetails => 'Редактировать финансовые данные';

  @override
  String get propertyInfo => 'Информация об объекте';

  @override
  String get coveredByLandlord => 'Покрыто владельцем';

  @override
  String get coveredByTenant => 'Покрыто арендатором';

  @override
  String get landlordReimbursement => 'Возмещение от владельца';

  @override
  String get tenantToPay => 'Оплата арендатором';

  @override
  String get landlordReimburseDesc =>
      'Арендатор оплатил заранее. Владелец возместит или вычтет из следующей аренды.';

  @override
  String get tenantToPayDesc =>
      'Расход закреплен за арендатором. Сумма будет включена в следующую аренду.';

  @override
  String get coveredByLandlordClosedDesc =>
      'Покрыто как основные расходы на имущество и закрыто.';

  @override
  String get coveredByTenantClosedDesc =>
      'Покрыто как эксплуатационный расход арендатора и закрыто.';

  @override
  String get reEditFinancials => 'Редактировать расходы';

  @override
  String get expenseRejectedDesc =>
      'Ранее поданная заявка на расход была отклонена. Вы можете отправить повторно с исправленной суммой и чеком.';

  @override
  String get agencyManager => 'Менеджер агентства';

  @override
  String actorStatusInvestigating(String actor) {
    return '🔍 $actor взял заявку на рассмотрение.';
  }

  @override
  String actorStatusInProgress(String actor) {
    return '🔧 $actor направил мастера, работы ведутся.';
  }

  @override
  String actorStatusResolved(String actor) {
    return '✅ $actor отметил проблему как решенную.';
  }

  @override
  String actorStatusClosed(String actor) {
    return '🔒 $actor закрыл заявку.';
  }

  @override
  String actorStatusReopened(String actor) {
    return '🔄 $actor повторно открыл заявку. Проблема сохраняется.';
  }

  @override
  String actorMarkedActive(String actor) {
    return '📋 $actor перевел заявку в статус активной.';
  }

  @override
  String actorUpdatedStatus(String actor, String status) {
    return '📌 $actor обновил статус: $status';
  }

  @override
  String get submitExpenseReview => 'Отправить расход (На проверку)';

  @override
  String get pleaseEnterValidCost =>
      'Пожалуйста, укажите корректную сумму оплаты.';

  @override
  String get pleaseUploadReceipt => 'Пожалуйста, прикрепите чек или счет.';

  @override
  String get pleaseSelectCostPayer =>
      'Пожалуйста, выберите ответственного за оплату.';

  @override
  String get noteLabel => 'Примечание';

  @override
  String get amountPaid => 'Сумма оплаты';

  @override
  String get costAmount => 'Сумма расхода';

  @override
  String get costResponsibility => 'Кто оплатил расход?';

  @override
  String get whoPaidTheCost => 'Кто оплатил расход?';

  @override
  String get paymentInvoiceStatus => 'Статус оплаты и счета';

  @override
  String get paymentDueDate => 'Дата оплаты / срок';

  @override
  String get noDate => 'Дата не выбрана';

  @override
  String get uploadReceiptInvoice => 'Загрузить чек / счет (PDF, Изображение)';

  @override
  String get uploadInvoiceDoc => 'Загрузить счет';

  @override
  String get existingDocument => 'Сохраненный документ';

  @override
  String get change => 'Изменить';

  @override
  String get enterAmountAttachReceipt => 'Укажите сумму и прикрепите чек.';

  @override
  String declaredAmountTitle(String amount) {
    return 'Заявленная сумма: $amount • Выберите, кто оплатил расход:';
  }

  @override
  String get expenseApprovalResponsibility =>
      'Одобрение расхода и ответственность';

  @override
  String get landlordCoveredPaidTitle =>
      'Покрыто владельцем (Отметить как оплачено)';

  @override
  String get landlordCoveredPaidSub =>
      'Расход относится к владельцу (основные расходы). Возмещение не требуется, закрыто как оплачено.';

  @override
  String get landlordCoveredPaidBadge => 'Оплачено • Владелец';

  @override
  String get tenantWillPayTitle => 'Оплачивает арендатор (Добавить к аренде)';

  @override
  String get tenantWillPaySub =>
      'Расход возник по вине/использованию арендатора. Добавляется к аренде.';

  @override
  String get tenantWillPayBadge => 'Ожидает оплаты • Долг арендатора';

  @override
  String get tenantPaidMarkAsPaidTitle =>
      'Арендатор оплатил (Отметить как оплачено)';

  @override
  String get tenantPaidMarkAsPaidSub =>
      'Поломка возникла при использовании арендатором. Закрыто как оплачено без возмещения.';

  @override
  String get tenantPaidMarkAsPaidBadge => 'Оплачено • Использование арендатора';

  @override
  String get landlordReimbursesTitle =>
      'Владелец возмещает (Вычесть из аренды)';

  @override
  String get landlordReimbursesSub =>
      'Расход на имущество, оплаченный арендатором. Владелец возмещает или вычитает из аренды.';

  @override
  String get landlordReimbursesBadge => 'Ожидает оплаты • Вычет из аренды';

  @override
  String get propertyManagedByAgencyNotice =>
      'Объект находится под управлением агентства. Только агентство может редактировать финансовые данные.';

  @override
  String agencyExpenseApprovedMsg(String amount, String actor, String details) {
    return '✅ Расход подтвержден: $amount (Подтвердил $actor • $details)';
  }

  @override
  String agencyExpenseRejectedMsg(String actor) {
    return '❌ Заявка на расход отклонена $actor';
  }

  @override
  String reasonLabel(String reason) {
    return 'Причина: $reason';
  }

  @override
  String get roleYou => 'Вы';

  @override
  String get roleUser => 'Пользователь';

  @override
  String landlordDeclaredExpenseSubtitle(String amount) {
    return 'Владелец заявил расход в размере $amount. Вы можете одобрить или отклонить расход.';
  }

  @override
  String tenantDeclaredExpenseSubtitle(String amount) {
    return 'Арендатор заявил расход в размере $amount. Вы можете одобрить или отклонить расход.';
  }

  @override
  String get expenseSubmittedForLandlordReview =>
      'Заявленный расход отправлен на проверку владельцу.';

  @override
  String get expenseSubmittedForTenantReview =>
      'Заявленный расход отправлен на проверку арендатору.';

  @override
  String get tblRequestProperty => 'Заявка и объект';

  @override
  String get tblPriority => 'Приоритет';

  @override
  String get tblIssueStatus => 'Статус проблемы';

  @override
  String get tblCostPayer => 'Расход и плательщик';

  @override
  String get tblFinancialStatus => 'Финансовый статус';

  @override
  String get tblDate => 'Дата';

  @override
  String get dueDatePrefix => 'Срок';

  @override
  String get edit => 'Редактировать';

  @override
  String get update => 'Обновить';

  @override
  String get paymentDate => 'Дата оплаты';

  @override
  String get profileUpdated => 'Успешно сохранено.';

  @override
  String get agencyPropertyTakeoverTitle =>
      'Принять объект, добавленный агентством';

  @override
  String get agencyPropertyTakeoverDesc =>
      'Добавьте объект, введенный агентством, в свой аккаунт, отсканировав QR-код или введя код приглашения.';

  @override
  String get scanQrOrEnterInviteCodeBtn => 'Сканировать QR-код / Ввести код';

  @override
  String get settlementIntentTitle => 'Цель оплаты и взаиморасчет';

  @override
  String get intentTenantSelfTitle =>
      'Арендатор оплатил за личное пользование (Поломка при эксплуатации)';

  @override
  String get intentTenantSelfSub =>
      'Сумма остается на арендаторе. Возмещение не требуется, закрыть как оплачено.';

  @override
  String get intentTenantSelfBadge => 'Оплачено • Расход арендатора';

  @override
  String get intentTenantReimburseTitle =>
      'Арендатор оплатил за имущество/ремонт (От имени владельца)';

  @override
  String get intentTenantReimburseSub =>
      'Арендатор оплатил авансом за основные фонды. Запрашивается вычет из аренды или возврат.';

  @override
  String get intentTenantReimburseBadge => 'Вычесть из аренды';

  @override
  String get intentLandlordSelfTitle =>
      'Владелец оплатил за имущество/ремонт (Расход владельца)';

  @override
  String get intentLandlordSelfSub =>
      'Расход покрыл владелец. С арендатора не взимается, закрыть как оплачено.';

  @override
  String get intentLandlordSelfBadge => 'Оплачено • Владелец';

  @override
  String get intentLandlordTenantDueTitle =>
      'Владелец оплатил за поломку по вине арендатора (Взыскать с арендатора)';

  @override
  String get intentLandlordTenantDueSub =>
      'Поломка возникла при использовании арендатором. Запрашивается добавить к следующей аренде.';

  @override
  String get intentLandlordTenantDueBadge => 'Добавить к аренде';

  @override
  String get pleaseSelectDeclarationIntent =>
      'Пожалуйста, выберите цель оплаты и вариант взаиморасчета.';

  @override
  String get confirmTenantReimburseApprovalTitle => 'Подтверждение зачета';

  @override
  String confirmTenantReimburseApprovalMsg(String amount) {
    return 'Вы подтверждаете, что арендатор может вычесть этот расход на имущество на сумму $amount из арендной платы?';
  }

  @override
  String get confirmTenantSelfApprovalTitle => 'Подтверждение личного расхода';

  @override
  String confirmTenantSelfApprovalMsg(String amount) {
    return 'Вы подтверждаете, что арендатор оплатил расход на сумму $amount самостоятельно и заявка закрывается как оплаченная?';
  }

  @override
  String get confirmLandlordSelfApprovalTitle =>
      'Подтверждение расхода владельца';

  @override
  String confirmLandlordSelfApprovalMsg(String amount) {
    return 'Вы подтверждаете, что владелец покрыл расход на сумму $amount и заявка закрывается как оплаченная?';
  }

  @override
  String get confirmLandlordTenantDueApprovalTitle => 'Подтверждение долга';

  @override
  String confirmLandlordTenantDueApprovalMsg(String amount) {
    return 'Вы подтверждаете, что этот расход на сумму $amount возник в результате вашего использования и будет оплачен владельцу?';
  }

  @override
  String get acceptDebtBtn => 'Принять долг';

  @override
  String get approveOffsetBtn => 'Подтвердить зачет';

  @override
  String get acceptDebtNote =>
      'После принятия сумма будет добавлена к вашим долгам в плане платежей.';

  @override
  String get approveOffsetNote =>
      'После подтверждения сумма зачисляется на баланс зачета арендатора для вычета из будущей аренды.';

  @override
  String declaredIntentLabel(String intent) {
    return 'Запрос взаиморасчета: $intent';
  }

  @override
  String get maintenanceSettlementsHeader =>
      'Взаиморасчеты по ремонту и расходам';

  @override
  String get maintenanceSettlementsSub =>
      'Утвержденные расходы на ремонт к вычету или добавлению к аренде';

  @override
  String get deductFromRentBadge => 'К вычету из аренды';

  @override
  String get addToRentBadge => 'К оплате с арендой';

  @override
  String get markAsSettledBtn => 'Отметить как зачтено / оплачено';

  @override
  String get confirmSettlementTitle => 'Закрыть взаиморасчет';

  @override
  String confirmSettlementMsg(String amount) {
    return 'Подтверждаете, что расход на ремонт на сумму $amount зачтен/оплачен и расчет закрыт?';
  }

  @override
  String get settlementRecordedSuccess =>
      'Взаиморасчет по ремонту успешно закрыт.';

  @override
  String get goToMaintenanceRequest => 'Открыть заявку';

  @override
  String maintenanceSettlementActivityMsg(String amount, String role) {
    return '💰 Расход на ремонт ($amount) отмечен как зачтенный/оплаченный ($role).';
  }

  @override
  String get settleExpenseTitle => 'Урегулирование расходов на ремонт';

  @override
  String get settleExpenseSub => 'Выберите способ оплаты или взаимозачета';

  @override
  String get optionOffsetFromRent => 'Зачесть из задолженности';

  @override
  String get optionOffsetFromRentDesc =>
      'Автоматически вычесть эту сумму из ожидающего платежа аренды, счета или ремонта в той же валюте';

  @override
  String get optionBankTransfer => 'Оплатить банковским переводом';

  @override
  String get optionBankTransferDesc =>
      'Загрузить квитанцию об оплате и отправить на подтверждение';

  @override
  String get optionCashPayment => 'Оплатить наличными';

  @override
  String get optionCashPaymentDesc => 'Подтвердить передачу наличными';

  @override
  String get selectRentToOffset => 'Выберите задолженность для зачета';

  @override
  String noEligiblePendingPayments(String currency) {
    return 'Не найдено подходящих задолженностей по аренде, счетам или ремонту для зачета ($currency).';
  }

  @override
  String offsetAppliedSuccess(String amount, String paymentTitle) {
    return 'Сумма $amount успешно зачтена из платежа $paymentTitle.';
  }

  @override
  String get confirmReceiptBtn => 'Оплату получил / Подтвердить';

  @override
  String get waitingForRecipientApproval =>
      'Ожидается подтверждение второй стороны';

  @override
  String get iPaidBtn => 'Оплачено / Загрузить чек';

  @override
  String get iPaidCashBtn => 'Оплачено наличными';

  @override
  String maintenanceCashPaidActivityMsg(String role, String amount) {
    return '💵 $role заявил об оплате расходов на ремонт ($amount) наличными. Ожидается подтверждение.';
  }

  @override
  String maintenanceBankPaidActivityMsg(String role, String amount) {
    return '📄 $role заявил об оплате расходов на ремонт ($amount) банковским переводом (Квитанция приложена). Ожидается подтверждение.';
  }

  @override
  String maintenanceOffsetActivityMsg(String amount, String paymentTitle) {
    return '🏠 Расход на ремонт ($amount) зачтен из платежа $paymentTitle.';
  }

  @override
  String agencyReferralBoundSuccess(String agencyName) {
    return 'Реферал агентства привязан: $agencyName';
  }

  @override
  String get invalidAgencyReferralCode =>
      'Недействительный или не найденный реферальный код агентства.';

  @override
  String get occupancyRate => 'Заполняемость';

  @override
  String get allPropertiesUpToDate =>
      'Все объекты и платежи в актуальном состоянии. Нет ожидающих подтверждений.';

  @override
  String overduePaymentsAlert(int count) {
    return 'Имеется $count просроченных платежей. Проверьте список объектов для подробностей.';
  }

  @override
  String get filterAll => 'Все';

  @override
  String get filterRented => 'Сдано';

  @override
  String get filterVacant => 'Свободно';

  @override
  String get noPropertiesForFilter => 'Не найдено объектов для этого фильтра.';

  @override
  String get attentionTag => 'ВНИМАНИЕ';

  @override
  String get reviewAction => 'Проверить';

  @override
  String get detailsAction => 'Детали';

  @override
  String get noActiveContractTapToInvite =>
      'Нет активного договора. Нажмите, чтобы пригласить жильца.';

  @override
  String get activeTenantsCount => 'Активные жильцы';

  @override
  String get totalPropertiesCount => 'Всего объектов';

  @override
  String get collectedRentSubtitle => 'Собранная аренда';

  @override
  String get awaitingApprovalSubtitle => 'Подтверждение квитанций';

  @override
  String get overduePaymentsSubtitle => 'Просрочено';

  @override
  String get vacantUnitsSubtitle => 'Доступно для аренды';

  @override
  String get portfolioRateSubtitle => 'Показатель портфеля';

  @override
  String get rentedStatusTag => 'Сдано';

  @override
  String get invitedStatusTag => 'Приглашение отправлено';

  @override
  String get settlementCredit => 'Зачетный остаток';

  @override
  String get noDebtLabel => 'Нет долга';

  @override
  String daysLeftBadge(int count) {
    return 'Осталось $count дн.';
  }

  @override
  String get dueTodayBadge => 'Сегодня последний день';

  @override
  String get overdueBadge => 'Просрочено';

  @override
  String allTenantPaymentsUpToDate(String date) {
    return 'Все ваши платежи актуальны. Следующая аренда $date.';
  }

  @override
  String tenantAwaitingReceiptApprovalMsg(int count) {
    return 'Квитанция загружена для $count платежей, ожидается подтверждение.';
  }

  @override
  String tenantOutstandingDebtMsg(int count) {
    return 'У вас имеется $count неоплаченных счетов.';
  }

  @override
  String get quickActionFinance => 'Аренда и счета';

  @override
  String get quickActionMaintenance => 'Ремонт и заявки';

  @override
  String get quickActionContract => 'Договор';

  @override
  String get quickActionHistory => 'История платежей';

  @override
  String get monthlyBaseRent => 'Месячная аренда';

  @override
  String get payNowAction => 'Оплатить';

  @override
  String get depositSecuredLabel => 'Депозит внесен';

  @override
  String get maintenanceTitle => 'Заявки на ремонт и обслуживание';

  @override
  String get maintenanceSubtitle =>
      'Отслеживайте заявки, визиты мастеров и взаиморасчеты расходов.';

  @override
  String get filterActive => 'Активные и в работе';

  @override
  String get filterInvestigating => 'На проверке';

  @override
  String get filterUrgent => 'Срочно';

  @override
  String get filterCompleted => 'Решенные';

  @override
  String get filterCost => 'С расходами / Возврат';

  @override
  String get searchMaintenancePlaceholder => 'Поиск заявок...';

  @override
  String get statActiveIssues => 'Активные / В работе';

  @override
  String get statUrgentIssues => 'Срочные заявки';

  @override
  String get statResolvedIssues => 'Решенные';

  @override
  String get statPendingSettlement => 'Расходы / Возврат';

  @override
  String get progressReported => 'Создана';

  @override
  String get progressInvestigating => 'Проверка';

  @override
  String get progressInProgress => 'Мастер';

  @override
  String get progressResolved => 'Решена';

  @override
  String get statusInProgressTechnician => 'Мастер назначен';

  @override
  String get costDeductFromRent => 'Вычесть из аренды';

  @override
  String get costAddToRent => 'Добавить к аренде';

  @override
  String get costPaidByTenant => 'Оплатил арендатор';

  @override
  String get costPaidByLandlord => 'Оплатил владелец';

  @override
  String get costPendingReview => 'Ожидает одобрения';

  @override
  String get costRejected => 'Расход отклонен';

  @override
  String get viewInvoiceAction => 'Смотреть счет';

  @override
  String get noMatchingIssues => 'Заявки по вашему запросу не найдены';

  @override
  String get clearFilters => 'Сбросить фильтры';

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото',
      few: '$count фото',
      one: '$count фото',
    );
    return '$_temp0';
  }

  @override
  String get viewDetailsAction => 'Смотреть детали';

  @override
  String get reportIssueSubtitle =>
      'Отправьте информацию о поломке или ремонте с фото для быстрого решения.';

  @override
  String get issueTitleHint => 'Напр: Протекает вода под кухонной раковиной';

  @override
  String get issueDescriptionHint =>
      'Опишите точное место, когда началась проблема и детали...';

  @override
  String get priorityNormalDesc => 'Стандартный процесс ремонта и обслуживания';

  @override
  String get priorityUrgentDesc => 'Затопление, замыкание или срочная ситуация';

  @override
  String get photosSubtitle => 'Добавьте четкие фото поломки (Макс. 5)';

  @override
  String get addPhotoFromGallery => 'Загрузить фото';

  @override
  String get sendRequestBtn => 'Отправить заявку на ремонт';

  @override
  String get categorySelectorTitle => 'Категория поломки';

  @override
  String get prioritySelectorTitle => 'Уровень приоритета';

  @override
  String get financialSectionTitle => 'ФИНАНСОВЫЕ ДАННЫЕ И СЧЕТ';

  @override
  String get financialSectionSubtitle =>
      'Укажите расходы на ремонт и счет при наличии (Необязательно).';

  @override
  String get costAmountLabel => 'Сумма расходов';

  @override
  String get paidByLabel => 'Кто оплачивает';

  @override
  String get unassignedLabel => 'Не указано';

  @override
  String get paymentStatusLabel => 'Статус счета и оплаты';

  @override
  String get pendingReviewHint => 'Счет на проверке (Не влияет на баланс)';

  @override
  String get pendingPaymentHint => 'Одобрено • Отражается к оплате';

  @override
  String get paymentCompletedSubtitle => 'Оплата завершена';

  @override
  String get paymentRejectedSubtitle => 'Недействительно / Отклонено';

  @override
  String get invoicePdfLabel => 'Счет / Квитанция';

  @override
  String get uploadPdfTitle => 'Загрузить счет PDF';

  @override
  String get uploadPdfSubtitle => 'Нажмите для выбора PDF (Макс. 10MB)';

  @override
  String get tenantLockedStatusNotice =>
      'Арендатор не может изменить статус оплаты, если не оплачивает сам (сохраняется как На проверке).';

  @override
  String get payerRequiredError =>
      'Пожалуйста, укажите кто оплачивает перед установкой статуса.';

  @override
  String get tabRentAndFinance => 'Аренда и Финансы';

  @override
  String get tabLeaseAndTenant => 'Договор и Арендатор';

  @override
  String get tabMaintenance => 'Обслуживание';

  @override
  String get tabAuditLog => 'История операций';

  @override
  String get paymentMethodBank => 'Банк';

  @override
  String get paymentMethodCash => 'Наличные';

  @override
  String get paymentMethodLabel => 'Способ оплаты:';

  @override
  String get managedByAgencyTitle => 'Под управлением агентства';

  @override
  String get managedByAgencyDesc =>
      'Ваша недвижимость управляется агентством. Добавление новых объектов может осуществляться только управляющим агентством.';

  @override
  String get structuralAndFinancialMetricsSubtitle =>
      'Тип недвижимости, номер квартиры, количество комнат и этажность';

  @override
  String get equipmentAndHeatingStandardsSubtitle =>
      'Меблировка и система отопления';

  @override
  String get featuredAmenitiesSubtitle =>
      'Основные удобства и подробное описание';

  @override
  String get roomTypeStudio => 'Студия';

  @override
  String get secondaryContacts => 'Дополнительные контактные лица';

  @override
  String get addSecondaryContact => 'Добавить контакт';

  @override
  String get secondaryContactsOptionalDesc =>
      'Необязательно: Вы можете добавить дополнительные контакты, такие как ассистент, представитель или член семьи.';

  @override
  String get roleOrRelation => 'Роль / Отношение';

  @override
  String get tenantFullName => 'Имя и фамилия арендатора';

  @override
  String get tenantIdOrPassport => 'Удостоверение / Паспорт / JMBG';

  @override
  String get tenantNotes => 'Заметки об арендаторе';

  @override
  String get tenantIdDocument =>
      'Документ, удостоверяющий личность / Паспорт арендатора';

  @override
  String get uploadPdfOrPhoto => 'Загрузите в формате PDF или фото';

  @override
  String get uploadAction => 'Загрузить';

  @override
  String get idDocumentUploaded => 'Документ загружен';

  @override
  String copiedId(String id) {
    return 'ID скопирован: $id';
  }

  @override
  String get rolePersonalAssistant => 'Личный помощник';

  @override
  String get rolePrRep => 'PR / Представитель';

  @override
  String get roleFamilyMember => 'Член семьи';

  @override
  String get roleAuthorizedContact => 'Доверенное лицо';

  @override
  String get clearAllAction => 'Сбросить все';

  @override
  String get selectAllAction => 'Выбрать все';

  @override
  String get applyAction => 'Применить';

  @override
  String selectedCount(int count) {
    return '$count выбрано';
  }

  @override
  String selectedItemsCount(int count) {
    return '$count Выбрано';
  }

  @override
  String get propertyOwnerInfoTitle => 'Информация о собственниках';

  @override
  String get propertyOwnerInfoSubtitle =>
      'Вы можете добавить нескольких собственников, юридические или физические лица, и загрузить подтверждающие документы.';

  @override
  String get addCoOwner => '+ Добавить совладельца';

  @override
  String get primaryOwnerLabel => '1. Собственник (Основной)';

  @override
  String coOwnerIndexedLabel(int index) {
    return '$index. Совладелец';
  }

  @override
  String get sharePercentage => 'Доля %';

  @override
  String get removeOwner => 'Удалить собственника';

  @override
  String get ownerType => 'Тип собственника';

  @override
  String get ownerIndividual => 'Физическое лицо';

  @override
  String get ownerCompany => 'Юридическое лицо / Компания';

  @override
  String get firstNameRequired => 'Имя *';

  @override
  String get lastNameRequired => 'Фамилия *';

  @override
  String get idOrPassportOrJmbg => 'Номер паспорта / удостоверения';

  @override
  String get idIssuingAuthority => 'Орган выдачи документа';

  @override
  String get companyLegalNameRequired => 'Полное юридическое наименование *';

  @override
  String get registeredOfficeAddress => 'Юридический адрес';

  @override
  String get taxIdPibRequired => 'ИНН / PIB *';

  @override
  String get companyRegNo => 'ОГРН / Matični broj';

  @override
  String get legalRepFullNameRequired => 'ФИО представителя *';

  @override
  String get repIdJmbg => 'Паспорт представителя';

  @override
  String get repAuthorityDetails => 'Детали полномочий представителя';

  @override
  String get contactPhoneRequired => 'Контактный телефон *';

  @override
  String get secondaryContactOptional => 'Доп. контакт (Опционально)';

  @override
  String get altPhoneOrNote => 'Доп. тел. / Заметка';

  @override
  String get emailAddressRequiredForPrimary =>
      'Email (Обязательно для основного) *';

  @override
  String get emailAddressOptional => 'Email (Опционально)';

  @override
  String get selectExistingAgencyContact =>
      'Или выберите из существующих контактов...';

  @override
  String get clearSelectionTooltip => 'Очистить выбор';

  @override
  String get supportingPdfDocuments => 'Подтверждающие PDF документы';

  @override
  String get uploadDocumentTooltip => 'Загрузить документ';

  @override
  String get docTypePassportCopy => 'Копия паспорта / удостоверения (PDF)';

  @override
  String get docTypeProofOfOwnership => 'Свидетельство о собственности (PDF)';

  @override
  String get docTypePowerOfAttorney => 'Доверенность (PDF)';

  @override
  String get docTypeOtherDocument => 'Другой документ (PDF)';

  @override
  String get addPdfDocument => '+ Добавить PDF';

  @override
  String get docTypeLabelId => 'Паспорт';

  @override
  String get docTypeLabelTitleDeed => 'Выписка';

  @override
  String get docTypeLabelPoa => 'Доверенность';

  @override
  String get docTypeLabelOther => 'Документ';

  @override
  String get markAsPaid => 'Отметить как оплачено';

  @override
  String markAsPaidSubtitle(String title, String month) {
    return 'Подтверждение оплаты за $title ($month)';
  }

  @override
  String get bankTransferOption => 'Банковский перевод';

  @override
  String get receiptOrDocOptional => 'Квитанция / Документ (Опционально)';

  @override
  String get uploadReceiptOrImage => 'Загрузить квитанцию или фото';

  @override
  String get uploadReceiptHint => 'PDF, PNG, JPG или фото';

  @override
  String get noteOptional => 'Примечание (Опционально)';

  @override
  String get noteOptionalRentHint =>
      'Напр: Получено наличными / Квитанция прикреплена';

  @override
  String get paymentMarkedPaidSuccess =>
      'Платеж успешно отмечен как оплаченный.';

  @override
  String get saveAsPaid => 'Сохранить как оплаченное';

  @override
  String get collectSettleExpenseTitle => 'Подтверждение получения и закрытие';

  @override
  String collectSettleExpenseSubtitle(String cost) {
    return 'Подтвердите получение $cost и закройте расход.';
  }

  @override
  String get collectionMethod => 'Способ получения';

  @override
  String get collectionMethodBank => 'Банк / Перевод';

  @override
  String get collectionMethodCash => 'Наличные';

  @override
  String get collectionMethodPayoutDeduction => 'Вычтено из аренды';

  @override
  String get attachReceiptOrVoucher => 'Прикрепить квитанцию';

  @override
  String get noteOptionalAgencyHint => 'Напр: Владелец передал наличные';

  @override
  String get payoutDeductionLabel => 'Вычет из аренды';

  @override
  String get collectionConfirmedAndSettled =>
      'Оплата подтверждена, запись закрыта.';

  @override
  String get confirmAndSettle => 'Подтвердить и закрыть';

  @override
  String propertyOwnersCountTitle(int count) {
    return 'Собственники ($count)';
  }

  @override
  String get editOwners => 'Редактировать собственников';

  @override
  String get primaryOwnerBadge => 'Основной';

  @override
  String get authorizedRepresentative => 'Представитель';

  @override
  String get registeredAddressLabel => 'Юридический адрес';

  @override
  String get idJmbgLabel => 'Паспорт/JMBG';

  @override
  String get secondaryContactPrefix => 'Доп. контакт: ';

  @override
  String get supportingDocumentsColon => 'Подтверждающие документы:';

  @override
  String get auditPaymentCreatedRent =>
      'Система автоматически создала запись о начислении';

  @override
  String get auditPaymentCreatedExpense =>
      'Система автоматически создала запись о расходах';

  @override
  String auditRentDeclaredCash(String actor, String monthSuffix) {
    return '$actor сообщил об оплате (Наличные)$monthSuffix';
  }

  @override
  String auditRentDeclaredReceipt(String actor, String monthSuffix) {
    return '$actor сообщил об оплате, загрузив квитанцию$monthSuffix';
  }

  @override
  String auditRentApproved(String actor, String monthSuffix) {
    return '$actor одобрил платеж$monthSuffix';
  }

  @override
  String auditRentRejected(String actor, String monthSuffix) {
    return '$actor отклонил платеж$monthSuffix';
  }

  @override
  String auditRentDisputed(String actor, String reasonSuffix) {
    return '$actor оспорил платеж$reasonSuffix';
  }

  @override
  String auditInvoiceUploadedPending(
    String actor,
    String monthPrefix,
    String amount,
  ) {
    return '$actor $monthPrefixзагрузил счет (Ожидает одобрения, $amount)';
  }

  @override
  String auditInvoiceUploaded(String actor, String monthPrefix, String amount) {
    return '$actor $monthPrefixзагрузил счет ($amount)';
  }

  @override
  String auditInvoiceEnteredPending(
    String actor,
    String monthPrefix,
    String amount,
  ) {
    return '$actor $monthPrefixввел сумму расхода (Ожидает одобрения, $amount)';
  }

  @override
  String auditInvoiceEntered(String actor, String monthPrefix, String amount) {
    return '$actor $monthPrefixввел данные расхода ($amount)';
  }

  @override
  String auditInvoiceApproved(String actor, String monthPrefix, String amount) {
    return '$actor $monthPrefixодобрил счет ($amount)';
  }

  @override
  String auditInvoiceRejected(
    String actor,
    String monthPrefix,
    String reasonSuffix,
  ) {
    return '$actor $monthPrefixотклонил счет$reasonSuffix';
  }

  @override
  String auditPaymentToggle(String actor, String status) {
    return '$actor отметил платеж как $status';
  }

  @override
  String get auditRentAutoApproved =>
      'Платеж был автоматически одобрен системой';

  @override
  String auditMaintenanceCreated(String actor, String titleSuffix) {
    return '$actor создал заявку на обслуживание$titleSuffix';
  }

  @override
  String auditMaintenanceStatusUpdated(String actor, String status) {
    return '$actor обновил статус заявки на обслуживание ($status)';
  }

  @override
  String auditMaintenanceMessageAdded(String actor) {
    return '$actor добавил сообщение к заявке на обслуживание';
  }

  @override
  String auditMaintenanceReopened(String actor) {
    return '$actor повторно открыл заявку на обслуживание';
  }

  @override
  String contactTenantAsLandlordInfo(String propertySummary) {
    return 'Этот контакт зарегистрирован как арендатор ($propertySummary). Теперь добавляется как собственник.';
  }

  @override
  String get registeredLandlordDetailsAutofilled =>
      'Данные зарегистрированного собственника заполнены.';

  @override
  String get noDocumentsAttachedYet => 'Документы еще не загружены.';

  @override
  String get coOwnerEmailHelper =>
      'При указании email совладелец сможет видеть объект после входа в систему.';

  @override
  String get propertyOwnersUpdatedSuccess =>
      'Данные собственников успешно обновлены.';

  @override
  String get systemActor => 'Система';

  @override
  String get agencyRole => 'Агентство';

  @override
  String get editPropertyOwners => 'Редактировать собственников недвижимости';

  @override
  String auditInvitationAccepted(Object actor) {
    return '$actor принял(а) приглашение по объекту';
  }

  @override
  String auditContractAccepted(Object actor) {
    return '$actor подтвердил(а) и подписал(а) договор аренды';
  }

  @override
  String auditContractTerminationRequested(Object actor) {
    return '$actor запросил(а) досрочное расторжение договора';
  }

  @override
  String auditContractChangesAccepted(Object actor) {
    return '$actor принял(а) предложенные изменения договора';
  }

  @override
  String auditContractChangesDeclined(Object actor) {
    return '$actor отклонил(а) или отозвал(а) изменения договора';
  }

  @override
  String auditLandlordOwnershipClaimed(Object actor) {
    return '$actor принял(а) право собственности и управление объектом';
  }

  @override
  String auditTenantRemoved(Object actor) {
    return '$actor удалил(а) арендатора из объекта';
  }

  @override
  String auditPropertyOwnersUpdated(Object actor) {
    return '$actor обновил(а) данные о владельцах объекта';
  }

  @override
  String auditMaintenanceFinancialsUpdated(Object actor) {
    return '$actor обновил(а) расходы и финансовые детали обслуживания';
  }

  @override
  String auditMaintenanceFinancialsDeleted(Object actor) {
    return '$actor удалил(а) детали расходов обслуживания и отменил(а) зачеты';
  }

  @override
  String auditMaintenanceChargeCreated(Object actor) {
    return '$actor добавил(а) новую статью расходов по обслуживанию';
  }

  @override
  String auditMaintenanceChargeStatusUpdated(Object actor) {
    return '$actor обновил(а) статус расхода по обслуживанию';
  }

  @override
  String auditMaintenanceChargeSettled(Object actor) {
    return '$actor произвел(а) взаимозачет расхода по обслуживанию';
  }

  @override
  String auditMaintenanceDeleted(Object actor) {
    return '$actor удалил(а) заявку на обслуживание';
  }

  @override
  String get tenantInviteEmailTitle => 'Уведомление для арендатора (email)';

  @override
  String get landlordInviteEmailTitle => 'Уведомление для владельца (email)';

  @override
  String get statusNotSent => 'Не отправлено';

  @override
  String get statusNoEmail => 'Нет email';

  @override
  String lastSentAt(String date) {
    return 'Последняя отправка: $date';
  }

  @override
  String get noEmailSpecified => 'Email адрес не указан';

  @override
  String ownersConfirmedRatio(String confirmed, String total) {
    return '$confirmed/$total Подтверждено';
  }

  @override
  String ownerConfirmedBanner(String name) {
    return '$name подтвердил(а) приглашение и принял(а) управление недвижимостью.';
  }

  @override
  String get emailPreviewTitle => 'Предпросмотр отправляемого email';

  @override
  String emailPreviewForOwner(String name) {
    return 'Предпросмотр email ($name)';
  }

  @override
  String get tabVisual => 'Визуальный';

  @override
  String get tabPlainText => 'Простой текст';

  @override
  String get emailCopiedToast => 'Текст email скопирован в буфер обмена.';

  @override
  String get languageLabel => 'Язык:';

  @override
  String get subjectHeader => 'ТЕМА';

  @override
  String get contentHeader => 'СОДЕРЖАНИЕ';

  @override
  String get recipientWillReceiveThisFormat =>
      'Получатель получит в этом формате';

  @override
  String get sendTenantInviteEmailBtn => 'Отправить email арендатору';

  @override
  String get resendInviteEmailBtn => 'Отправить email повторно';

  @override
  String get sendLandlordInviteEmailBtn => 'Отправить email владельцу';

  @override
  String sendInviteForOwnerBtn(String name) {
    return 'Отправить email для $name';
  }

  @override
  String resendInviteForOwnerBtn(String name) {
    return 'Отправить повторно для $name';
  }

  @override
  String get sendToAllBtn => 'Отправить всем';

  @override
  String sendToAllOwnersBtn(String count) {
    return 'Отправить всем владельцам индивидуально ($count)';
  }

  @override
  String resendToAllOwnersBtn(String count) {
    return 'Повторно отправить всем владельцам ($count)';
  }

  @override
  String get sendingState => 'Отправка...';

  @override
  String get sendingAllState => 'Отправка всем...';

  @override
  String get noEmailAddressDefined => 'Email адрес не указан';

  @override
  String tenantInviteSentSuccess(String email) {
    return 'Приглашение успешно отправлено на $email.';
  }

  @override
  String landlordInviteSentSuccess(String email) {
    return 'Приглашение успешно отправлено на $email.';
  }

  @override
  String noEmailForUserError(String name) {
    return 'Для $name не указан email адрес.';
  }

  @override
  String get tenantNoEmailError => 'Email адрес арендатора не указан.';

  @override
  String get emailSendFailedError =>
      'Не удалось отправить email. Пожалуйста, проверьте настройки Brevo API.';

  @override
  String emailSendGenericError(String error) {
    return 'Произошла ошибка при отправке email: $error';
  }

  @override
  String get tenantInviteEmailBtn => 'Email приглашение для арендатора';

  @override
  String allOwnersInviteSentSuccess(String successCount, String totalCount) {
    return 'Письма-приглашения успешно отправлены для $successCount / $totalCount владельцев недвижимости.';
  }

  @override
  String landlordsListHeader(String count) {
    return 'Владельцы недвижимости ($count)';
  }
}
