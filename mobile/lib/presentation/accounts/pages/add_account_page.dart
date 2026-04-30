import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/account_model.dart';
import '../bloc/account_bloc.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _creditLimitController = TextEditingController();

  AccountType _type = AccountType.BANK;
  String _currency = 'TRY';
  int _statementDay = 1;
  int _paymentDueDay = 10;
  bool _isDefault = false;

  final _nameFocus = FocusNode();
  final _balanceFocus = FocusNode();
  final _creditLimitFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _nameFocus.dispose();
    _balanceFocus.dispose();
    _creditLimitFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final balance =
        double.tryParse(_balanceController.text.replaceAll(',', '.')) ?? 0.0;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': _type.name,
      'balance': balance,
      'currency': _currency,
      'isDefault': _isDefault,
      if (_type == AccountType.CREDIT_CARD) ...{
        'creditLimit':
            double.tryParse(_creditLimitController.text.replaceAll(',', '.')) ??
                0.0,
        'statementDay': _statementDay,
        'paymentDueDay': _paymentDueDay,
      },
    };

    context.read<AccountBloc>().add(AccountCreateRequested(data));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountSuccess) {
          Navigator.of(context).pop(state.account);
        } else if (state is AccountError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hesap Ekle'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            children: [
              const SizedBox(height: AppSpacing.xl),
              _TypeSelector(
                selected: _type,
                onChanged: (t) => setState(() {
                  _type = t;
                  _creditLimitController.clear();
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              _label('Hesap Adı'),
              const SizedBox(height: AppSpacing.sm),
              _AppField(
                controller: _nameController,
                focusNode: _nameFocus,
                hintText: _type.label,
                prefixIcon: _type.defaultIcon,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _balanceFocus.requestFocus(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Hesap adı gerekli' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _label('Başlangıç Bakiyesi'),
              const SizedBox(height: AppSpacing.sm),
              _AppField(
                controller: _balanceController,
                focusNode: _balanceFocus,
                hintText: '0,00',
                prefixIcon: Icons.account_balance_wallet_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: _type == AccountType.CREDIT_CARD
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (_type == AccountType.CREDIT_CARD) {
                    _creditLimitFocus.requestFocus();
                  }
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Geçersiz tutar';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _CurrencySelector(
                selected: _currency,
                onChanged: (c) => setState(() => _currency = c),
              ),
              if (_type == AccountType.CREDIT_CARD) ...[
                const SizedBox(height: AppSpacing.xl),
                _label('Kredi Kartı Detayları'),
                const SizedBox(height: AppSpacing.sm),
                _AppField(
                  controller: _creditLimitController,
                  focusNode: _creditLimitFocus,
                  hintText: 'Kredi limiti',
                  prefixIcon: Icons.credit_card_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  validator: (v) {
                    if (_type != AccountType.CREDIT_CARD) return null;
                    if (v == null || v.trim().isEmpty) return 'Kredi limiti gerekli';
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Geçerli bir limit girin';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _DayDropdown(
                        label: 'Ekstre Günü',
                        value: _statementDay,
                        onChanged: (d) => setState(() => _statementDay = d),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _DayDropdown(
                        label: 'Son Ödeme Günü',
                        value: _paymentDueDay,
                        onChanged: (d) => setState(() => _paymentDueDay = d),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              _DefaultToggle(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.lg,
            ),
            child: BlocBuilder<AccountBloc, AccountState>(
              builder: (context, state) {
                final isLoading = state is AccountSubmitting;
                return FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Hesabı Kaydet'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant));
}

// ── Account type selector ──────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});
  final AccountType selected;
  final ValueChanged<AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.6,
      children: AccountType.values.map((type) {
        final isSelected = type == selected;
        final accent = type.defaultColor;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.14)
                  : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: isSelected
                  ? Border.all(color: accent, width: 1.5)
                  : Border.all(color: Colors.transparent, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type.defaultIcon,
                  size: 20,
                  color: isSelected ? accent : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  type.label,
                  style: AppTypography.bodyMd.copyWith(
                    color: isSelected ? accent : AppColors.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

// ── Text form field ────────────────────────────────────────────────────────

class _AppField extends StatelessWidget {
  const _AppField({
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      validator: validator,
      style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.onSurfaceVariant)
            : null,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: AppTypography.bodySm.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
    );
  }
}

// ── Currency selector ──────────────────────────────────────────────────────

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  static const _currencies = ['TRY', 'USD', 'EUR'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _currencies.map((c) {
        final isSelected = c == selected;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Text(
                c,
                style: AppTypography.labelSm.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Day dropdown (1–31) ────────────────────────────────────────────────────

class _DayDropdown extends StatelessWidget {
  const _DayDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<int>(
          initialValue: value,
          dropdownColor: AppColors.surfaceContainerHigh,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          icon: const Icon(Icons.expand_more_rounded, color: AppColors.onSurfaceVariant, size: 20),
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          items: List.generate(
            28,
            (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

// ── Default toggle ─────────────────────────────────────────────────────────

class _DefaultToggle extends StatelessWidget {
  const _DefaultToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.star_outline_rounded,
              size: 22,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Varsayılan hesap',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Yeni işlemlerde otomatik seçilir',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
