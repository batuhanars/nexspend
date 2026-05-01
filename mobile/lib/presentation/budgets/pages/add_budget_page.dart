import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/category_model.dart';
import '../bloc/add_budget_bloc.dart';
import '../bloc/add_budget_event.dart';
import '../bloc/add_budget_state.dart';

class AddBudgetPage extends StatefulWidget {
  const AddBudgetPage({super.key});

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  CategoryModel? _selectedCategory;
  BudgetPeriod _period = BudgetPeriod.MONTHLY;
  bool _smartTracking = true;
  DateTime _startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    context.read<AddBudgetBloc>().add(const AddBudgetInitialized());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit(List<CategoryModel> categories) {
    final amountStr = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);

    if (amount == null || amount <= 0) {
      _showError('Geçerli bir tutar girin.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError('Bütçe adı girin.');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Bir kategori seçin.');
      return;
    }

    final data = <String, dynamic>{
      'categoryId': _selectedCategory!.id,
      'name': _nameController.text.trim(),
      'amount': amount,
      'period': _period.name,
      'startDate': _startDate.toIso8601String(),
      'smartTracking': _smartTracking,
      if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
      if (_noteController.text.trim().isNotEmpty)
        'note': _noteController.text.trim(),
    };

    context.read<AddBudgetBloc>().add(AddBudgetSubmitted(data));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF5350),
      ),
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddBudgetBloc, AddBudgetState>(
      listener: (context, state) {
        if (state is AddBudgetSuccess) {
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
          title: Text('Yeni Bütçe', style: AppTypography.titleSm),
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount input
                  _AmountField(controller: _amountController),
                  const SizedBox(height: AppSpacing.xl),

                  // Name input
                  _AppField(
                    controller: _nameController,
                    label: 'Bütçe Adı',
                    hint: 'Örn. Market Bütçesi',
                    icon: Icons.label_outline,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Category grid
                  Text('Kategori', style: AppTypography.titleSm),
                  const SizedBox(height: AppSpacing.md),
                  if (categories.isEmpty)
                    Text(
                      'Kategori bulunamadı.',
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                    )
                  else
                    _CategoryGrid(
                      categories: categories,
                      selected: _selectedCategory,
                      onSelect: (c) =>
                          setState(() => _selectedCategory = c),
                    ),
                  const SizedBox(height: AppSpacing.xl),

                  // Period
                  Text('Dönem', style: AppTypography.titleSm),
                  const SizedBox(height: AppSpacing.md),
                  _PeriodSelector(
                    selected: _period,
                    onSelect: (p) => setState(() {
                      _period = p;
                      if (p != BudgetPeriod.CUSTOM) _endDate = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Date row
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(
                          label: 'Başlangıç',
                          value: _formatDate(_startDate),
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      if (_period == BudgetPeriod.CUSTOM) ...[
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _DateButton(
                            label: 'Bitiş',
                            value: _endDate != null
                                ? _formatDate(_endDate!)
                                : 'Seç',
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Smart tracking toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Akıllı Takip',
                                  style: AppTypography.bodyMd),
                              Text(
                                'İşlemler otomatik hesaplanır',
                                style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _smartTracking,
                          onChanged: (v) => setState(() => _smartTracking = v),
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Note
                  _AppField(
                    controller: _noteController,
                    label: 'Not (isteğe bağlı)',
                    hint: 'Açıklama ekle...',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Submit
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
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl),
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
                              'Bütçe Oluştur',
                              style: AppTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Bütçe Tutarı',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₺',
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IntrinsicWidth(
              child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                ],
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '0',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const Divider(color: AppColors.surfaceContainerHighest),
      ],
    );
  }
}

class _AppField extends StatelessWidget {
  const _AppField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTypography.bodyMd,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        labelStyle:
            AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        hintStyle:
            AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });
  final List<CategoryModel> categories;
  final CategoryModel? selected;
  final ValueChanged<CategoryModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: categories.map((cat) {
        final isSelected = selected?.id == cat.id;
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.cardColor.withValues(alpha: 0.2)
                  : AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected
                    ? cat.cardColor
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconMapper.fromString(cat.icon),
                  size: 16,
                  color: isSelected ? cat.cardColor : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  cat.name,
                  style: AppTypography.bodySm.copyWith(
                    color: isSelected ? cat.cardColor : AppColors.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelect});
  final BudgetPeriod selected;
  final ValueChanged<BudgetPeriod> onSelect;

  static const _labels = {
    BudgetPeriod.MONTHLY: 'Aylık',
    BudgetPeriod.WEEKLY: 'Haftalık',
    BudgetPeriod.YEARLY: 'Yıllık',
    BudgetPeriod.CUSTOM: 'Özel',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: BudgetPeriod.values.map((p) {
        final isSelected = p == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: p != BudgetPeriod.CUSTOM ? AppSpacing.sm : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                _labels[p]!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
