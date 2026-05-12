class InsightModel {
  const InsightModel({
    required this.id,
    required this.ruleId,
    required this.title,
    required this.message,
    this.category,
    required this.severity,
    this.data,
    required this.isRead,
    required this.isDismissed,
    required this.period,
    required this.createdAt,
  });

  final String id;
  final String ruleId;
  final String title;
  final String message;
  final String? category;
  final String severity;
  final String? data;
  final bool isRead;
  final bool isDismissed;
  final String period;
  final DateTime createdAt;

  factory InsightModel.fromJson(Map<String, dynamic> json) => InsightModel(
        id: json['id'] as String,
        ruleId: json['ruleId'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        category: json['category'] as String?,
        severity: json['severity'] as String,
        data: json['data'] as String?,
        isRead: json['isRead'] as bool,
        isDismissed: json['isDismissed'] as bool,
        period: json['period'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  InsightModel copyWith({
    bool? isRead,
    bool? isDismissed,
  }) =>
      InsightModel(
        id: id,
        ruleId: ruleId,
        title: title,
        message: message,
        category: category,
        severity: severity,
        data: data,
        isRead: isRead ?? this.isRead,
        isDismissed: isDismissed ?? this.isDismissed,
        period: period,
        createdAt: createdAt,
      );
}

class InsightSummaryModel {
  const InsightSummaryModel({
    required this.unreadCount,
    required this.totalCount,
    this.latestInsight,
  });

  final int unreadCount;
  final int totalCount;
  final InsightModel? latestInsight;

  factory InsightSummaryModel.fromJson(Map<String, dynamic> json) =>
      InsightSummaryModel(
        unreadCount: (json['unreadCount'] as num).toInt(),
        totalCount: (json['totalCount'] as num).toInt(),
        latestInsight: json['latestInsight'] != null
            ? InsightModel.fromJson(
                json['latestInsight'] as Map<String, dynamic>)
            : null,
      );
}

class InsightGenerateResultModel {
  const InsightGenerateResultModel({
    required this.generated,
    required this.period,
  });

  final int generated;
  final String period;

  factory InsightGenerateResultModel.fromJson(Map<String, dynamic> json) =>
      InsightGenerateResultModel(
        generated: (json['generated'] as num).toInt(),
        period: json['period'] as String,
      );
}
