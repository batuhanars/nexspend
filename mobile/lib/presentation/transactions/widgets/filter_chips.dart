import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../bloc/transactions_bloc.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({super.key, required this.activeFilter});
  final String? activeFilter;

  static const _filters = [
    (label: 'Hepsi', value: null),
    (label: 'Gelir', value: 'INCOME'),
    (label: 'Gider', value: 'EXPENSE'),
    (label: 'Transfer', value: 'TRANSFER'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: _filters.map((f) {
          final isActive = activeFilter == f.value;
          final isLast = f == _filters.last;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
              child: GestureDetector(
                onTap: () => context
                    .read<TransactionsBloc>()
                    .add(TransactionsFilterChanged(f.value)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surfaceContainerHigh,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    border: isActive
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    f.label,
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
      ),
    );
  }
}
