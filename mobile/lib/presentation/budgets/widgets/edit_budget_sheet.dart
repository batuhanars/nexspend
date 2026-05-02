import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/budget_model.dart';
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
  late final TextEditingController _amountController;
  late BudgetPeriod _period;
  late bool _smartTracking;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.budget.name);
    _amountController = TextEditingController(
      text: widget.budget.amount % 1 == 0
          ? widget.budget.amount.toInt().toString()
          : widget.budget.amount.toString(),
    );
    _period = widget.budget.period;
    _smartTracking = widget.budget.smartTracking;
    _endDate = widget.budget.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final amountStr =
        _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      _showError('Geçerli bir tutar girin.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError('Bütçe adı girin.');
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
              if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
            },
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

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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
    if (picked != null) setState(() => _endDate = picked);
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  static const _periodLabels = {
    BudgetPeriod.MONTHLY: 'Aylık',
    BudgetPeriod.WEEKLY: 'Haftalık',
    BudgetPeriod.YEARLY: 'Yıllık',
    BudgetPeriod.CUSTOM: 'Özel',
  };

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
            Text('Bütçeyi Düzenle', style: AppTypography.titleSm),
            const SizedBox(height: AppSpacing.xl),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                labelText: 'Tutar (₺)',
                prefixIcon: const Icon(Icons.attach_money,
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
            const SizedBox(height: AppSpacing.md),

            // Name
            TextField(
              controller: _nameController,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                labelText: 'Bütçe Adı',
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
            Text('Dönem', style: AppTypography.titleSm),
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
                        _periodLabels[p]!,
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

            // End date (optional)
            GestureDetector(
              onTap: _pickEndDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bitiş Tarihi',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            _endDate != null
                                ? _fmtDate(_endDate!)
                                : 'Belirsiz',
                            style: AppTypography.bodySm,
                          ),
                        ],
                      ),
                    ),
                    if (_endDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _endDate = null),
                        child: const Icon(Icons.close,
                            size: 16,
                            color: AppColors.onSurfaceVariant),
                      ),
                  ],
                ),
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
                    child: Text('Akıllı Takip',
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
                  'Kaydet',
                  style: AppTypography.bodyMd
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
