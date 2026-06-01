import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/account_model.dart';
import '../../../../data/models/statement_model.dart';
import '../../bloc/statements_bloc.dart';

enum _PayChoice { minimum, full }

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
  _PayChoice _choice = _PayChoice.full;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    if (widget.payableAccounts.isNotEmpty) {
      final def = widget.payableAccounts.firstWhere(
        (a) => a.isDefault,
        orElse: () => widget.payableAccounts.first,
      );
      _selectedAccountId = def.id;
    }
    // Asgari zaten ödenmişse default tamamına çek; aksi halde asgari mantıklı.
    final remainingMin =
        widget.statement.minimumPayment - widget.statement.paidAmount;
    if (remainingMin > 0.005) _choice = _PayChoice.minimum;
  }

  double get _remainingMinimum =>
      (widget.statement.minimumPayment - widget.statement.paidAmount).clamp(
        0,
        widget.statement.remainingAmount,
      );

  double get _selectedAmount => _choice == _PayChoice.minimum
      ? _remainingMinimum
      : widget.statement.remainingAmount;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: context.colors.error),
    );
  }

  void _submit() {
    final s = AppStrings.of(context);
    final amount = _selectedAmount;
    if (amount <= 0) {
      _showError(s.enterValidAmount);
      return;
    }
    final accountId = _selectedAccountId;
    if (accountId == null) {
      _showError(s.selectAccount);
      return;
    }
    context.read<StatementsBloc>().add(
      StatementPaymentRequested(
        statementId: widget.statement.id,
        amount: amount,
        fromAccountId: accountId,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    final stmt = widget.statement;
    final hasPayable = widget.payableAccounts.isNotEmpty;
    final minimumAvailable = _remainingMinimum > 0.005;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(
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
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(s.payStatementTitle, style: AppTypography.titleSm),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${s.remainingLabel}: ${CurrencyFormatter.format(stmt.remainingAmount)}',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!hasPayable)
              _Warning(message: s.noPayableAccountWarning)
            else ...[
              _PayChoiceTile(
                label: s.payMinimumButton,
                amount: _remainingMinimum,
                selected: _choice == _PayChoice.minimum,
                enabled: minimumAvailable,
                onTap: minimumAvailable
                    ? () => setState(() => _choice = _PayChoice.minimum)
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _PayChoiceTile(
                label: s.payFullButton,
                amount: stmt.remainingAmount,
                selected: _choice == _PayChoice.full,
                enabled: true,
                onTap: () => setState(() => _choice = _PayChoice.full),
              ),
              const SizedBox(height: AppSpacing.lg),
              _label(s.fromAccountLabel, colors),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                dropdownColor: colors.surfaceContainerHigh,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: widget.payableAccounts
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          '${a.name} · ${CurrencyFormatter.format(a.balance)}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _selectedAmount > 0 ? _submit : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: Text(
                    '${s.payButton} · ${CurrencyFormatter.format(_selectedAmount)}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text, AppPalette colors) => Text(
    text,
    style: AppTypography.labelSm.copyWith(color: colors.onSurfaceVariant),
  );
}

class _PayChoiceTile extends StatelessWidget {
  const _PayChoiceTile({
    required this.label,
    required this.amount,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final double amount;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.onSurfaceVariant;
    final bg = selected
        ? colors.primary.withValues(alpha: 0.12)
        : colors.surfaceContainerHighest;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMd.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(amount),
                  style: AppTypography.bodyMd.copyWith(
                    color: selected ? colors.primary : colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        message,
        style: AppTypography.bodySm.copyWith(color: colors.warning),
      ),
    );
  }
}
