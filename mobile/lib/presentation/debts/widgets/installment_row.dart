import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/core/utils/date_formatter.dart';
import 'package:wallet_app/data/models/debt_model.dart';

class InstallmentRow extends StatelessWidget {
  const InstallmentRow({super.key, required this.installment});
  final DebtInstallmentModel installment;

  @override
  Widget build(BuildContext context) {
    final isPaid = installment.status == DebtStatus.PAID;
    final isOverdue = installment.status == DebtStatus.OVERDUE;
    final color = installment.status.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isPaid
                  ? Icon(Icons.check_rounded, size: 14, color: color)
                  : Text(
                      '${installment.installmentNo}',
                      style: AppTypography.labelSm.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${installment.installmentNo}. Taksit',
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isPaid
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                    decoration:
                        isPaid ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  DateFormatter.formatLong(installment.dueDate),
                  style: AppTypography.bodySm.copyWith(
                    color: isOverdue
                        ? AppColors.error
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(installment.amount),
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPaid ? AppColors.onSurfaceVariant : color,
                  decoration:
                      isPaid ? TextDecoration.lineThrough : null,
                ),
              ),
              if (installment.paidAmount > 0 && !isPaid)
                Text(
                  '${CurrencyFormatter.formatCompact(installment.paidAmount)} ödendi',
                  style: AppTypography.bodySm,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
