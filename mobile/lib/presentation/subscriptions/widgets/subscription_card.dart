import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/data/models/subscription_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../navigation/route_names.dart';
import '../bloc/subscriptions_bloc.dart';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key, required this.sub});
  final SubscriptionModel sub;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Dismissible(
      key: ValueKey(sub.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: AppColors.errorContainer,
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        context.read<SubscriptionsBloc>().add(SubscriptionDeleteRequested(sub.id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.of(context).subscriptionDeletedSuccess),
          backgroundColor: AppColors.secondary,
        ));
      },
      child: GestureDetector(
        onTap: () async {
          final bloc = context.read<SubscriptionsBloc>();
          await context.push(RouteNames.subscriptionDetail(sub.id), extra: sub);
          if (context.mounted) bloc.add(const SubscriptionsRefreshRequested());
        },
        child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.xs,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sub.cardColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.subscriptions_outlined,
                  color: sub.cardColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sub.name,
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                              color: sub.isActive
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (sub.isRenewingSoon)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Text(
                              'Yakında',
                              style: AppTypography.labelSm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${sub.billingCycle.label(s)} • ${sub.accountName ?? ''}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (sub.nextRenewalDate != null)
                      Text(
                        '${s.nextRenewalLabel}: ${_formatDate(sub.nextRenewalDate!)}',
                        style: AppTypography.bodySm.copyWith(
                          color: sub.isRenewingSoon
                              ? AppColors.warning
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(sub.amount),
                    style: AppTypography.titleSm.copyWith(
                      color: sub.isActive
                          ? AppColors.tertiary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: () => context.read<SubscriptionsBloc>().add(
                      SubscriptionToggleRequested(sub.id),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: sub.isActive
                            ? AppColors.secondary.withValues(alpha: 0.12)
                            : AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        sub.isActive ? s.activeLabel : s.inactiveLabel,
                        style: AppTypography.labelSm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: sub.isActive
                              ? AppColors.secondary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(AppStrings.of(context).cancelSubscriptionTitle, style: AppTypography.titleSm),
        content: Text(
          '${sub.name} aboneliği silinecek. Gelecek ödemeler durur.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.of(context).delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
