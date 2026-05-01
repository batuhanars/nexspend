// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
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
    this.endDate,
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
  final DateTime? endDate;
  final CategoryModel? category;

  Color get statusColor => switch (status) {
        BudgetStatus.OK => const Color(0xFF70D8C8),
        BudgetStatus.WARNING => const Color(0xFFFFB68F),
        BudgetStatus.CRITICAL => const Color(0xFFFF9800),
        BudgetStatus.EXCEEDED => const Color(0xFFEF5350),
      };

  String get statusLabel => switch (status) {
        BudgetStatus.OK => 'Normal',
        BudgetStatus.WARNING => 'Uyarı',
        BudgetStatus.CRITICAL => 'Kritik',
        BudgetStatus.EXCEEDED => 'Aşıldı',
      };

  String get periodLabel => switch (period) {
        BudgetPeriod.MONTHLY => 'Aylık',
        BudgetPeriod.WEEKLY => 'Haftalık',
        BudgetPeriod.YEARLY => 'Yıllık',
        BudgetPeriod.CUSTOM => 'Özel',
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
            : null,
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
