import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/models/account_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../shared/widgets/split_amount_field.dart';
import '../bloc/subscriptions_bloc.dart';

class AddSubscriptionSheet extends StatefulWidget {
  const AddSubscriptionSheet({super.key});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _nameController = TextEditingController();

  double? _amount;
  String _period = 'MONTHLY';
  bool _autoDeduct = true;
  String? _selectedAccountId;
  late final Future<List<AccountModel>> _accountsFuture;

  List<({String label, String value})> _cycles(BuildContext context) {
    final s = AppStrings.of(context);
    return [
      (label: s.billingCycleDaily, value: 'DAILY'),
      (label: s.billingCycleWeekly, value: 'WEEKLY'),
      (label: s.billingCycleMonthly, value: 'MONTHLY'),
      (label: s.billingCycleYearly, value: 'YEARLY'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _accountsFuture = getIt<AccountRepository>().getAccounts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _calcNextRenewal() {
    final now = DateTime.now();
    final DateTime next;
    switch (_period) {
      case 'DAILY':
        next = now.add(const Duration(days: 1));
      case 'WEEKLY':
        next = now.add(const Duration(days: 7));
      case 'YEARLY':
        next = DateTime(now.year + 1, now.month, now.day);
      default:
        next = DateTime(now.year, now.month + 1, now.day);
    }
    return _isoDate(next);
  }

  void _submit() {
    final name = _nameController.text.trim();
    final amount = _amount;
    if (name.isEmpty || amount == null || amount <= 0) return;
    if (_selectedAccountId == null) return;

    final now = DateTime.now();
    context.read<SubscriptionsBloc>().add(
      SubscriptionCreated({
        'name': name,
        'amount': amount,
        'period': _period,
        'autoDeduct': _autoDeduct,
        'accountId': _selectedAccountId!,
        'startDate': _isoDate(now),
        'nextRenewal': _calcNextRenewal(),
      }),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
              Text(s.addSubscriptionTitle, style: AppTypography.headlineSm),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: SplitAmountField(
              onChanged: (v) => setState(() => _amount = v),
              color: AppColors.tertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _field(_nameController, s.subscriptionNameHint, Icons.subscriptions_outlined),
          const SizedBox(height: AppSpacing.lg),
          Text(
            s.accountLabel,
            style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<List<AccountModel>>(
            future: _accountsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }
              final accounts = snapshot.data!.where((a) => !a.isArchived).toList();
              if (accounts.isEmpty) {
                return Text(
                  s.noAccountsFound,
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                );
              }
              if (_selectedAccountId == null) {
                final def = accounts.firstWhere(
                  (a) => a.isDefault,
                  orElse: () => accounts.first,
                );
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => setState(() => _selectedAccountId = def.id),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: accounts.map((a) {
                    final isSelected = _selectedAccountId == a.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAccountId = a.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          a.name,
                          style: AppTypography.labelSm.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            s.billingCycleLabel,
            style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _cycles(context).map((c) {
              final isActive = _period == c.value;
              final isLast = c == _cycles(context).last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.xs),
                  child: GestureDetector(
                    onTap: () => setState(() => _period = c.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: isActive
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        c.label,
                        style: AppTypography.labelSm.copyWith(
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
                  const Icon(Icons.autorenew_rounded,
                      size: 20, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(s.autoDeductLabel, style: AppTypography.bodyMd),
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
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
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
