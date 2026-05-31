// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_strings.dart';

enum BillingCycle { DAILY, WEEKLY, MONTHLY, YEARLY }

extension BillingCycleX on BillingCycle {
  String label(AppStrings s) => switch (this) {
        BillingCycle.DAILY => s.billingCycleDaily,
        BillingCycle.WEEKLY => s.billingCycleWeekly,
        BillingCycle.MONTHLY => s.billingCycleMonthly,
        BillingCycle.YEARLY => s.billingCycleYearly,
      };
}

enum SubscriptionKind { SUBSCRIPTION, BILL }

extension SubscriptionKindX on SubscriptionKind {
  String label(AppStrings s) => switch (this) {
        SubscriptionKind.SUBSCRIPTION => s.kindSubscription,
        SubscriptionKind.BILL => s.kindBill,
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
    this.kind = SubscriptionKind.SUBSCRIPTION,
    this.reminderDaysBefore = 3,
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
  final SubscriptionKind kind;
  final int reminderDaysBefore;
  final String? description;
  final String? icon;
  final String? color;
  final String? accountId;
  final String? accountName;
  final DateTime? nextRenewalDate;
  final String? categoryId;
  final String? categoryName;

  bool get isBill => kind == SubscriptionKind.BILL;

  Color get cardColor {
    if (color != null) {
      try {
        return Color(int.parse('FF${color!.replaceAll('#', '')}', radix: 16));
      } catch (_) {}
    }
    return AppColors.primary;
  }

  SubscriptionModel copyWith({
    String? name,
    double? amount,
    BillingCycle? billingCycle,
    bool? isActive,
    bool? autoDeduct,
    SubscriptionKind? kind,
    int? reminderDaysBefore,
    String? description,
    String? icon,
    String? color,
    String? accountId,
    String? accountName,
    DateTime? nextRenewalDate,
    String? categoryId,
    String? categoryName,
  }) =>
      SubscriptionModel(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        billingCycle: billingCycle ?? this.billingCycle,
        isActive: isActive ?? this.isActive,
        autoDeduct: autoDeduct ?? this.autoDeduct,
        kind: kind ?? this.kind,
        reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        accountId: accountId ?? this.accountId,
        accountName: accountName ?? this.accountName,
        nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
      );

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
          (e) => e.name == (json['period'] ?? json['billingCycle']),
          orElse: () => BillingCycle.MONTHLY,
        ),
        isActive: json['isActive'] as bool? ?? true,
        autoDeduct: json['autoDeduct'] as bool? ?? true,
        kind: SubscriptionKind.values.firstWhere(
          (e) => e.name == json['kind'],
          orElse: () => SubscriptionKind.SUBSCRIPTION,
        ),
        reminderDaysBefore: json['reminderDaysBefore'] as int? ?? 3,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        accountId: json['accountId'] as String?,
        accountName: json['account']?['name'] as String?,
        nextRenewalDate: (json['nextRenewal'] ?? json['nextRenewalDate']) != null
            ? DateTime.parse((json['nextRenewal'] ?? json['nextRenewalDate']) as String)
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
