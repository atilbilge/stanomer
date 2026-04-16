class LandlordDashboardStats {
  final Map<String, double> expectedByCurrency;
  final Map<String, double> collectedByCurrency;
  final int delaysCount;
  final int vacantCount;
  final int totalProperties;

  const LandlordDashboardStats({
    this.expectedByCurrency = const {},
    this.collectedByCurrency = const {},
    this.delaysCount = 0,
    this.vacantCount = 0,
    this.totalProperties = 0,
  });

  LandlordDashboardStats copyWith({
    Map<String, double>? expectedByCurrency,
    Map<String, double>? collectedByCurrency,
    int? delaysCount,
    int? vacantCount,
    int? totalProperties,
  }) {
    return LandlordDashboardStats(
      expectedByCurrency: expectedByCurrency ?? this.expectedByCurrency,
      collectedByCurrency: collectedByCurrency ?? this.collectedByCurrency,
      delaysCount: delaysCount ?? this.delaysCount,
      vacantCount: vacantCount ?? this.vacantCount,
      totalProperties: totalProperties ?? this.totalProperties,
    );
  }
}
