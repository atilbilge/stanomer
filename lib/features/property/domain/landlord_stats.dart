class LandlordDashboardStats {
  final Map<String, double> expectedByCurrency;
  final Map<String, double> collectedByCurrency;
  final Map<String, double> overdueByCurrency;
  final Map<String, Map<String, double>> collectedByType;
  final int delaysCount;
  final int vacantCount;
  final int totalProperties;

  final int awaitingApprovalCount;
  final String? latestAwaitingTitle;
  final String? latestAwaitingPropertyId;

  final int unenteredBillsCount;
  final String? latestUnenteredTitle;
  final String? latestUnenteredPropertyId;

  const LandlordDashboardStats({
    this.expectedByCurrency = const {},
    this.collectedByCurrency = const {},
    this.overdueByCurrency = const {},
    this.collectedByType = const {},
    this.delaysCount = 0,
    this.vacantCount = 0,
    this.totalProperties = 0,
    this.awaitingApprovalCount = 0,
    this.latestAwaitingTitle,
    this.latestAwaitingPropertyId,
    this.unenteredBillsCount = 0,
    this.latestUnenteredTitle,
    this.latestUnenteredPropertyId,
  });

  LandlordDashboardStats copyWith({
    Map<String, double>? expectedByCurrency,
    Map<String, double>? collectedByCurrency,
    Map<String, double>? overdueByCurrency,
    Map<String, Map<String, double>>? collectedByType,
    int? delaysCount,
    int? vacantCount,
    int? totalProperties,
    int? awaitingApprovalCount,
    String? latestAwaitingTitle,
    String? latestAwaitingPropertyId,
    int? unenteredBillsCount,
    String? latestUnenteredTitle,
    String? latestUnenteredPropertyId,
  }) {
    return LandlordDashboardStats(
      expectedByCurrency: expectedByCurrency ?? this.expectedByCurrency,
      collectedByCurrency: collectedByCurrency ?? this.collectedByCurrency,
      overdueByCurrency: overdueByCurrency ?? this.overdueByCurrency,
      collectedByType: collectedByType ?? this.collectedByType,
      delaysCount: delaysCount ?? this.delaysCount,
      vacantCount: vacantCount ?? this.vacantCount,
      totalProperties: totalProperties ?? this.totalProperties,
      awaitingApprovalCount: awaitingApprovalCount ?? this.awaitingApprovalCount,
      latestAwaitingTitle: latestAwaitingTitle ?? this.latestAwaitingTitle,
      latestAwaitingPropertyId: latestAwaitingPropertyId ?? this.latestAwaitingPropertyId,
      unenteredBillsCount: unenteredBillsCount ?? this.unenteredBillsCount,
      latestUnenteredTitle: latestUnenteredTitle ?? this.latestUnenteredTitle,
      latestUnenteredPropertyId: latestUnenteredPropertyId ?? this.latestUnenteredPropertyId,
    );
  }
}
