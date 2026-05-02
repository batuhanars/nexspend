import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../bloc/subscriptions_bloc.dart';

class AddSubscriptionSheet extends StatefulWidget {
  const AddSubscriptionSheet({super.key});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _billingCycle = 'MONTHLY';
  bool _autoDeduct = true;

  static const _cycles = [
    (label: 'Günlük', value: 'DAILY'),
    (label: 'Haftalık', value: 'WEEKLY'),
    (label: 'Aylık', value: 'MONTHLY'),
    (label: 'Yıllık', value: 'YEARLY'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final amountStr = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (name.isEmpty || amount == null || amount <= 0) return;

    context.read<SubscriptionsBloc>().add(
      SubscriptionCreated({
        'name': name,
        'amount': amount,
        'billingCycle': _billingCycle,
        'autoDeduct': _autoDeduct,
      }),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Abonelik Ekle', style: AppTypography.headlineSm),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _field(
            _nameController,
            'Abonelik adı (Netflix, Spotify...)',
            Icons.subscriptions_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            _amountController,
            'Tutar (₺)',
            Icons.attach_money_rounded,
            numeric: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Fatura Dönemi',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _cycles.map((c) {
              final isActive = _billingCycle == c.value;
              final isLast = c == _cycles.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.xs),
                  child: GestureDetector(
                    onTap: () => setState(() => _billingCycle = c.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: isActive
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        c.label,
                        style: AppTypography.labelSm.copyWith(
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
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.autorenew_rounded,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Otomatik Kesinti',
                      style: AppTypography.bodyMd,
                    ),
                  ),
                  Switch(
                    value: _autoDeduct,
                    onChanged: (v) => setState(() => _autoDeduct = v),
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool numeric = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
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
    );
  }
}
