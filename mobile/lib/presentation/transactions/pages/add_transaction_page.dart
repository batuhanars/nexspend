import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/app_events.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/category_model.dart';
import '../bloc/add_transaction_bloc.dart';
import '../widgets/account_chips.dart';
import '../widgets/recurring_section.dart';
import '../widgets/transaction_amount_field.dart';
import '../widgets/transaction_category_grid.dart';
import '../widgets/transaction_date_picker.dart';
import '../widgets/transaction_text_fields.dart';
import '../widgets/type_selector.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({
    super.key,
    this.initialAccountId,
    this.initialType,
    this.initialCategoryId,
  });

  final String? initialAccountId;
  final String? initialType;
  final String? initialCategoryId;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  double? _amount;
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late String _type;
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  AccountModel? _transferToAccount;
  DateTime _date = DateTime.now();
  bool _accountsInitialized = false;
  bool _categoryInitialized = false;

  bool _isRecurring = false;
  String _recurringFrequency = 'MONTHLY';
  DateTime? _recurringEndDate;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'EXPENSE';
    context.read<AddTransactionBloc>().add(AddTransactionInitialized());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = _amount;

    final s = AppStrings.of(context);
    if (amount == null || amount <= 0) {
      _showError(s.enterValidAmount);
      return;
    }
    if (_selectedAccount == null) {
      _showError(s.selectAccount);
      return;
    }
    if (_type == 'TRANSFER' && _transferToAccount == null) {
      _showError(s.selectTargetAccount);
      return;
    }
    if (_type != 'TRANSFER' && _selectedCategory == null) {
      _showError(s.selectCategory);
      return;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : _selectedCategory?.name ?? AppStrings.of(context).transactionFallback;

    final now = DateTime.now();
    final isToday = _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
    final submitDate = isToday ? now : _date;

    final data = <String, dynamic>{
      'type': _type,
      'amount': amount,
      'title': title,
      'accountId': _selectedAccount!.id,
      'transactionDate': submitDate.toUtc().toIso8601String(),
      if (_selectedCategory != null) 'categoryId': _selectedCategory!.id,
      if (_noteController.text.trim().isNotEmpty)
        'note': _noteController.text.trim(),
      if (_type == 'TRANSFER' && _transferToAccount != null)
        'transferToAccountId': _transferToAccount!.id,
      'isRecurring': _isRecurring,
      if (_isRecurring) 'frequency': _recurringFrequency,
      if (_isRecurring && _recurringEndDate != null)
        'endDate': _recurringEndDate!.toUtc().toIso8601String(),
    };

    context.read<AddTransactionBloc>().add(AddTransactionSubmitted(data));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  List<CategoryModel> _filteredCategories(List<CategoryModel> all) {
    return all.where((c) {
      if (_type == 'INCOME') {
        return c.type == CategoryType.INCOME || c.type == CategoryType.BOTH;
      }
      return c.type == CategoryType.EXPENSE || c.type == CategoryType.BOTH;
    }).toList();
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant),
      );

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddTransactionBloc, AddTransactionState>(
      listener: (context, state) {
        if (state is AddTransactionSuccess) {
          getIt<AppEvents>().transactionAdded();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).transactionCreatedSuccess),
              backgroundColor: AppColors.secondary,
            ),
          );
          context.pop(true);
        } else if (state is AddTransactionFailure) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.of(context).addTransactionBtn),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<AddTransactionBloc, AddTransactionState>(
          builder: (context, state) {
            if (state is AddTransactionDataLoading ||
                state is AddTransactionInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final categories = _categoriesFrom(state);
            final accounts = _accountsFrom(state);

            if (!_accountsInitialized && accounts.isNotEmpty) {
              final preselect = widget.initialAccountId;
              _selectedAccount = preselect != null
                  ? accounts.firstWhere(
                      (a) => a.id == preselect,
                      orElse: () => accounts.firstWhere(
                        (a) => a.isDefault,
                        orElse: () => accounts.first,
                      ),
                    )
                  : accounts.firstWhere(
                      (a) => a.isDefault,
                      orElse: () => accounts.first,
                    );
              _accountsInitialized = true;
            }

            final filtered = _filteredCategories(categories);

            if (!_categoryInitialized && widget.initialCategoryId != null) {
              final preselectId = widget.initialCategoryId;
              final match = categories
                  .where((c) => c.id == preselectId)
                  .toList();
              if (match.isNotEmpty) {
                _selectedCategory = match.first;
                _categoryInitialized = true;
              }
            }

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              children: [
                const SizedBox(height: AppSpacing.lg),
                TransactionTypeSelector(
                  selected: _type,
                  onChanged: (t) => setState(() {
                    _type = t;
                    _selectedCategory = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),
                TransactionAmountField(
                    onChanged: (v) => setState(() => _amount = v),
                    type: _type),
                if (_type != 'TRANSFER' && filtered.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _sectionLabel(AppStrings.of(context).categoryLabel),
                  const SizedBox(height: AppSpacing.sm),
                  TransactionCategoryGrid(
                    categories: filtered,
                    selected: _selectedCategory,
                    onSelected: (c) =>
                        setState(() => _selectedCategory = c),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _sectionLabel(AppStrings.of(context).accountLabel),
                const SizedBox(height: AppSpacing.sm),
                AccountChips(
                  accounts: accounts,
                  selected: _selectedAccount,
                  onSelected: (a) => setState(() => _selectedAccount = a),
                ),
                if (_type == 'TRANSFER') ...[
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel(AppStrings.of(context).targetAccountLabel),
                  const SizedBox(height: AppSpacing.sm),
                  AccountChips(
                    accounts: accounts
                        .where((a) => a.id != _selectedAccount?.id)
                        .toList(),
                    selected: _transferToAccount,
                    onSelected: (a) =>
                        setState(() => _transferToAccount = a),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                TransactionTitleField(controller: _titleController),
                const SizedBox(height: AppSpacing.md),
                TransactionDatePicker(
                  date: _date,
                  onChanged: (d) => setState(() {
                    _date = DateTime(
                        d.year, d.month, d.day, _date.hour, _date.minute);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                TransactionNoteField(controller: _noteController),
                const SizedBox(height: AppSpacing.xl),
                RecurringSection(
                  isRecurring: _isRecurring,
                  frequency: _recurringFrequency,
                  endDate: _recurringEndDate,
                  onToggle: (val) => setState(() => _isRecurring = val),
                  onFrequencyChanged: (f) =>
                      setState(() => _recurringFrequency = f),
                  onEndDateChanged: (d) =>
                      setState(() => _recurringEndDate = d),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.lg,
            ),
            child: BlocBuilder<AddTransactionBloc, AddTransactionState>(
              builder: (context, state) {
                final isSubmitting = state is AddTransactionSubmitting;
                return FilledButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(AppStrings.of(context).save),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<CategoryModel> _categoriesFrom(AddTransactionState s) {
    if (s is AddTransactionReady) return s.categories;
    if (s is AddTransactionSubmitting) return s.categories;
    if (s is AddTransactionFailure) return s.categories;
    return const [];
  }

  List<AccountModel> _accountsFrom(AddTransactionState s) {
    if (s is AddTransactionReady) return s.accounts;
    if (s is AddTransactionSubmitting) return s.accounts;
    if (s is AddTransactionFailure) return s.accounts;
    return const [];
  }
}
