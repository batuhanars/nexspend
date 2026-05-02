// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/icon_mapper.dart';

enum AccountType { BANK, CASH, CREDIT_CARD, INVESTMENT }

extension AccountTypeX on AccountType {
  String get label => switch (this) {
        AccountType.BANK => 'Banka',
        AccountType.CASH => 'Nakit',
        AccountType.CREDIT_CARD => 'Kredi Kartı',
        AccountType.INVESTMENT => 'Yatırım',
      };

  IconData get defaultIcon => switch (this) {
        AccountType.BANK => Icons.account_balance_outlined,
        AccountType.CASH => Icons.account_balance_wallet_outlined,
        AccountType.CREDIT_CARD => Icons.credit_card_outlined,
        AccountType.INVESTMENT => Icons.trending_up,
      };

  Color get defaultColor => switch (this) {
        AccountType.BANK => AppColors.primary,
        AccountType.CASH => AppColors.secondary,
        AccountType.CREDIT_CARD => AppColors.warning,
        AccountType.INVESTMENT => AppColors.tertiary,
      };
}

class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    this.icon,
    this.color,
    required this.isDefault,
    required this.isArchived,
    this.creditLimit,
    this.statementDay,
    this.paymentDueDay,
  });

  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final String? icon;
  final String? color;
  final bool isDefault;
  final bool isArchived;
  final double? creditLimit;
  final int? statementDay;
  final int? paymentDueDay;

  IconData get iconData =>
      icon != null ? IconMapper.fromString(icon) : type.defaultIcon;

  Color get cardColor {
    if (color != null) {
      try {
        return Color(int.parse('FF${color!.replaceAll('#', '')}', radix: 16));
      } catch (_) {}
    }
    return type.defaultColor;
  }

  double get creditUsed {
    if (type != AccountType.CREDIT_CARD || creditLimit == null) return 0;
    // balance is negative when debt exists (e.g. -500 means 500 TL owed)
    return (-balance).clamp(0.0, creditLimit!);
  }

  double get creditUsagePercent {
    if (type != AccountType.CREDIT_CARD ||
        creditLimit == null ||
        creditLimit == 0) {
      return 0;
    }
    return (creditUsed / creditLimit!).clamp(0.0, 1.0);
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AccountType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AccountType.BANK,
        ),
        balance: (json['balance'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'TRY',
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
        creditLimit: (json['creditLimit'] as num?)?.toDouble(),
        statementDay: json['statementDay'] as int?,
        paymentDueDay: json['paymentDueDay'] as int?,
      );
}
