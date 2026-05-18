import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/utils/date_formatter.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_preview_bloc.dart';

class DateField extends StatelessWidget {
  const DateField({super.key, required this.state});
  final ReceiptPreviewReady state;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: state.effectiveDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: AppColors.onPrimary,
                surface: AppColors.surfaceContainerHigh,
                onSurface: AppColors.onSurface,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null && context.mounted) {
          context.read<ReceiptPreviewBloc>().add(
            ReceiptPreviewFieldUpdated(date: picked),
          );
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              DateFormatter.formatLong(state.effectiveDate, context),
              style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
