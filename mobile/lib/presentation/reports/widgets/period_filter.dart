import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/presentation/reports/bloc/reports_bloc.dart';

class PeriodFilter extends StatelessWidget {
  const PeriodFilter({super.key, required this.activePeriod});
  final String activePeriod;

  static const _periods = [
    (label: 'Bu Ay', value: 'THIS_MONTH'),
    (label: '3 Ay', value: 'LAST_3_MONTHS'),
    (label: 'Bu Yıl', value: 'THIS_YEAR'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _periods.map((p) {
        final isActive = activePeriod == p.value;
        final isLast = p == _periods.last;
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
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: isActive
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  p.label,
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
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
