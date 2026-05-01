class ExpenseDistributionItem {
  const ExpenseDistributionItem({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
    required this.percentage,
  });

  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String? categoryColor;
  final double amount;
  final double percentage;

  factory ExpenseDistributionItem.fromJson(Map<String, dynamic> json) =>
      ExpenseDistributionItem(
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? 'Diğer',
        categoryIcon: json['categoryIcon'] as String? ?? 'category',
        categoryColor: json['categoryColor'] as String?,
        amount: (json['amount'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
      );
}

class CashFlowItem {
  const CashFlowItem({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.net,
  });

  final int month;
  final int year;
  final double income;
  final double expense;
  final double net;

  String get label {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return months[month - 1];
  }

  factory CashFlowItem.fromJson(Map<String, dynamic> json) => CashFlowItem(
        month: json['month'] as int,
        year: json['year'] as int,
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
        net: (json['net'] as num).toDouble(),
      );
}

class TrendItem {
  const TrendItem({
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
    required this.changePercent,
  });

  final String categoryName;
  final double currentAmount;
  final double previousAmount;
  final double changePercent;

  bool get isIncrease => changePercent >= 0;

  factory TrendItem.fromJson(Map<String, dynamic> json) => TrendItem(
        categoryName: json['categoryName'] as String,
        currentAmount: (json['currentAmount'] as num).toDouble(),
        previousAmount: (json['previousAmount'] as num).toDouble(),
        changePercent: (json['changePercent'] as num).toDouble(),
      );
}
