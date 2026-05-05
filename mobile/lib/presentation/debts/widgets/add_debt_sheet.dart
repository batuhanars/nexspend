import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
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

  void _submit() {
    final name = _nameController.text.trim();
    final amount = _amount;

    if (name.isEmpty) return;
    if (amount == null || amount <= 0) return;

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
        'firstInstallmentDate':
            DateTime.now().toIso8601String().split('T').first,
    };

    context.read<DebtsBloc>().add(DebtCreated(data));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_type == DebtType.LENT
            ? AppStrings.of(context).debtLentCreatedSuccess
            : AppStrings.of(context).debtCreatedSuccess),
        backgroundColor: AppColors.secondary,
      ),
    );
    Navigator.of(context).pop();
  }

  Color get _typeColor =>
      _type == DebtType.BORROWED ? AppColors.tertiary : AppColors.secondary;

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
                Text(s.addDebtTitle, style: AppTypography.headlineSm),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.onSurfaceVariant,
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
                color: _typeColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _inputField(_nameController, s.personNameHint, Icons.person_outline),
            const SizedBox(height: AppSpacing.md),
            _inputField(_descController, s.descriptionOptionalHint, Icons.notes_outlined),
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
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 20, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _dueDate == null
                          ? s.dueDateHint
                          : '${_dueDate!.day.toString().padLeft(2, '0')}.${_dueDate!.month.toString().padLeft(2, '0')}.${_dueDate!.year}',
                      style: TextStyle(
                        color: _dueDate == null
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface,
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
                color: AppColors.surfaceContainerHighest,
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
                        const Icon(Icons.receipt_long_outlined,
                            size: 20, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(s.installment, style: AppTypography.bodyMd),
                        ),
                        Switch(
                          value: _hasInstallments,
                          onChanged: (v) =>
                              setState(() => _hasInstallments = v),
                          activeThumbColor: AppColors.primary,
                          activeTrackColor:
                              AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                  if (_hasInstallments)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                      child: Row(
                        children: [
                          Text(s.installmentCountLabel,
                              style: AppTypography.bodyMd),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              if (_installmentCount > 2) {
                                setState(() => _installmentCount--);
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.onSurfaceVariant,
                          ),
                          Text('$_installmentCount',
                              style: AppTypography.titleSm),
                          IconButton(
                            onPressed: () =>
                                setState(() => _installmentCount++),
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
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
  ) {
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
