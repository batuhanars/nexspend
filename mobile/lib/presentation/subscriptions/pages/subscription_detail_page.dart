import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/data/models/subscription_model.dart';
import 'package:wallet_app/presentation/subscriptions/bloc/subscriptions_bloc.dart';

class SubscriptionDetailPage extends StatefulWidget {
  const SubscriptionDetailPage({super.key, required this.subscription});
  final SubscriptionModel subscription;

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  late SubscriptionModel _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.subscription;
  }

  void _toggle() {
    context.read<SubscriptionsBloc>().add(SubscriptionToggleRequested(_sub.id));
    setState(() {
      _sub = SubscriptionModel(
        id: _sub.id,
        name: _sub.name,
        amount: _sub.amount,
        billingCycle: _sub.billingCycle,
        isActive: !_sub.isActive,
        autoDeduct: _sub.autoDeduct,
        description: _sub.description,
        icon: _sub.icon,
        color: _sub.color,
        accountId: _sub.accountId,
        accountName: _sub.accountName,
        nextRenewalDate: _sub.nextRenewalDate,
        categoryId: _sub.categoryId,
        categoryName: _sub.categoryName,
      );
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Aboneliği Sil', style: AppTypography.titleSm),
        content: Text(
          '${_sub.name} aboneliği silinecek. Gelecek ödemeler durur.',
          style:
              AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context
          .read<SubscriptionsBloc>()
          .add(SubscriptionDeleteRequested(_sub.id));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _sub.cardColor;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_sub.name, style: AppTypography.headlineSm),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _HeaderCard(sub: _sub, color: color),
          const SizedBox(height: AppSpacing.xl),
          _DetailsCard(sub: _sub),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _toggle,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: _sub.isActive
                  ? AppColors.surfaceContainerHighest
                  : AppColors.primary,
              foregroundColor:
                  _sub.isActive ? AppColors.onSurfaceVariant : AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Text(
              _sub.isActive ? 'Aboneliği Durdur' : 'Aboneliği Etkinleştir',
              style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.sub, required this.color});
  final SubscriptionModel sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(Icons.subscriptions_outlined, color: color, size: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            CurrencyFormatter.format(sub.amount),
            style: AppTypography.headlineMd.copyWith(color: color),
          ),
          Text(sub.billingCycle.label, style: AppTypography.bodySm),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: sub.isActive
                  ? AppColors.secondary.withValues(alpha: 0.12)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              sub.isActive ? 'Aktif' : 'Pasif',
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w600,
                color: sub.isActive
                    ? AppColors.secondary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.sub});
  final SubscriptionModel sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detaylar', style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.md),
          if (sub.description != null) ...[
            _DetailRow(label: 'Açıklama', value: sub.description!),
            const Divider(color: AppColors.surfaceContainerHighest, height: 1),
          ],
          if (sub.categoryName != null) ...[
            _DetailRow(label: 'Kategori', value: sub.categoryName!),
            const Divider(color: AppColors.surfaceContainerHighest, height: 1),
          ],
          if (sub.accountName != null) ...[
            _DetailRow(label: 'Hesap', value: sub.accountName!),
            const Divider(color: AppColors.surfaceContainerHighest, height: 1),
          ],
          _DetailRow(
            label: 'Otomatik Kesinti',
            value: sub.autoDeduct ? 'Açık' : 'Kapalı',
          ),
          if (sub.nextRenewalDate != null) ...[
            const Divider(color: AppColors.surfaceContainerHighest, height: 1),
            _DetailRow(
              label: 'Sonraki Yenilenme',
              value: _formatDate(sub.nextRenewalDate!),
              valueColor:
                  sub.isRenewingSoon ? AppColors.warning : null,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant)),
          Text(
            value,
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
