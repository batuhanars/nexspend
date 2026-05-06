import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/account_model.dart';
import '../../shared/widgets/split_amount_field.dart' show ThousandsFormatter;
import '../bloc/account_bloc.dart';
import '../widgets/account_form_widgets.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({
    super.key,
    this.initialType,
    this.initialBankName,
  });

  /// Açılış tipi — fiş tarama akışından "kredi kartı tespit edildi" gibi
  /// hint'le geliyorsa kullanıcı tip seçimini atlar.
  final AccountType? initialType;

  /// Banka adı pre-fill — `BANK` tipinde chip'lerle (case-insensitive) eşleşirse
  /// otomatik seçilir, eşleşmezse "Diğer" chip'i seçilip alana yazılır.
  final String? initialBankName;

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _creditLimitController = TextEditingController();

  late AccountType _type;
  String _currency = 'TRY';
  int _statementDay = 1;
  int _paymentDueDay = 10;
  bool _isDefault = false;
  String? _selectedBank;

  static const _turkishBanks = [
    'Ziraat Bankası',
    'Halkbank',
    'Vakıfbank',
    'İş Bankası',
    'Garanti BBVA',
    'Akbank',
    'Yapı Kredi',
    'QNB Finansbank',
    'Denizbank',
    'TEB',
    'HSBC',
    'ING',
    'Odeabank',
    'Şekerbank',
  ];

  final _nameFocus = FocusNode();
  final _balanceFocus = FocusNode();
  final _creditLimitFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? AccountType.BANK;
    _applyInitialBankName();
  }

  void _applyInitialBankName() {
    final hint = widget.initialBankName;
    if (hint == null) return;
    if (_type == AccountType.BANK) {
      // Chip listesinde case/diakritik-insensitive eşleşme dene.
      final normalized = _normalizeBankKey(hint);
      final chip = _turkishBanks.cast<String?>().firstWhere(
            (b) => b != null && _normalizeBankKey(b) == normalized,
            orElse: () => null,
          );
      if (chip != null) {
        _selectedBank = chip;
        _nameController.text = chip;
      } else {
        _selectedBank = 'other';
        _nameController.text = hint;
      }
    } else {
      _nameController.text = hint;
    }
  }

  static String _normalizeBankKey(String s) => s
      .toUpperCase()
      .replaceAll('İ', 'I')
      .replaceAll('Ş', 'S')
      .replaceAll('Ğ', 'G')
      .replaceAll('Ü', 'U')
      .replaceAll('Ö', 'O')
      .replaceAll('Ç', 'C')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

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

  /// "1.234" → 1234.0. Boş veya geçersizse null.
  double? _parseAmount(String text) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '.').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void _submit() {
    if (_type == AccountType.BANK && _selectedBank == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rawBalance = _parseAmount(_balanceController.text) ?? 0.0;
    final creditLimit = _parseAmount(_creditLimitController.text) ?? 0.0;

    if (_type == AccountType.CREDIT_CARD && creditLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.of(context).creditLimitRequired),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    // Kredi kartında kullanıcı pozitif borç tutarı girer; backend negatif
    // bakiye olarak saklar.
    final balance =
        _type == AccountType.CREDIT_CARD ? -rawBalance : rawBalance;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': _type.name,
      'balance': balance,
      'currency': _currency,
      'isDefault': _isDefault,
      if (_type == AccountType.CREDIT_CARD) ...{
        'creditLimit': creditLimit,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).accountCreatedSuccess),
              backgroundColor: AppColors.secondary,
            ),
          );
          context.pop(state.account);
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
          title: Text(AppStrings.of(context).addAccountTitle),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
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
                  _selectedBank = null;
                  _nameController.clear();
                  _balanceController.clear();
                  _creditLimitController.clear();
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_type == AccountType.BANK)
                _buildBankPicker()
              else ...[
                _label(AppStrings.of(context).accountNameLabel),
                const SizedBox(height: AppSpacing.sm),
                AccountFormField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  hintText: _type.labelOf(context),
                  prefixIcon: _type.defaultIcon,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _balanceFocus.requestFocus(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.of(context).accountNameRequired : null,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _label(_type == AccountType.CREDIT_CARD
                  ? AppStrings.of(context).currentDebt
                  : AppStrings.of(context).startingBalance),
              const SizedBox(height: AppSpacing.sm),
              AccountFormField(
                controller: _balanceController,
                focusNode: _balanceFocus,
                hintText: _type == AccountType.CREDIT_CARD
                    ? AppStrings.of(context).debtHint
                    : '0',
                prefixIcon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                textInputAction: _type == AccountType.CREDIT_CARD
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (_type == AccountType.CREDIT_CARD) {
                    _creditLimitFocus.requestFocus();
                  }
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsFormatter(),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (_parseAmount(v) == null) {
                    return AppStrings.of(context).invalidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AccountCurrencySelector(
                selected: _currency,
                onChanged: (c) => setState(() => _currency = c),
              ),
              if (_type == AccountType.CREDIT_CARD) ...[
                const SizedBox(height: AppSpacing.xl),
                _label(AppStrings.of(context).creditCardDetailsLabel),
                const SizedBox(height: AppSpacing.sm),
                AccountFormField(
                  controller: _creditLimitController,
                  focusNode: _creditLimitFocus,
                  hintText: AppStrings.of(context).creditLimitHint,
                  prefixIcon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsFormatter(),
                  ],
                  validator: (v) {
                    if (_type != AccountType.CREDIT_CARD) return null;
                    if (v == null || v.trim().isEmpty) {
                      return AppStrings.of(context).creditLimitRequired;
                    }
                    final n = _parseAmount(v);
                    if (n == null || n <= 0) {
                      return AppStrings.of(context).creditLimitInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AccountDayDropdown(
                        label: AppStrings.of(context).statementDayLabel,
                        value: _statementDay,
                        onChanged: (d) => setState(() => _statementDay = d),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AccountDayDropdown(
                        label: AppStrings.of(context).paymentDueDayLabel,
                        value: _paymentDueDay,
                        onChanged: (d) => setState(() => _paymentDueDay = d),
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
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(AppStrings.of(context).saveAccount),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(AppStrings.of(context).selectBankLabel),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ..._turkishBanks.map((bank) => _bankChip(bank)),
            _bankChip(AppStrings.of(context).otherBankOption, key: 'other'),
          ],
        ),
        if (_selectedBank == 'other') ...[
          const SizedBox(height: AppSpacing.lg),
          _label(AppStrings.of(context).bankNameLabel),
          const SizedBox(height: AppSpacing.sm),
          AccountFormField(
            controller: _nameController,
            focusNode: _nameFocus,
            hintText: AppStrings.of(context).bankNameHint,
            prefixIcon: AccountType.BANK.defaultIcon,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _balanceFocus.requestFocus(),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? AppStrings.of(context).accountNameRequired : null,
          ),
        ],
      ],
    );
  }

  Widget _bankChip(String name, {String? key}) {
    final chipKey = key ?? name;
    final isSelected = _selectedBank == chipKey;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedBank = chipKey;
        if (key == 'other') {
          _nameController.clear();
        } else {
          _nameController.text = name;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
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
          name,
          style: AppTypography.bodyMd.copyWith(
            color: isSelected ? AppColors.primary : AppColors.onSurface,
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
