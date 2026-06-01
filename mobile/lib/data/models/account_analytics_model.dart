import 'package:flutter/material.dart';
import '../../core/utils/icon_mapper.dart';

class MonthlyFlowModel {
  const MonthlyFlowModel({
    required this.month,
    required this.income,
    required this.expense,
    this.payment,
    this.spend,
  });

  final String month; // "2026-04"
  final double income;
  final double expense;
  final double? payment; // kredi kartı: TRANSFER toAccountId=card
  final double? spend;   // kredi kartı: EXPENSE accountId=card

  factory MonthlyFlowModel.fromJson(Map<String, dynamic> json) =>
      MonthlyFlowModel(
        month: json['month'] as String,
        income: (json['income'] as num?)?.toDouble() ?? 0.0,
        expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
        payment: (json['payment'] as num?)?.toDouble(),
        spend: (json['spend'] as num?)?.toDouble(),
      );
}

class CategoryBreakdownModel {
  const CategoryBreakdownModel({
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    this.categoryId,
  });

  final String? categoryId;
  final String name;
  final String icon;
  final String color;
  final double amount;

  IconData get iconData => IconMapper.fromString(icon);

  Color get cardColor {
    try {
      return Color(int.parse('FF${color.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFFC6C5D4); // fallback: dark onSurfaceVariant
    }
  }

  factory CategoryBreakdownModel.fromJson(Map<String, dynamic> json) =>
      CategoryBreakdownModel(
        categoryId: json['categoryId'] as String?,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'category',
        color: json['color'] as String? ?? '#9E9E9E',
        amount: (json['amount'] as num).toDouble(),
      );
}

class AccountAnalyticsModel {
  const AccountAnalyticsModel({
    required this.months,
    required this.topCategories,
    this.isCreditCard = false,
  });

  final List<MonthlyFlowModel> months;
  final List<CategoryBreakdownModel> topCategories;
  final bool isCreditCard;

  double get currentMonthIncome => months.isEmpty ? 0 : months.last.income;
  double get currentMonthExpense => months.isEmpty ? 0 : months.last.expense;
  double get currentMonthPayment =>
      months.isEmpty ? 0 : (months.last.payment ?? 0);
  double get currentMonthSpend =>
      months.isEmpty ? 0 : (months.last.spend ?? 0);

  double get maxMonthlyValue => months.fold<double>(
        0,
        (m, e) {
          if (isCreditCard) {
            final p = e.payment ?? 0;
            final s = e.spend ?? 0;
            return m > p ? (m > s ? m : s) : (p > s ? p : s);
          }
          return m > e.income
              ? (m > e.expense ? m : e.expense)
              : (e.income > e.expense ? e.income : e.expense);
        },
      );

  factory AccountAnalyticsModel.fromJson(Map<String, dynamic> json) =>
      AccountAnalyticsModel(
        months: (json['months'] as List)
            .map((m) => MonthlyFlowModel.fromJson(m as Map<String, dynamic>))
            .toList(),
        topCategories: (json['topCategories'] as List)
            .map((c) =>
                CategoryBreakdownModel.fromJson(c as Map<String, dynamic>))
            .toList(),
        isCreditCard: json['isCreditCard'] as bool? ?? false,
      );

  static AccountAnalyticsModel empty() => const AccountAnalyticsModel(
        months: [],
        topCategories: [],
      );
}
