import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/core/utils/date_formatter.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_preview_bloc.dart';

class DateField extends StatelessWidget {
  const DateField({super.key, required this.state});
  final ReceiptPreviewReady state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: state.effectiveDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.dark(
                primary: ctx.colors.primary,
                onPrimary: ctx.colors.onPrimary,
                surface: ctx.colors.surfaceContainerHigh,
                onSurface: ctx.colors.onSurface,
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
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Text(
              DateFormatter.formatLong(state.effectiveDate, context),
              style: TextStyle(color: colors.onSurface, fontSize: 14),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
