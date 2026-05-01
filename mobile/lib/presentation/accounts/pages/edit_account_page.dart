import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/account_model.dart';
import '../bloc/account_bloc.dart';
import '../widgets/account_form_widgets.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key, required this.account});

  final AccountModel account;

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.account.name);
  late final _creditLimitController = TextEditingController(
    text: widget.account.creditLimit != null
        ? widget.account.creditLimit!.toStringAsFixed(2)
        : '',
  );

  late AccountType _type = widget.account.type;
  late String _currency = widget.account.currency;
  late int _statementDay = widget.account.statementDay ?? 1;
  late int _paymentDueDay = widget.account.paymentDueDay ?? 10;
  late bool _isDefault = widget.account.isDefault;

  final _nameFocus = FocusNode();
  final _creditLimitFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _creditLimitController.dispose();
    _nameFocus.dispose();
    _creditLimitFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': _type.name,
      'currency': _currency,
      'isDefault': _isDefault,
      if (_type == AccountType.CREDIT_CARD) ...{
        'creditLimit': double.tryParse(
                _creditLimitController.text.replaceAll(',', '.')) ??
            0.0,
        'statementDay': _statementDay,
        'paymentDueDay': _paymentDueDay,
      },
    };

    context.read<AccountBloc>().add(
          AccountUpdateRequested(id: widget.account.id, data: data),
        );
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
          title: const Text('Hesabı Düzenle'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            children: [
              const SizedBox(height: AppSpacing.xl),
              AccountTypeSelector(
                selected: _type,
                onChanged: (t) => setState(() {
                  _type = t;
                  if (t != AccountType.CREDIT_CARD) {
                    _creditLimitController.clear();
                  }
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              _label('Hesap Adı'),
              const SizedBox(height: AppSpacing.sm),
              AccountFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                hintText: _type.label,
                prefixIcon: _type.defaultIcon,
                textInputAction: _type == AccountType.CREDIT_CARD
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (_type == AccountType.CREDIT_CARD) {
                    _creditLimitFocus.requestFocus();
                  }
                },
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Hesap adı gerekli' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AccountCurrencySelector(
                selected: _currency,
                onChanged: (c) => setState(() => _currency = c),
              ),
              if (_type == AccountType.CREDIT_CARD) ...[
                const SizedBox(height: AppSpacing.xl),
                _label('Kredi Kartı Detayları'),
                const SizedBox(height: AppSpacing.sm),
                AccountFormField(
                  controller: _creditLimitController,
                  focusNode: _creditLimitFocus,
                  hintText: 'Kredi limiti',
                  prefixIcon: Icons.credit_card_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  validator: (v) {
                    if (_type != AccountType.CREDIT_CARD) return null;
                    if (v == null || v.trim().isEmpty) {
                      return 'Kredi limiti gerekli';
                    }
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Geçerli bir limit girin';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AccountDayDropdown(
                        label: 'Ekstre Günü',
                        value: _statementDay,
                        onChanged: (d) =>
                            setState(() => _statementDay = d),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AccountDayDropdown(
                        label: 'Son Ödeme Günü',
                        value: _paymentDueDay,
                        onChanged: (d) =>
                            setState(() => _paymentDueDay = d),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AccountDefaultToggle(
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
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Değişiklikleri Kaydet'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTypography.labelMd
            .copyWith(color: AppColors.onSurfaceVariant),
      );
}
