// ignore_for_file: constant_identifier_names

enum StatementStatus { DUE, PARTIALLY_PAID, PAID, OVERDUE }

extension StatementStatusX on StatementStatus {
  bool get isOpen => this != StatementStatus.PAID;
  bool get isPaid => this == StatementStatus.PAID;
}

/// Kapatılmış bir kredi kartı ekstresi.
class StatementModel {
  const StatementModel({
    required this.id,
    required this.accountId,
    required this.periodStart,
    required this.periodEnd,
    required this.dueDate,
    required this.totalAmount,
    required this.minimumPayment,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
  });

  final String id;
  final String accountId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime dueDate;
  final double totalAmount;
  final double minimumPayment;
  final double paidAmount;
  final double remainingAmount;
  final StatementStatus status;

  factory StatementModel.fromJson(Map<String, dynamic> json) => StatementModel(
        id: json['id'] as String,
        accountId: json['accountId'] as String,
        periodStart: DateTime.parse(json['periodStart'] as String),
        periodEnd: DateTime.parse(json['periodEnd'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        minimumPayment: (json['minimumPayment'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num).toDouble(),
        remainingAmount: (json['remainingAmount'] as num).toDouble(),
        status: StatementStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => StatementStatus.DUE,
        ),
      );
}

/// Aktif (henüz kapanmamış) dönem — DB'de kayıt yok, transaction'lar üzerinden
/// hesaplanır. Backend `currentPeriod` alanında döner.
class CurrentPeriodModel {
  const CurrentPeriodModel({
    required this.periodStart,
    required this.periodEnd,
    required this.spentAmount,
    required this.transactionCount,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final double spentAmount;
  final int transactionCount;

  factory CurrentPeriodModel.fromJson(Map<String, dynamic> json) =>
      CurrentPeriodModel(
        periodStart: DateTime.parse(json['periodStart'] as String),
        periodEnd: DateTime.parse(json['periodEnd'] as String),
        spentAmount: (json['spentAmount'] as num).toDouble(),
        transactionCount: json['transactionCount'] as int,
      );
}

class AccountStatementsResponse {
  const AccountStatementsResponse({
    required this.currentPeriod,
    required this.openStatements,
    required this.history,
  });

  final CurrentPeriodModel currentPeriod;
  final List<StatementModel> openStatements;
  final List<StatementModel> history;

  factory AccountStatementsResponse.fromJson(Map<String, dynamic> json) {
    return AccountStatementsResponse(
      currentPeriod:
          CurrentPeriodModel.fromJson(json['currentPeriod'] as Map<String, dynamic>),
      openStatements: (json['openStatements'] as List)
          .map((e) => StatementModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      history: (json['history'] as List)
          .map((e) => StatementModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
