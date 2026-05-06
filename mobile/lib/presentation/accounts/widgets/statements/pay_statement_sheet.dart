import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/account_model.dart';
import '../../../../data/models/statement_model.dart';
import '../../bloc/statements_bloc.dart';

/// Account detail sayfasında bulunan `StatementsBloc`'a erişim gerektirir —
/// bu yüzden `showModalBottomSheet` çağrılırken parent context'in bloc'u
/// `BlocProvider.value` ile aktarılmalı.
class PayStatementSheet extends StatefulWidget {
  const PayStatementSheet({
    super.key,
    required this.statement,
    required this.payableAccounts,
  });

  final StatementModel statement;
  final List<AccountModel> payableAccounts;

  @override
  State<PayStatementSheet> createState() => _PayStatementSheetState();
}

class _PayStatementSheetState extends State<PayStatementSheet> {
  late final TextEditingController _amountCtrl;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.statement.remainingAmount.toStringAsFixed(2),
    );
    if (widget.payableAccounts.isNotEmpty) {
      final def = widget.payableAccounts.firstWhere(
        (a) => a.isDefault,
        orElse: () => widget.payableAccounts.first,
      );
      _selectedAccountId = def.id;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _setAmount(double v) {
    _amountCtrl.text = v.toStringAsFixed(2);
    setState(() {});
  }

  void _submit() {
    final raw = _amountCtrl.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) return;
    final accountId = _selectedAccountId;
    if (accountId == null) return;
    context.read<StatementsBloc>().add(StatementPaymentRequested(
          statementId: widget.statement.id,
          amount: amount,
          fromAccountId: accountId,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final stmt = widget.statement;
    final hasPayable = widget.payableAccounts.isNotEmpty;
    final fullPayable = stmt.remainingAmount;
    final minPayable = stmt.minimumPayment - stmt.paidAmount;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.lg,
          AppSpacing.pagePadding,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(s.payStatementTitle, style: AppTypography.titleSm),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${s.remainingLabel}: ${CurrencyFormatter.format(stmt.remainingAmount)}',
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!hasPayable)
              _Warning(message: s.noPayableAccountWarning)
            else ...[
              _label(s.paymentAmountLabel),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                style: const TextStyle(
                    color: AppColors.onSurface, fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: minPayable > 0.005
                          ? () => _setAmount(minPayable)
                          : null,
                      style: _quickBtnStyle(),
                      child: Text(s.payMinimumButton),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _setAmount(fullPayable),
                      style: _quickBtnStyle(),
                      child: Text(s.payFullButton),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _label(s.fromAccountLabel),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                dropdownColor: AppColors.surfaceContainerHigh,
                style:
                    const TextStyle(color: AppColors.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: widget.payableAccounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(
                              '${a.name} · ${CurrencyFormatter.format(a.balance)}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: Text(s.payButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ButtonStyle _quickBtnStyle() => OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.onSurfaceVariant),
        foregroundColor: AppColors.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: AppTypography.labelSm
            .copyWith(color: AppColors.onSurfaceVariant),
      );
}

class _Warning extends StatelessWidget {
  const _Warning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        message,
        style: AppTypography.bodySm.copyWith(color: AppColors.warning),
      ),
    );
  }
}
