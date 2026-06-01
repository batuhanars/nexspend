import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/constants/api_endpoints.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/core/widgets/authenticated_image.dart';
import 'package:wallet_app/data/models/receipt_model.dart';
import 'package:wallet_app/navigation/route_names.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_history_bloc.dart';

class ReceiptHistoryTile extends StatelessWidget {
  const ReceiptHistoryTile({super.key, required this.receipt});
  final ReceiptHistoryModel receipt;

  Color _statusColor(AppPalette colors) => switch (receipt.status) {
        ReceiptStatus.CONFIRMED => colors.success,
        ReceiptStatus.PARSED => colors.primary,
        ReceiptStatus.PROCESSING => colors.warning,
        ReceiptStatus.FAILED => colors.error,
      };

  IconData get _statusIcon => switch (receipt.status) {
        ReceiptStatus.CONFIRMED => Icons.check_circle_outline_rounded,
        ReceiptStatus.PARSED => Icons.receipt_long_outlined,
        ReceiptStatus.PROCESSING => Icons.hourglass_empty_rounded,
        ReceiptStatus.FAILED => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = _statusColor(colors);

    return Dismissible(
      key: ValueKey(receipt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: colors.errorContainer,
        child: Icon(Icons.delete_outline_rounded, color: colors.error),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => context
          .read<ReceiptHistoryBloc>()
          .add(ReceiptHistoryDeleteRequested(receipt.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.xs,
        ),
        child: Material(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: receipt.hasImage
                ? () => context.push(RouteNames.receiptImage(receipt.id))
                : null,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  _buildLeading(statusColor),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.merchantName ??
                              AppStrings.of(context).unknownMerchant,
                          style: AppTypography.bodyMd
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          receipt.date != null
                              ? _formatDate(receipt.date!)
                              : AppStrings.of(context).unknownDate,
                          style: AppTypography.bodySm
                              .copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (receipt.amount != null)
                        Text(
                          CurrencyFormatter.format(receipt.amount!),
                          style: AppTypography.titleSm
                              .copyWith(color: colors.expense),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      _StatusBadge(status: receipt.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(Color statusColor) {
    final placeholder = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(_statusIcon, color: statusColor, size: 22),
    );
    if (!receipt.hasImage) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(
        width: 44,
        height: 44,
        child: AuthenticatedImage(
          urlPath: ApiEndpoints.receiptImage(receipt.id),
          cacheKey: receipt.id,
          fit: BoxFit.cover,
          placeholder: placeholder,
          errorWidget: placeholder,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerHigh,
          title: Text(AppStrings.of(context).deleteReceiptTitle, style: AppTypography.titleSm),
          content: Text(
            AppStrings.of(context).receiptDeleteContent,
            style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppStrings.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppStrings.of(context).delete, style: TextStyle(color: colors.error)),
            ),
          ],
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    final (label, color) = switch (status) {
      ReceiptStatus.CONFIRMED => (s.receiptStatusConfirmed, colors.success),
      ReceiptStatus.PARSED => (s.receiptStatusParsed, colors.primary),
      ReceiptStatus.PROCESSING => (s.receiptStatusProcessing, colors.warning),
      ReceiptStatus.FAILED => (s.receiptStatusFailed, colors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
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
