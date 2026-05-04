// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum DebtType { LENT, BORROWED }

enum DebtStatus { PENDING, PAID, OVERDUE }

extension DebtTypeX on DebtType {
  String get label => this == DebtType.LENT ? 'Alacak' : 'Borç';
  Color get color => this == DebtType.LENT ? AppColors.secondary : AppColors.tertiary;
  IconData get icon => this == DebtType.LENT ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
}

extension DebtStatusX on DebtStatus {
  String get label => switch (this) {
        DebtStatus.PENDING => 'Beklemede',
        DebtStatus.PAID => 'Ödendi',
        DebtStatus.OVERDUE => 'Gecikmiş',
      };

  Color get color => switch (this) {
        DebtStatus.PENDING => AppColors.warning,
        DebtStatus.PAID => AppColors.secondary,
        DebtStatus.OVERDUE => AppColors.error,
      };
}

class DebtModel {
  const DebtModel({
    required this.id,
    required this.type,
    required this.status,
    required this.personName,
    required this.totalAmount,
    required this.paidAmount,
    required this.hasInstallments,
    this.description,
    this.dueDate,
    this.paidDate,
  });

  final String id;
  final DebtType type;
  final DebtStatus status;
  final String personName;
  final double totalAmount;
  final double paidAmount;
  final bool hasInstallments;
  final String? description;
  final DateTime? dueDate;
  final DateTime? paidDate;

  double get remainingAmount => totalAmount - paidAmount;
  double get progress => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0;

  factory DebtModel.fromJson(Map<String, dynamic> json) => DebtModel(
        id: json['id'] as String,
        type: DebtType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DebtType.BORROWED,
        ),
        status: DebtStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DebtStatus.PENDING,
        ),
        personName: json['personName'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num? ?? 0).toDouble(),
        hasInstallments: json['hasInstallments'] as bool? ?? false,
        description: json['description'] as String?,
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
        paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate'] as String) : null,
      );
}

class DebtSummaryModel {
  const DebtSummaryModel({
    required this.totalLent,
    required this.totalBorrowed,
    required this.totalLentRemaining,
    required this.totalBorrowedRemaining,
  });

  final double totalLent;
  final double totalBorrowed;
  final double totalLentRemaining;
  final double totalBorrowedRemaining;

  factory DebtSummaryModel.fromJson(Map<String, dynamic> json) =>
      DebtSummaryModel(
        totalLent: (json['totalLent'] as num? ?? 0).toDouble(),
        totalBorrowed: (json['totalBorrowed'] as num? ?? 0).toDouble(),
        totalLentRemaining: (json['remainingLent'] as num? ?? 0).toDouble(),
        totalBorrowedRemaining:
            (json['remainingBorrowed'] as num? ?? 0).toDouble(),
      );

  factory DebtSummaryModel.empty() => const DebtSummaryModel(
        totalLent: 0,
        totalBorrowed: 0,
        totalLentRemaining: 0,
        totalBorrowedRemaining: 0,
      );
}

class DebtPaymentModel {
  const DebtPaymentModel({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.note,
    this.installmentId,
  });

  final String id;
  final double amount;
  final DateTime paidAt;
  final String? note;
  final String? installmentId;

  factory DebtPaymentModel.fromJson(Map<String, dynamic> json) =>
      DebtPaymentModel(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        paidAt: DateTime.parse(json['paidAt'] as String),
        note: json['note'] as String?,
        installmentId: json['installmentId'] as String?,
      );
}

class DebtInstallmentModel {
  const DebtInstallmentModel({
    required this.id,
    required this.installmentNo,
    required this.amount,
    required this.paidAmount,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final int installmentNo;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final DebtStatus status;

  double get remainingAmount => amount - paidAmount;

  factory DebtInstallmentModel.fromJson(Map<String, dynamic> json) =>
      DebtInstallmentModel(
        id: json['id'] as String,
        installmentNo: json['installmentNo'] as int,
        amount: (json['amount'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num? ?? 0).toDouble(),
        dueDate: DateTime.parse(json['dueDate'] as String),
        status: DebtStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DebtStatus.PENDING,
        ),
      );
}
