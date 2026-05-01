import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/icon_mapper.dart';

class MonthlyFlowModel {
  const MonthlyFlowModel({
    required this.month,
    required this.income,
    required this.expense,
  });

  final String month; // "2026-04"
  final double income;
  final double expense;

  factory MonthlyFlowModel.fromJson(Map<String, dynamic> json) =>
      MonthlyFlowModel(
        month: json['month'] as String,
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
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
      return AppColors.onSurfaceVariant;
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
  });

  final List<MonthlyFlowModel> months;
  final List<CategoryBreakdownModel> topCategories;

  double get currentMonthIncome => months.isEmpty ? 0 : months.last.income;
  double get currentMonthExpense => months.isEmpty ? 0 : months.last.expense;

  double get maxMonthlyValue => months.fold<double>(
        0,
        (m, e) => m > e.income
            ? (m > e.expense ? m : e.expense)
            : (e.income > e.expense ? e.income : e.expense),
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
      );

  static AccountAnalyticsModel empty() => const AccountAnalyticsModel(
        months: [],
        topCategories: [],
      );
}
