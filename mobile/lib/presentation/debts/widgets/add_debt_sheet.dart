import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/data/models/debt_model.dart';
import 'package:wallet_app/presentation/debts/bloc/debts_bloc.dart';
import 'package:wallet_app/presentation/debts/widgets/type_toggle.dart';
import 'package:wallet_app/presentation/shared/widgets/split_amount_field.dart';

class AddDebtSheet extends StatefulWidget {
  const AddDebtSheet({super.key});

  @override
  State<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<AddDebtSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  double? _amount;
  DebtType _type = DebtType.BORROWED;
  DateTime? _dueDate;
  bool _hasInstallments = false;
  int _installmentCount = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
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
      _showError(s.enterPersonName);
      return;
    }
    if (amount == null || amount <= 0) {
      _showError(s.enterValidAmount);
      return;
    }

    final data = <String, dynamic>{
      'type': _type.name,
      'personName': name,
      'totalAmount': amount,
      if (_descController.text.trim().isNotEmpty)
        'note': _descController.text.trim(),
      if (_dueDate != null)
        'dueDate': _dueDate!.toIso8601String().split('T').first,
      'hasInstallments': _hasInstallments,
      if (_hasInstallments) 'installmentCount': _installmentCount,
      if (_hasInstallments)
        'firstInstallmentDate': DateTime.now()
            .toIso8601String()
            .split('T')
            .first,
    };

    context.read<DebtsBloc>().add(DebtCreated(data));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _type == DebtType.LENT
              ? AppStrings.of(context).debtLentCreatedSuccess
              : AppStrings.of(context).debtCreatedSuccess,
        ),
        backgroundColor: context.colors.secondary,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    final typeColor = _type == DebtType.BORROWED ? colors.expense : colors.income;

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
                Text(s.addDebtTitle, style: AppTypography.headlineSm),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TypeToggle(
              selected: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: SplitAmountField(
                onChanged: (v) => setState(() => _amount = v),
                color: typeColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _inputField(
              _nameController,
              s.personNameHint,
              Icons.person_outline,
              colors,
            ),
            const SizedBox(height: AppSpacing.md),
            _inputField(
              _descController,
              s.descriptionOptionalHint,
              Icons.notes_outlined,
              colors,
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
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
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _dueDate == null
                          ? s.dueDateHint
                          : '${_dueDate!.day.toString().padLeft(2, '0')}.${_dueDate!.month.toString().padLeft(2, '0')}.${_dueDate!.year}',
                      style: TextStyle(
                        color: _dueDate == null
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            s.installment,
                            style: AppTypography.bodyMd,
                          ),
                        ),
                        Switch(
                          value: _hasInstallments,
                          onChanged: (v) =>
                              setState(() => _hasInstallments = v),
                          activeThumbColor: colors.primary,
                          activeTrackColor: colors.primary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasInstallments)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Text(
                            s.installmentCountLabel,
                            style: AppTypography.bodyMd,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              if (_installmentCount > 2) {
                                setState(() => _installmentCount--);
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                            color: colors.onSurfaceVariant,
                          ),
                          Text(
                            '$_installmentCount',
                            style: AppTypography.titleSm,
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _installmentCount++),
                            icon: const Icon(Icons.add_circle_outline),
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                ],
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
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    AppPalette colors,
  ) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: colors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 14,
        ),
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
