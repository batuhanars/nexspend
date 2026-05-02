import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/core/utils/date_formatter.dart';
import 'package:wallet_app/data/models/debt_model.dart';

class PaymentRow extends StatelessWidget {
  const PaymentRow({super.key, required this.payment, required this.isLent});
  final DebtPaymentModel payment;
  final bool isLent;

  @override
  Widget build(BuildContext context) {
    final color = isLent ? AppColors.secondary : AppColors.tertiary;
    final label = isLent ? 'Tahsilat' : 'Ödeme';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLent
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (payment.note != null)
                  Text(
                    payment.note!,
                    style: AppTypography.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    DateFormatter.formatFull(payment.paidAt),
                    style: AppTypography.bodySm,
                  ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(payment.amount),
            style: AppTypography.titleSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
