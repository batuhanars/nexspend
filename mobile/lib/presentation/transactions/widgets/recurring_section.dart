import 'package:flutter/material.dart';
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

  static const _frequencies = [
    (label: 'Günlük', value: 'DAILY'),
    (label: 'Haftalık', value: 'WEEKLY'),
    (label: 'Aylık', value: 'MONTHLY'),
    (label: 'Yıllık', value: 'YEARLY'),
  ];

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  Widget build(BuildContext context) {
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
                    'Tekrarlayan İşlem',
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
                    'Sıklık',
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: _frequencies.map((f) {
                      final isActive = frequency == f.value;
                      final isLast = f == _frequencies.last;
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
                                ? 'Bitiş tarihi (opsiyonel)'
                                : '${endDate!.day} ${_months[endDate!.month - 1]} ${endDate!.year}',
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
