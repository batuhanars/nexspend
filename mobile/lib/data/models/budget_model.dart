// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import 'category_model.dart';

enum BudgetStatus { OK, WARNING, CRITICAL, EXCEEDED }

enum BudgetPeriod { MONTHLY, WEEKLY, YEARLY, CUSTOM }

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.status,
    required this.period,
    required this.smartTracking,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    this.category,
  });

  final String id;
  final String name;
  final double amount;
  final double spent;
  final double remaining;
  final int percentage;
  final BudgetStatus status;
  final BudgetPeriod period;
  final bool smartTracking;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final CategoryModel? category;

  Color get statusColor => switch (status) {
        BudgetStatus.OK => const Color(0xFF70D8C8),
        BudgetStatus.WARNING => const Color(0xFFFFB68F),
        BudgetStatus.CRITICAL => const Color(0xFFFF9800),
        BudgetStatus.EXCEEDED => const Color(0xFFEF5350),
      };

  String statusLabel(AppStrings s) => switch (status) {
        BudgetStatus.OK => s.budgetStatusOk,
        BudgetStatus.WARNING => s.budgetStatusWarning,
        BudgetStatus.CRITICAL => s.budgetStatusCritical,
        BudgetStatus.EXCEEDED => s.budgetStatusExceeded,
      };

  String periodLabel(AppStrings s) => switch (period) {
        BudgetPeriod.MONTHLY => s.billingCycleMonthly,
        BudgetPeriod.WEEKLY => s.billingCycleWeekly,
        BudgetPeriod.YEARLY => s.billingCycleYearly,
        BudgetPeriod.CUSTOM => s.budgetPeriodCustom,
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        remaining: (json['remaining'] as num).toDouble(),
        percentage: (json['percentage'] as num).toInt(),
        status: BudgetStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => BudgetStatus.OK,
        ),
        period: BudgetPeriod.values.firstWhere(
          (e) => e.name == json['period'],
          orElse: () => BudgetPeriod.MONTHLY,
        ),
        smartTracking: json['smartTracking'] as bool? ?? true,
        isActive: json['isActive'] as bool? ?? true,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : DateTime.parse(json['startDate'] as String),
        category: json['category'] != null
            ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
            : null,
      );
}

class BudgetOverviewModel {
  const BudgetOverviewModel({
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.percentage,
    required this.count,
  });

  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final int percentage;
  final int count;

  factory BudgetOverviewModel.fromJson(Map<String, dynamic> json) =>
      BudgetOverviewModel(
        totalBudget: (json['totalBudget'] as num).toDouble(),
        totalSpent: (json['totalSpent'] as num).toDouble(),
        remaining: (json['remaining'] as num).toDouble(),
        percentage: (json['percentage'] as num).toInt(),
        count: (json['count'] as num).toInt(),
      );

  static BudgetOverviewModel empty() => const BudgetOverviewModel(
        totalBudget: 0,
        totalSpent: 0,
        remaining: 0,
        percentage: 0,
        count: 0,
      );
}

class BudgetHistoryEntry {
  const BudgetHistoryEntry({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.spent,
    required this.percentage,
    required this.isActive,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final double spent;
  final double percentage;
  final bool isActive;

  factory BudgetHistoryEntry.fromJson(Map<String, dynamic> json) =>
      BudgetHistoryEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        amount: (json['amount'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        isActive: json['isActive'] as bool? ?? false,
      );
}
