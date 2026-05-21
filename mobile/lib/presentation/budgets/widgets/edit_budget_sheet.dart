import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
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
        backgroundColor: AppColors.secondary,
      ),
    );
    Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
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
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(AppStrings.of(context).editBudgetTitle, style: AppTypography.titleSm),
            const SizedBox(height: AppSpacing.xl),

            // Amount
            Center(
              child: SplitAmountField(
                initialValue: widget.budget.amount,
                onChanged: (v) => _amount = v,
                autofocus: false,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Name
            TextField(
              controller: _nameController,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                labelText: AppStrings.of(context).budgetNameLabel,
                prefixIcon: const Icon(Icons.label_outline,
                    color: AppColors.onSurfaceVariant, size: 20),
                filled: true,
                fillColor: AppColors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                labelStyle: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Period
            Text(AppStrings.of(context).periodLabel, style: AppTypography.titleSm),
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
                          right: p != BudgetPeriod.CUSTOM
                              ? AppSpacing.sm
                              : 0),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _periodLabels(context)[p]!,
                        style: AppTypography.bodySm.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSurface,
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

            // End date (read-only computed chip)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_available_outlined,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    AppStrings.of(context).budgetEndsOn(
                        DateFormatter.formatLong(_computedEndDate, context)),
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Smart tracking
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(AppStrings.of(context).smartTracking,
                        style: AppTypography.bodyMd),
                  ),
                  Switch(
                    value: _smartTracking,
                    onChanged: (v) =>
                        setState(() => _smartTracking = v),
                    activeThumbColor: AppColors.primary,
                    activeTrackColor:
                        AppColors.primary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                ),
                child: Text(
                  AppStrings.of(context).save,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.surface,
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
