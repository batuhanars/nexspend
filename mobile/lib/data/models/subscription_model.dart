// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum BillingCycle { DAILY, WEEKLY, MONTHLY, YEARLY }

extension BillingCycleX on BillingCycle {
  String get label => switch (this) {
        BillingCycle.DAILY => 'Günlük',
        BillingCycle.WEEKLY => 'Haftalık',
        BillingCycle.MONTHLY => 'Aylık',
        BillingCycle.YEARLY => 'Yıllık',
      };
}

class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.isActive,
    required this.autoDeduct,
    this.description,
    this.icon,
    this.color,
    this.accountId,
    this.accountName,
    this.nextRenewalDate,
    this.categoryId,
    this.categoryName,
  });

  final String id;
  final String name;
  final double amount;
  final BillingCycle billingCycle;
  final bool isActive;
  final bool autoDeduct;
  final String? description;
  final String? icon;
  final String? color;
  final String? accountId;
  final String? accountName;
  final DateTime? nextRenewalDate;
  final String? categoryId;
  final String? categoryName;

  Color get cardColor {
    if (color != null) {
      try {
        return Color(int.parse('FF${color!.replaceAll('#', '')}', radix: 16));
      } catch (_) {}
    }
    return AppColors.primary;
  }

  bool get isRenewingSoon {
    if (nextRenewalDate == null) return false;
    final diff = nextRenewalDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionModel(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        billingCycle: BillingCycle.values.firstWhere(
          (e) => e.name == json['billingCycle'],
          orElse: () => BillingCycle.MONTHLY,
        ),
        isActive: json['isActive'] as bool? ?? true,
        autoDeduct: json['autoDeduct'] as bool? ?? true,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        accountId: json['accountId'] as String?,
        accountName: json['account']?['name'] as String?,
        nextRenewalDate: json['nextRenewalDate'] != null
            ? DateTime.parse(json['nextRenewalDate'] as String)
            : null,
        categoryId: json['categoryId'] as String?,
        categoryName: json['category']?['name'] as String?,
      );
}

class SubscriptionSummaryModel {
  const SubscriptionSummaryModel({
    required this.totalMonthly,
    required this.activeCount,
  });

  final double totalMonthly;
  final int activeCount;

  factory SubscriptionSummaryModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionSummaryModel(
        totalMonthly: (json['totalMonthly'] as num? ?? 0).toDouble(),
        activeCount: json['activeCount'] as int? ?? 0,
      );

  factory SubscriptionSummaryModel.empty() =>
      const SubscriptionSummaryModel(totalMonthly: 0, activeCount: 0);
}
