import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_palette.dart';

class TransactionDatePicker extends StatelessWidget {
  const TransactionDatePicker({
    super.key,
    required this.date,
    required this.onChanged,
  });
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final label = isToday
        ? s.todayLabel
        : '${date.day} ${s.monthName(date.month)} ${date.year}';

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                    primary: ctx.colors.primary,
                    surface: ctx.colors.surfaceContainerHigh,
                  ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(color: colors.onSurface, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
