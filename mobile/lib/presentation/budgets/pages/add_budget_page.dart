import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/budget_period.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/category_model.dart';
import '../bloc/add_budget_bloc.dart';
import '../bloc/add_budget_event.dart';
import '../bloc/add_budget_state.dart';
import '../widgets/amount_field.dart';
import '../widgets/app_field.dart';
import '../widgets/category_grid.dart';
import '../widgets/date_button.dart';
import '../widgets/period_selector.dart';

class AddBudgetPage extends StatefulWidget {
  const AddBudgetPage({super.key, this.prefill});

  /// Önceki arşivlenmiş bütçeden prefill için.
  final BudgetModel? prefill;

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  double? _amount;
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  CategoryModel? _selectedCategory;
  BudgetPeriod _period = BudgetPeriod.MONTHLY;
  bool _smartTracking = true;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _applyPrefill();
    context.read<AddBudgetBloc>().add(const AddBudgetInitialized());
  }

  void _applyPrefill() {
    final p = widget.prefill;
    if (p == null) return;
    _amount = p.amount;
    _nameController.text = p.name;
    _period = p.period;
    _smartTracking = p.smartTracking;
    // Yeni dönem: eski endDate + 1 gün
    _startDate = p.endDate.add(const Duration(days: 1));
    _endDate = null; // custom olmadığı sürece yeniden hesaplanır
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
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
      'categoryId': _selectedCategory!.id,
      'name': _nameController.text.trim(),
      'amount': amount,
      'period': _period.name,
      'startDate': _startDate.toIso8601String(),
      'smartTracking': _smartTracking,
      if (_period == BudgetPeriod.CUSTOM && _endDate != null)
        'endDate': _endDate!.toIso8601String(),
      if (_noteController.text.trim().isNotEmpty)
        'note': _noteController.text.trim(),
    };

    context.read<AddBudgetBloc>().add(AddBudgetSubmitted(data));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
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
            primary: AppColors.primary,
            onPrimary: AppColors.surface,
            surface: AppColors.surfaceContainerHigh,
            onSurface: AppColors.onSurface,
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

  Widget _buildEndDateChip(BuildContext context) {
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
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              s.budgetEndsOn(formatted),
              style: AppTypography.bodySm.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isPrefill = widget.prefill != null;

    return BlocListener<AddBudgetBloc, AddBudgetState>(
      listener: (context, state) {
        if (state is AddBudgetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.budgetCreatedSuccess),
              backgroundColor: AppColors.secondary,
            ),
          );
          Navigator.of(context).pop(state.budget);
        } else if (state is AddBudgetFailure) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isPrefill ? s.openNewPeriodBtn : s.newBudgetTitle,
            style: AppTypography.titleSm,
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<AddBudgetBloc, AddBudgetState>(
          builder: (context, state) {
            final isLoading = state is AddBudgetCategoriesLoading;
            final isSubmitting = state is AddBudgetSubmitting;
            final categories = switch (state) {
              AddBudgetReady(:final categories) => categories,
              AddBudgetSubmitting(:final categories) => categories,
              AddBudgetFailure(:final categories) => categories,
              _ => <CategoryModel>[],
            };

            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            // Prefill'de kategori otomatik seçilir (kategoriler yüklendikten sonra)
            if (isPrefill &&
                _selectedCategory == null &&
                categories.isNotEmpty) {
              final prefillCategoryId = widget.prefill?.category?.id;
              if (prefillCategoryId != null) {
                final match = categories
                    .where((c) => c.id == prefillCategoryId)
                    .toList();
                if (match.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _selectedCategory = match.first);
                    }
                  });
                }
              }
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
                    hint: s.budgetNameHint,
                    icon: Icons.label_outline,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(s.categoryLabel, style: AppTypography.titleSm),
                  const SizedBox(height: AppSpacing.md),
                  if (categories.isEmpty)
                    Text(
                      s.noCategoriesFound,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
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
                        Expanded(child: _buildEndDateChip(context)),
                      ],
                    ],
                  ),
                  if (_period != BudgetPeriod.CUSTOM) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildEndDateChip(context),
                  ],
                  const SizedBox(height: AppSpacing.xl),

                  Container(
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.smartTracking,
                                style: AppTypography.bodyMd,
                              ),
                              Text(
                                s.smartTrackingSubtitle,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _smartTracking,
                          onChanged: (v) => setState(() => _smartTracking = v),
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppField(
                    controller: _noteController,
                    label: s.noteOptionalLabel,
                    hint: s.addNoteHint,
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () => _submit(categories),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXl,
                          ),
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
                                color: AppColors.surface,
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
