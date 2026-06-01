import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/budget_period.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/budget_model.dart';
import '../../shared/widgets/split_amount_field.dart';
import '../bloc/budgets_bloc.dart';
import '../bloc/budgets_event.dart';

class EditBudgetSheet extends StatefulWidget {
  const EditBudgetSheet({super.key, required this.budget});
  final BudgetModel budget;

  @override
  State<EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends State<EditBudgetSheet> {
  late final TextEditingController _nameController;
  late double? _amount;
  late BudgetPeriod _period;
  late bool _smartTracking;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.budget.name);
    _amount = widget.budget.amount;
    _period = widget.budget.period;
    _smartTracking = widget.budget.smartTracking;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      _showError(AppStrings.of(context).enterValidAmount);
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError(AppStrings.of(context).enterBudgetName);
      return;
    }

    context.read<BudgetsBloc>().add(
          BudgetUpdateRequested(
            id: widget.budget.id,
            data: {
              'name': _nameController.text.trim(),
              'amount': amount,
              'period': _period.name,
              'smartTracking': _smartTracking,
              'endDate': _computedEndDate.toIso8601String(),
            },
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.of(context).budgetUpdatedSuccess),
        backgroundColor: context.colors.income,
      ),
    );
    Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.colors.error,
      ),
    );
  }

  DateTime get _computedEndDate {
    if (_period == BudgetPeriod.CUSTOM) return widget.budget.endDate;
    return BudgetPeriodUtils.computeEndDate(widget.budget.startDate, _period);
  }

  Map<BudgetPeriod, String> _periodLabels(BuildContext context) {
    final s = AppStrings.of(context);
    return {
      BudgetPeriod.MONTHLY: s.billingCycleMonthly,
      BudgetPeriod.WEEKLY: s.billingCycleWeekly,
      BudgetPeriod.YEARLY: s.billingCycleYearly,
      BudgetPeriod.CUSTOM: s.periodCustom,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xl + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(AppStrings.of(context).editBudgetTitle,
                style: AppTypography.titleSm),
            const SizedBox(height: AppSpacing.xl),

            Center(
              child: SplitAmountField(
                initialValue: widget.budget.amount,
                onChanged: (v) => _amount = v,
                autofocus: false,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            TextField(
              controller: _nameController,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                labelText: AppStrings.of(context).budgetNameLabel,
                prefixIcon: Icon(Icons.label_outline,
                    color: colors.onSurfaceVariant, size: 20),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                labelStyle: AppTypography.bodySm
                    .copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(AppStrings.of(context).periodLabel,
                style: AppTypography.titleSm),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: BudgetPeriod.values.map((p) {
                final isSelected = p == _period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _period = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(
                          right:
                              p != BudgetPeriod.CUSTOM ? AppSpacing.sm : 0),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary.withValues(alpha: 0.15)
                            : colors.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: isSelected
                              ? colors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _periodLabels(context)[p]!,
                        style: AppTypography.bodySm.copyWith(
                          color: isSelected
                              ? colors.primary
                              : colors.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available_outlined,
                      size: 14, color: colors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    AppStrings.of(context).budgetEndsOn(
                        DateFormatter.formatLong(_computedEndDate, context)),
                    style: AppTypography.bodySm
                        .copyWith(color: colors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(AppStrings.of(context).smartTracking,
                        style: AppTypography.bodyMd),
                  ),
                  Switch(
                    value: _smartTracking,
                    onChanged: (v) => setState(() => _smartTracking = v),
                    activeThumbColor: colors.primary,
                    activeTrackColor:
                        colors.primary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                ),
                child: Text(
                  AppStrings.of(context).save,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.surface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
