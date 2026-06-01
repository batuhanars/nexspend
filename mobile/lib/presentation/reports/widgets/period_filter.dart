import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/presentation/reports/bloc/reports_bloc.dart';

class PeriodFilter extends StatelessWidget {
  const PeriodFilter({super.key, required this.activePeriod});
  final String activePeriod;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    final periods = [
      (label: s.periodThisMonth, value: 'THIS_MONTH'),
      (label: s.period3Months, value: 'LAST_3_MONTHS'),
      (label: s.periodThisYear, value: 'THIS_YEAR'),
    ];

    return Row(
      children: periods.map((p) {
        final isActive = activePeriod == p.value;
        final isLast = p == periods.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
            child: GestureDetector(
              onTap: () => context.read<ReportsBloc>().add(
                ReportsPeriodChanged(p.value),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: isActive
                      ? Border.all(color: colors.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  p.label,
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? colors.primary : colors.onSurfaceVariant,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
