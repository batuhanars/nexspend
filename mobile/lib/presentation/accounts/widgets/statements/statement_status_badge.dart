import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../data/models/statement_model.dart';

class StatementStatusBadge extends StatelessWidget {
  const StatementStatusBadge({super.key, required this.status});
  final StatementStatus status;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final (label, color) = switch (status) {
      StatementStatus.PAID => (s.statementStatusPaid, AppColors.secondary),
      StatementStatus.DUE => (s.statementStatusDue, AppColors.primary),
      StatementStatus.PARTIALLY_PAID => (
          s.statementStatusPartiallyPaid,
          AppColors.warning,
        ),
      StatementStatus.OVERDUE => (s.statementStatusOverdue, AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
