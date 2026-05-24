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
import '../../../data/models/family_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/family_repository.dart';
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
    this.initialSharedBudgetId,
    this.editing,
  });

  final String? initialAccountId;
  final String? initialType;
  final String? initialCategoryId;

  /// Ortak bütçe detayından açıldığında o ortak bütçenin id'si.
  /// Kapsam chip'lerini kilitler (sadece o chip görünür).
  final String? initialSharedBudgetId;

  /// Doluysa edit modu — formu prefill eder.
  final TransactionModel? editing;

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

  List<MySharedBudgetModel> _mySharedBudgets = const [];
  // null = "Kişisel"; doluysa seçilen ortak bütçenin id'si.
  String? _selectedSharedBudgetId;

  /// Form bir bütçe detayından açıldıysa true: kapsam chip'leri kilitli
  late bool _isBudgetLocked;
  bool _sharedBudgetInitialized = false;

  bool _isRecurring = false;
  String _recurringFrequency = 'MONTHLY';
  DateTime? _recurringEndDate;

  bool get _isEditMode => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      // Edit modu: prefill
      _type = editing.type.name;
      _amount = editing.amount;
      _titleController.text = editing.description ?? '';
      _noteController.text = editing.note ?? '';
      _date = editing.date;
      _isBudgetLocked = false;
    } else {
      _type = widget.initialType ?? 'EXPENSE';
      _isBudgetLocked = widget.initialCategoryId != null;
    }
    context
        .read<AddTransactionBloc>()
        .add(AddTransactionInitialized(editingId: editing?.id));
    if (!_isEditMode) {
      _loadMySharedBudgets();
    }
  }

  Future<void> _loadMySharedBudgets() async {
    try {
      final list = await getIt<FamilyRepository>().getMySharedBudgets();
      if (!mounted) return;
      setState(() {
        _mySharedBudgets = list;
        if (!_sharedBudgetInitialized &&
            widget.initialSharedBudgetId != null &&
            list.any((b) => b.id == widget.initialSharedBudgetId)) {
          _selectedSharedBudgetId = widget.initialSharedBudgetId;
        }
        _sharedBudgetInitialized = true;
      });
    } catch (_) {
      _sharedBudgetInitialized = true;
    }
  }

  List<MySharedBudgetModel> _sharedBudgetsForCategory() {
    final c = _selectedCategory;
    if (c == null) return const [];
    return _mySharedBudgets
        .where((b) => b.categoryId == c.id || b.categoryId == c.parentId)
        .toList();
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
    if (_type == 'TRANSFER' && _transferToAccount == null && !_isEditMode) {
      _showError(s.selectTargetAccount);
      return;
    }
    if (_type != 'TRANSFER' && _selectedCategory == null && !_isEditMode) {
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

    if (_isEditMode) {
      // Edit mode: hanya kirim field yang diizinkan PATCH
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
      };
      context.read<AddTransactionBloc>().add(AddTransactionSubmitted(data));
    } else {
      final data = <String, dynamic>{
        'type': _type,
        'amount': amount,
        'title': title,
        'accountId': _selectedAccount!.id,
        'transactionDate': submitDate.toUtc().toIso8601String(),
        if (_selectedCategory != null) 'categoryId': _selectedCategory!.id,
        if (_selectedSharedBudgetId != null)
          'sharedBudgetId': _selectedSharedBudgetId,
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
    final s = AppStrings.of(context);
    return BlocListener<AddTransactionBloc, AddTransactionState>(
      listener: (context, state) {
        if (state is AddTransactionSuccess) {
          if (state.isEditMode) {
            // Edit: liste refresh için aynı event yeterli
            getIt<AppEvents>().transactionAdded();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.transactionUpdatedSuccess),
                backgroundColor: AppColors.secondary,
              ),
            );
          } else {
            getIt<AppEvents>().transactionAdded();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.transactionCreatedSuccess),
                backgroundColor: AppColors.secondary,
              ),
            );
          }
          context.pop(true);
        } else if (state is AddTransactionFailure) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? s.editTransactionTitle : s.addTransactionBtn),
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
              final editing = widget.editing;
              if (editing != null && !_accountsInitialized) {
                // Edit modunda mevcut hesabı prefill et
                final match = accounts
                    .where((a) => a.id == editing.account?.id)
                    .toList();
                _selectedAccount = match.isNotEmpty
                    ? match.first
                    : accounts.firstWhere(
                        (a) => a.isDefault,
                        orElse: () => accounts.first,
                      );
              } else {
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
              }
              _accountsInitialized = true;
            }

            final filtered = _filteredCategories(categories);

            if (!_categoryInitialized) {
              final editing = widget.editing;
              if (editing != null && editing.category != null) {
                final match = categories
                    .where((c) => c.id == editing.category!.id)
                    .toList();
                if (match.isNotEmpty) {
                  _selectedCategory = match.first;
                  _categoryInitialized = true;
                }
              } else if (widget.initialCategoryId != null) {
                final preselectId = widget.initialCategoryId;
                final match = categories
                    .where((c) => c.id == preselectId)
                    .toList();
                if (match.isNotEmpty) {
                  _selectedCategory = match.first;
                  _categoryInitialized = true;
                }
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
                    _selectedSharedBudgetId = null;
                    _isBudgetLocked = false;
                    if (t == 'INCOME' &&
                        _selectedAccount?.type == AccountType.CREDIT_CARD) {
                      _selectedAccount = null;
                    }
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),
                TransactionAmountField(
                  onChanged: (v) => setState(() => _amount = v),
                  type: _type,
                  initialValue: widget.editing?.amount,
                ),
                if (_type != 'TRANSFER' && filtered.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _sectionLabel(s.categoryLabel),
                  const SizedBox(height: AppSpacing.sm),
                  TransactionCategoryGrid(
                    categories: filtered,
                    selected: _selectedCategory,
                    onSelected: (c) => setState(() {
                      final changed = c.id != _selectedCategory?.id;
                      _selectedCategory = c;
                      if (changed && !_isEditMode) {
                        _selectedSharedBudgetId = null;
                        _isBudgetLocked = false;
                      }
                    }),
                  ),
                ],
                if (!_isEditMode &&
                    _type == 'EXPENSE' &&
                    (_isBudgetLocked ||
                        _sharedBudgetsForCategory().isNotEmpty)) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel(s.budgetScopeLabel),
                  const SizedBox(height: AppSpacing.sm),
                  _BudgetScopeChips(
                    budgets: _sharedBudgetsForCategory(),
                    selectedId: _selectedSharedBudgetId,
                    personalLabel: s.budgetScopePersonal,
                    isLocked: _isBudgetLocked,
                    lockedSharedBudget: _isBudgetLocked &&
                            _selectedSharedBudgetId != null
                        ? _mySharedBudgets
                            .where((b) => b.id == _selectedSharedBudgetId)
                            .firstOrNull
                        : null,
                    onSelected: (id) =>
                        setState(() => _selectedSharedBudgetId = id),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _sectionLabel(s.accountLabel),
                const SizedBox(height: AppSpacing.sm),
                AccountChips(
                  accounts: _type == 'INCOME'
                      ? accounts
                          .where((a) => a.type != AccountType.CREDIT_CARD)
                          .toList()
                      : accounts,
                  selected: _selectedAccount,
                  onSelected: (a) => setState(() => _selectedAccount = a),
                ),
                if (_type == 'TRANSFER') ...[
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel(s.targetAccountLabel),
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
                // Tekrarlayan toggle: yalnız create modunda göster
                if (!_isEditMode) ...[
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
                ],
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
                      : Text(_isEditMode ? s.save : s.save),
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

class _BudgetScopeChips extends StatelessWidget {
  const _BudgetScopeChips({
    required this.budgets,
    required this.selectedId,
    required this.personalLabel,
    required this.onSelected,
    this.isLocked = false,
    this.lockedSharedBudget,
  });

  final List<MySharedBudgetModel> budgets;
  final String? selectedId;
  final String personalLabel;
  final ValueChanged<String?> onSelected;
  final bool isLocked;
  final MySharedBudgetModel? lockedSharedBudget;

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      final label = lockedSharedBudget != null
          ? '${lockedSharedBudget!.groupName} · ${lockedSharedBudget!.name}'
          : personalLabel;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _Chip(label: label, selected: true, onTap: () {}),
        ],
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _Chip(
          label: personalLabel,
          selected: selectedId == null,
          onTap: () => onSelected(null),
        ),
        for (final b in budgets)
          _Chip(
            label: '${b.groupName} · ${b.name}',
            selected: selectedId == b.id,
            onTap: () => onSelected(b.id),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Text(
          label,
          style: AppTypography.bodySm.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
