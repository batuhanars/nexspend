import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/data/models/subscription_model.dart';
import 'package:wallet_app/presentation/shared/widgets/split_amount_field.dart';
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

  Future<void> _showEditSheet() async {
    final nameCtrl = TextEditingController(text: _sub.name);
    double? pendingAmount = _sub.amount;
    String? savedName;
    double? savedAmount;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.xl,
                AppSpacing.pagePadding,
                MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Aboneliği Düzenle', style: AppTypography.headlineSm),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: SplitAmountField(
                      initialValue: _sub.amount,
                      onChanged: (v) => pendingAmount = v,
                      color: AppColors.tertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Abonelik adı',
                      hintStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                      prefixIcon: const Icon(Icons.subscriptions_outlined, size: 20, color: AppColors.onSurfaceVariant),
                      filled: true,
                      fillColor: AppColors.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty || pendingAmount == null || pendingAmount! <= 0) return;
                      savedName = name;
                      savedAmount = pendingAmount;
                      Navigator.of(ctx).pop();
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                    ),
                    child: Text(AppStrings.of(ctx).save),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();

    if (savedName != null && savedAmount != null && mounted) {
      context.read<SubscriptionsBloc>().add(
        SubscriptionUpdateRequested(
          id: _sub.id,
          name: savedName!,
          amount: savedAmount!,
        ),
      );
      setState(() {
        _sub = _sub.copyWith(name: savedName, amount: savedAmount);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).subscriptionUpdatedSuccess),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(AppStrings.of(context).deleteSubscriptionTitle, style: AppTypography.titleSm),
        content: Text(
          '${_sub.name} aboneliği silinecek. Gelecek ödemeler durur.',
          style: AppTypography.bodyMd
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.of(context).delete, style: TextStyle(color: AppColors.error)),
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
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditSheet,
          ),
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
              style: AppTypography.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
                color: _sub.isActive
                    ? AppColors.onSurfaceVariant
                    : AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
