// ignore_for_file: constant_identifier_names
enum TransactionType { INCOME, EXPENSE, TRANSFER }

enum TransactionSource {
  MANUAL,
  RECURRING,
  DEBT_PAYMENT,
  DEBT_COLLECTION,
  SUBSCRIPTION,
}

class CategoryInfo {
  const CategoryInfo({
    required this.id,
    required this.name,
    this.icon,
    this.color,
  });

  final String id;
  final String name;
  final String? icon;
  final String? color;

  factory CategoryInfo.fromJson(Map<String, dynamic> json) => CategoryInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
      );
}

class AccountInfo {
  const AccountInfo({required this.id, required this.name});

  final String id;
  final String name;

  factory AccountInfo.fromJson(Map<String, dynamic> json) => AccountInfo(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.source,
    required this.date,
    this.category,
    this.account,
    this.description,
  });

  final String id;
  final double amount;
  final TransactionType type;
  final TransactionSource source;
  final DateTime date;
  final CategoryInfo? category;
  final AccountInfo? account;
  final String? description;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransactionType.EXPENSE,
        ),
        source: TransactionSource.values.firstWhere(
          (e) => e.name == json['source'],
          orElse: () => TransactionSource.MANUAL,
        ),
        date: DateTime.parse(json['date'] as String),
        category: json['category'] != null
            ? CategoryInfo.fromJson(json['category'] as Map<String, dynamic>)
            : null,
        account: json['account'] != null
            ? AccountInfo.fromJson(json['account'] as Map<String, dynamic>)
            : null,
        description: json['description'] as String?,
      );
}
