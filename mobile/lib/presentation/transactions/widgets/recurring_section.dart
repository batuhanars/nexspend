import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class RecurringSection extends StatelessWidget {
  const RecurringSection({
    super.key,
    required this.isRecurring,
    required this.frequency,
    this.endDate,
    required this.onToggle,
    required this.onFrequencyChanged,
    required this.onEndDateChanged,
  });
  final bool isRecurring;
  final String frequency;
  final DateTime? endDate;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onFrequencyChanged;
  final ValueChanged<DateTime?> onEndDateChanged;

  List<({String label, String value})> _frequencies(BuildContext context) {
    final s = AppStrings.of(context);
    return [
      (label: s.billingCycleDaily, value: 'DAILY'),
      (label: s.billingCycleWeekly, value: 'WEEKLY'),
      (label: s.billingCycleMonthly, value: 'MONTHLY'),
      (label: s.billingCycleYearly, value: 'YEARLY'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final freqs = _frequencies(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(Icons.repeat_rounded,
                    size: 20, color: AppColors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    s.recurringTransaction,
                    style: AppTypography.bodyMd,
                  ),
                ),
                Switch(
                  value: isRecurring,
                  onChanged: onToggle,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor:
                      AppColors.primary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          if (isRecurring) ...[
            const Divider(
                height: 1, color: AppColors.surfaceContainerHighest),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.recurringFrequencyLabel,
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: freqs.map((f) {
                      final isActive = frequency == f.value;
                      final isLast = f == freqs.last;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: isLast ? 0 : AppSpacing.xs),
                          child: GestureDetector(
                            onTap: () => onFrequencyChanged(f.value),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.surfaceContainerHighest,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: isActive
                                    ? Border.all(
                                        color: AppColors.primary, width: 1.5)
                                    : null,
                              ),
                              child: Text(
                                f.label,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
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
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2040),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                                  primary: AppColors.primary,
                                  surface: AppColors.surfaceContainerHigh,
                                ),
                          ),
                          child: child!,
                        ),
                      );
                      onEndDateChanged(picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_outlined,
                              size: 16,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            endDate == null
                                ? s.endDateOptional
                                : '${endDate!.day} ${s.monthName(endDate!.month)} ${endDate!.year}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: endDate == null
                                  ? AppColors.onSurfaceVariant
                                  : AppColors.onSurface,
                            ),
                          ),
                          if (endDate != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            GestureDetector(
                              onTap: () => onEndDateChanged(null),
                              child: const Icon(Icons.close_rounded,
                                  size: 14,
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
