import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/data/models/subscription_model.dart';
import 'package:wallet_app/presentation/subscriptions/bloc/subscriptions_bloc.dart';
import 'package:wallet_app/presentation/subscriptions/widgets/subscription_details_card.dart';
import 'package:wallet_app/presentation/subscriptions/widgets/subscription_header_card.dart';

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
          style: AppTypography.bodyMd
              .copyWith(color: AppColors.onSurfaceVariant),
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
          SubscriptionHeaderCard(sub: _sub),
          const SizedBox(height: AppSpacing.xl),
          SubscriptionDetailsCard(sub: _sub),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _toggle,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: _sub.isActive
                  ? AppColors.surfaceContainerHighest
                  : AppColors.primary,
              foregroundColor: _sub.isActive
                  ? AppColors.onSurfaceVariant
                  : AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Text(
              _sub.isActive ? 'Aboneliği Durdur' : 'Aboneliği Etkinleştir',
              style:
                  AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
