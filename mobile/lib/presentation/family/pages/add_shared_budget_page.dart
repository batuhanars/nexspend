import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/budget_period.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/budget_model.dart' show BudgetPeriod;
import '../../../data/models/category_model.dart';
import '../../budgets/widgets/amount_field.dart';
import '../../budgets/widgets/app_field.dart';
import '../../budgets/widgets/category_grid.dart';
import '../../budgets/widgets/date_button.dart';
import '../../budgets/widgets/period_selector.dart';
import '../bloc/add_shared_budget_bloc.dart';
import '../bloc/add_shared_budget_event.dart';
import '../bloc/add_shared_budget_state.dart';

class AddSharedBudgetPage extends StatefulWidget {
  const AddSharedBudgetPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<AddSharedBudgetPage> createState() => _AddSharedBudgetPageState();
}

class _AddSharedBudgetPageState extends State<AddSharedBudgetPage> {
  double? _amount;
  final _nameController = TextEditingController();
  CategoryModel? _selectedCategory;
  BudgetPeriod _period = BudgetPeriod.MONTHLY;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(List<CategoryModel> categories) {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      _showError(AppStrings.of(context).enterValidAmount);
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError(AppStrings.of(context).enterBudgetName);
      return;
    }
    if (_selectedCategory == null) {
      _showError(AppStrings.of(context).selectCategoryPrompt);
      return;
    }
    if (_period == BudgetPeriod.CUSTOM && _endDate == null) {
      _showError(AppStrings.of(context).selectEndDate);
      return;
    }

    final data = <String, dynamic>{
      'groupId': widget.groupId,
      'categoryId': _selectedCategory!.id,
      'name': _nameController.text.trim(),
      'amount': amount,
      'period': _period.name,
      'startDate': _startDate.toIso8601String(),
      if (_period == BudgetPeriod.CUSTOM && _endDate != null)
        'endDate': _endDate!.toIso8601String(),
    };

    context.read<AddSharedBudgetBloc>().add(AddSharedBudgetSubmitted(data));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: context.colors.error),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final first = isStart ? DateTime(2020) : _startDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: ctx.colors.primary,
            onPrimary: ctx.colors.surface,
            surface: ctx.colors.surfaceContainerHigh,
            onSurface: ctx.colors.onSurface,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  Widget _buildEndDateWidget(BuildContext context) {
    final colors = context.colors;
    if (_period == BudgetPeriod.CUSTOM) {
      return DateButton(
        label: AppStrings.of(context).endDateLabel,
        value: _endDate != null
            ? _formatDate(_endDate!)
            : AppStrings.of(context).selectPlaceholder,
        onTap: () => _pickDate(isStart: false),
      );
    }

    final computed = BudgetPeriodUtils.computeEndDate(_startDate, _period);
    final formatted = DateFormatter.formatLong(computed, context);
    final s = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 14,
            color: colors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              s.budgetEndsOn(formatted),
              style: AppTypography.bodySm.copyWith(color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);

    return BlocListener<AddSharedBudgetBloc, AddSharedBudgetState>(
      listener: (context, state) {
        if (state is AddSharedBudgetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.budgetCreatedSuccess),
              backgroundColor: colors.secondary,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is AddSharedBudgetFailure) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.close, color: colors.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(s.addSharedBudgetTitle, style: AppTypography.titleSm),
          centerTitle: true,
        ),
        body: BlocBuilder<AddSharedBudgetBloc, AddSharedBudgetState>(
          builder: (context, state) {
            final isLoading = state is AddSharedBudgetCategoriesLoading;
            final isSubmitting = state is AddSharedBudgetSubmitting;
            final categories = switch (state) {
              AddSharedBudgetReady(:final categories) => categories,
              AddSharedBudgetSubmitting(:final categories) => categories,
              AddSharedBudgetFailure(:final categories) => categories,
              _ => <CategoryModel>[],
            };

            if (isLoading) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AmountField(
                    initialValue: _amount,
                    onChanged: (v) => setState(() => _amount = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppField(
                    controller: _nameController,
                    label: s.budgetNameLabel,
                    hint: s.sharedBudgetNameHint,
                    icon: Icons.label_outline,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(s.categoryLabel, style: AppTypography.titleSm),
                  const SizedBox(height: AppSpacing.md),
                  if (categories.isEmpty)
                    Text(
                      s.noCategoriesFound,
                      style: AppTypography.bodyMd.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    )
                  else
                    CategoryGrid(
                      categories: categories,
                      selected: _selectedCategory,
                      onSelect: (c) => setState(() => _selectedCategory = c),
                    ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(s.periodLabel, style: AppTypography.titleSm),
                  const SizedBox(height: AppSpacing.md),
                  PeriodSelector(
                    selected: _period,
                    onSelect: (p) => setState(() {
                      _period = p;
                      if (p != BudgetPeriod.CUSTOM) _endDate = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    children: [
                      Expanded(
                        child: DateButton(
                          label: s.startDateLabel,
                          value: _formatDate(_startDate),
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      if (_period == BudgetPeriod.CUSTOM) ...[
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildEndDateWidget(context)),
                      ],
                    ],
                  ),
                  if (_period != BudgetPeriod.CUSTOM) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildEndDateWidget(context),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : () => _submit(categories),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.surface,
                        disabledBackgroundColor: colors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              s.save,
                              style: AppTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.surface,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
