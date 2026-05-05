import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/core/utils/date_formatter.dart';
import 'package:wallet_app/data/models/debt_model.dart';

class InstallmentRow extends StatelessWidget {
  const InstallmentRow({
    super.key,
    required this.installment,
    this.onPay,
    this.isLent = false,
  });
  final DebtInstallmentModel installment;
  final VoidCallback? onPay;
  final bool isLent;

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
                  AppStrings.of(context).installmentNo(installment.installmentNo),
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
          if (!isPaid && onPay != null)
            TextButton(
              onPressed: onPay,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 0,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isLent ? AppStrings.of(context).collectBtn : AppStrings.of(context).payBtn,
                style: AppTypography.labelSm.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(installment.amount),
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isPaid ? AppColors.onSurfaceVariant : color,
                    decoration: isPaid ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (installment.paidAmount > 0 && !isPaid)
                  Text(
                    AppStrings.of(context).partiallyPaid(CurrencyFormatter.formatCompact(installment.paidAmount)),
                    style: AppTypography.bodySm,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
