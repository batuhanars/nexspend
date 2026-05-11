// ignore_for_file: constant_identifier_names

class InflationRateModel {
  const InflationRateModel({
    required this.categoryKey,
    required this.year,
    required this.month,
    required this.monthlyRate,
    this.yearlyRate,
    required this.fetchedAt,
  });

  final String categoryKey;
  final int year;
  final int month;
  final double monthlyRate;
  final double? yearlyRate;
  final DateTime fetchedAt;

  factory InflationRateModel.fromJson(Map<String, dynamic> json) =>
      InflationRateModel(
        categoryKey: json['categoryKey'] as String? ?? '',
        year: (json['year'] as num).toInt(),
        month: (json['month'] as num).toInt(),
        monthlyRate: (json['monthlyRate'] as num).toDouble(),
        yearlyRate: json['yearlyRate'] != null
            ? (json['yearlyRate'] as num).toDouble()
            : null,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );
}

class InflationSuggestionModel {
  const InflationSuggestionModel({
    required this.budgetId,
    required this.currentAmount,
    required this.suggestedAmount,
    required this.cumulativeRate,
    required this.monthsSinceUpdate,
    required this.categoryKey,
  });

  final String budgetId;
  final double currentAmount;
  final double suggestedAmount;
  final double cumulativeRate;
  final int monthsSinceUpdate;
  final String categoryKey;

  factory InflationSuggestionModel.fromJson(Map<String, dynamic> json) =>
      InflationSuggestionModel(
        budgetId: json['budgetId'] as String,
        currentAmount: (json['currentAmount'] as num).toDouble(),
        suggestedAmount: (json['suggestedAmount'] as num).toDouble(),
        cumulativeRate: (json['cumulativeRate'] as num).toDouble(),
        monthsSinceUpdate: (json['monthsSinceUpdate'] as num).toInt(),
        categoryKey: json['categoryKey'] as String,
      );
}

enum InflationComparisonStatus { BELOW, EQUAL, ABOVE }

class InflationComparisonRowModel {
  const InflationComparisonRowModel({
    required this.categoryId,
    required this.categoryName,
    required this.lastPeriodSpent,
    required this.currentPeriodSpent,
    this.userChangeRate,
    required this.inflationRate,
    required this.status,
  });

  final String categoryId;
  final String categoryName;
  final double lastPeriodSpent;
  final double currentPeriodSpent;
  final double? userChangeRate;
  final double inflationRate;
  final InflationComparisonStatus status;

  factory InflationComparisonRowModel.fromJson(Map<String, dynamic> json) =>
      InflationComparisonRowModel(
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
        lastPeriodSpent: (json['lastPeriodSpent'] as num).toDouble(),
        currentPeriodSpent: (json['currentPeriodSpent'] as num).toDouble(),
        userChangeRate: json['userChangeRate'] != null
            ? (json['userChangeRate'] as num).toDouble()
            : null,
        inflationRate: (json['inflationRate'] as num).toDouble(),
        status: InflationComparisonStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => InflationComparisonStatus.EQUAL,
        ),
      );
}

class InflationComparisonSummary {
  const InflationComparisonSummary({
    required this.categoriesBelow,
    required this.categoriesAbove,
    required this.categoriesEqual,
  });

  final int categoriesBelow;
  final int categoriesAbove;
  final int categoriesEqual;

  factory InflationComparisonSummary.fromJson(Map<String, dynamic> json) =>
      InflationComparisonSummary(
        categoriesBelow: (json['categoriesBelow'] as num).toInt(),
        categoriesAbove: (json['categoriesAbove'] as num).toInt(),
        categoriesEqual: (json['categoriesEqual'] as num).toInt(),
      );
}

class InflationComparisonModel {
  const InflationComparisonModel({
    required this.period,
    required this.rows,
    required this.summary,
  });

  final String period;
  final List<InflationComparisonRowModel> rows;
  final InflationComparisonSummary summary;

  factory InflationComparisonModel.fromJson(Map<String, dynamic> json) =>
      InflationComparisonModel(
        period: json['period'] as String,
        rows: (json['rows'] as List)
            .map((r) =>
                InflationComparisonRowModel.fromJson(r as Map<String, dynamic>))
            .toList(),
        summary: InflationComparisonSummary.fromJson(
            json['summary'] as Map<String, dynamic>),
      );
}
