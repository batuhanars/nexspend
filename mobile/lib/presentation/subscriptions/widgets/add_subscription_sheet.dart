import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_palette.dart';
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
  int _reminderDaysBefore = 3;
  DateTime? _dueDate;
  String? _selectedAccountId;
  late final Future<List<AccountModel>> _accountsFuture;

  List<({String label, String value})> _cycles(BuildContext context) {
    final s = AppStrings.of(context);
    return [
      (label: s.billingCycleMonthly, value: 'MONTHLY'),
      (label: s.billingCycleYearly, value: 'YEARLY'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _accountsFuture = getIt<AccountRepository>().getAccounts();
    _dueDate = _defaultRenewalDate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _defaultRenewalDate() {
    final now = DateTime.now();
    return _period == 'YEARLY'
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: context.colors.error),
    );
  }

  void _submit() {
    final s = AppStrings.of(context);
    final name = _nameController.text.trim();
    final amount = _amount;
    if (name.isEmpty) {
      _showError(s.enterSubscriptionName);
      return;
    }
    if (amount == null || amount <= 0) {
      _showError(s.enterValidAmount);
      return;
    }
    if (_selectedAccountId == null) {
      _showError(s.selectAccount);
      return;
    }

    final now = DateTime.now();
    context.read<SubscriptionsBloc>().add(
      SubscriptionCreated({
        'name': name,
        'amount': amount,
        'period': _period,
        'reminderDaysBefore': _reminderDaysBefore,
        'accountId': _selectedAccountId!,
        'startDate': _isoDate(now),
        'nextRenewal': _isoDate(_dueDate ?? _defaultRenewalDate()),
      }),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.of(context).subscriptionCreatedSuccess),
        backgroundColor: context.colors.secondary,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
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
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: SplitAmountField(
                onChanged: (v) => setState(() => _amount = v),
                color: colors.expense,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _field(_nameController, s.subscriptionNameHint, Icons.subscriptions_outlined, colors),
            const SizedBox(height: AppSpacing.lg),
            Text(
              s.accountLabel,
              style: AppTypography.labelSm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<AccountModel>>(
              future: _accountsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox(
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  );
                }
                final accounts = snapshot.data!
                    .where((a) => !a.isArchived)
                    .toList();
                if (accounts.isEmpty) {
                  return Text(
                    s.noAccountsFound,
                    style: AppTypography.bodySm.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
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
                                ? colors.primary.withValues(alpha: 0.15)
                                : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: isSelected
                                ? Border.all(color: colors.primary, width: 1.5)
                                : null,
                          ),
                          child: Text(
                            a.name,
                            style: AppTypography.labelSm.copyWith(
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
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
              style: AppTypography.labelSm.copyWith(
                color: colors.onSurfaceVariant,
              ),
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
                      onTap: () => setState(() {
                        final stillDefault = _dueDate == _defaultRenewalDate();
                        _period = c.value;
                        if (_dueDate == null || stillDefault) {
                          _dueDate = _defaultRenewalDate();
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colors.primary.withValues(alpha: 0.15)
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: isActive
                              ? Border.all(color: colors.primary, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          c.label,
                          style: AppTypography.labelSm.copyWith(
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? colors.primary : colors.onSurfaceVariant,
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
            _dueDatePicker(s, colors),
            const SizedBox(height: AppSpacing.lg),
            Text(
              s.reminderDaysBeforeLabel,
              style: AppTypography.labelSm.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            _reminderSelector(s, colors),
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
      ),
    );
  }

  Widget _dueDatePicker(AppStrings s, AppPalette colors) {
    final now = DateTime.now();
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? now,
          firstDate: now,
          lastDate: DateTime(2040),
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
        if (picked != null) setState(() => _dueDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _dueDate == null
                    ? s.selectDueDate
                    : '${s.nextRenewalLabel}: ${_isoDate(_dueDate!)}',
                style: AppTypography.bodyMd.copyWith(
                  color: _dueDate == null ? colors.onSurfaceVariant : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderSelector(AppStrings s, AppPalette colors) {
    const days = [1, 3, 7];
    return Row(
      children: days.map((d) {
        final isActive = _reminderDaysBefore == d;
        final isLast = d == days.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.xs),
            child: GestureDetector(
              onTap: () => setState(() => _reminderDaysBefore = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: isActive
                      ? Border.all(color: colors.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  s.reminderDaysOption(d),
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? colors.primary : colors.onSurfaceVariant,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, AppPalette colors) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: colors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: colors.onSurfaceVariant),
        filled: true,
        fillColor: colors.surfaceContainerHighest,
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
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}
