import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/subscription_model.dart';
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
  SubscriptionKind _kind = SubscriptionKind.SUBSCRIPTION;
  int _reminderDaysBefore = 3;
  DateTime? _dueDate;
  String? _selectedAccountId;
  late final Future<List<AccountModel>> _accountsFuture;

  bool get _isBill => _kind == SubscriptionKind.BILL;

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
    // Abonelik için yenileme tarihi akıllı varsayılanla ön-doldurulur (düzenlenebilir)
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
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
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
    // Abonelikte tutar zorunlu; faturada tahmini tutar opsiyonel
    if (!_isBill && (amount == null || amount <= 0)) {
      _showError(s.enterValidAmount);
      return;
    }
    if (_selectedAccountId == null) {
      _showError(s.selectAccount);
      return;
    }
    // Faturada son ödeme tarihi manuel seçilmeli
    if (_isBill && _dueDate == null) {
      _showError(s.selectDueDate);
      return;
    }

    final now = DateTime.now();
    context.read<SubscriptionsBloc>().add(
      SubscriptionCreated({
        'name': name,
        if (amount != null && amount > 0) 'amount': amount,
        'kind': _kind.name,
        'period': _isBill ? 'MONTHLY' : _period,
        'autoDeduct': !_isBill,
        if (_isBill) 'reminderDaysBefore': _reminderDaysBefore,
        'accountId': _selectedAccountId!,
        'startDate': _isoDate(now),
        'nextRenewal': _isoDate(_dueDate ?? _defaultRenewalDate()),
      }),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.of(context).subscriptionCreatedSuccess),
        backgroundColor: AppColors.secondary,
      ),
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
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _typeSelector(s),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: SplitAmountField(
                onChanged: (v) => setState(() => _amount = v),
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _field(
              _nameController,
              _isBill ? s.billNameHint : s.subscriptionNameHint,
              _isBill
                  ? Icons.receipt_long_outlined
                  : Icons.subscriptions_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              s.accountLabel,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
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
                final accounts = snapshot.data!
                    .where((a) => !a.isArchived)
                    .toList();
                if (accounts.isEmpty) {
                  return Text(
                    s.noAccountsFound,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
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
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  )
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
            if (!_isBill) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                s.billingCycleLabel,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: _cycles(context).map((c) {
                  final isActive = _period == c.value;
                  final isLast = c == _cycles(context).last;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: isLast ? 0 : AppSpacing.xs,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          // Tarih elle değiştirilmediyse döneme göre güncelle
                          final stillDefault =
                              _dueDate == _defaultRenewalDate();
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
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: isActive
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  )
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
            ],
            const SizedBox(height: AppSpacing.md),
            // Tarih + hatırlatma hem abonelik hem fatura için
            _dueDatePicker(s),
            const SizedBox(height: AppSpacing.lg),
            Text(
              s.reminderDaysBeforeLabel,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _reminderSelector(s),
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

  Widget _typeSelector(AppStrings s) {
    final options = [
      (kind: SubscriptionKind.SUBSCRIPTION, label: s.kindSubscription),
      (kind: SubscriptionKind.BILL, label: s.kindBill),
    ];
    return Row(
      children: options.map((o) {
        final isActive = _kind == o.kind;
        final isLast = o == options.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.xs),
            child: GestureDetector(
              onTap: () => setState(() {
                _kind = o.kind;
                // Faturada gerçek son ödeme günü seçilsin (boş); abonelikte akıllı varsayılan
                _dueDate = _isBill ? null : _defaultRenewalDate();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 44,
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
                  o.label,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dueDatePicker(AppStrings s) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? now,
          // Faturada geç ödeme için geçmişe izin ver; abonelikte yenileme tarihi gelecekte
          firstDate: _isBill ? DateTime(now.year - 1) : now,
          lastDate: DateTime(2040),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primary,
                surface: AppColors.surfaceContainerHigh,
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
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_outlined,
              size: 20,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _dueDate == null
                    ? (_isBill ? s.selectDueDate : s.selectRenewalDate)
                    : '${_isBill ? s.billDueDateLabel : s.nextRenewalLabel}: ${_isoDate(_dueDate!)}',
                style: AppTypography.bodyMd.copyWith(
                  color: _dueDate == null
                      ? AppColors.onSurfaceVariant
                      : AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderSelector(AppStrings s) {
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
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: isActive
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  s.reminderDaysOption(d),
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
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
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
