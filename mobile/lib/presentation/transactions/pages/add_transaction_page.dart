import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/category_model.dart';
import '../bloc/add_transaction_bloc.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'EXPENSE';
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  AccountModel? _transferToAccount;
  DateTime _date = DateTime.now();
  bool _accountsInitialized = false;

  @override
  void initState() {
    super.initState();
    context.read<AddTransactionBloc>().add(AddTransactionInitialized());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountStr = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);

    if (amount == null || amount <= 0) {
      _showError('Geçerli bir tutar girin.');
      return;
    }
    if (_selectedAccount == null) {
      _showError('Bir hesap seçin.');
      return;
    }
    if (_type == 'TRANSFER' && _transferToAccount == null) {
      _showError('Hedef hesap seçin.');
      return;
    }
    if (_type != 'TRANSFER' && _selectedCategory == null) {
      _showError('Bir kategori seçin.');
      return;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : _selectedCategory?.name ?? 'İşlem';

    final data = <String, dynamic>{
      'type': _type,
      'amount': amount,
      'title': title,
      'accountId': _selectedAccount!.id,
      'transactionDate': _date.toIso8601String(),
      if (_selectedCategory != null) 'categoryId': _selectedCategory!.id,
      if (_noteController.text.trim().isNotEmpty)
        'note': _noteController.text.trim(),
      if (_type == 'TRANSFER' && _transferToAccount != null)
        'transferToAccountId': _transferToAccount!.id,
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddTransactionBloc, AddTransactionState>(
      listener: (context, state) {
        if (state is AddTransactionSuccess) {
          Navigator.of(context).pop(true);
        } else if (state is AddTransactionFailure) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('İşlem Ekle'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
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

            // Varsayılan hesabı bir kez seç
            if (!_accountsInitialized && accounts.isNotEmpty) {
              _selectedAccount = accounts.firstWhere(
                (a) => a.isDefault,
                orElse: () => accounts.first,
              );
              _accountsInitialized = true;
            }

            final filtered = _filteredCategories(categories);

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              children: [
                const SizedBox(height: AppSpacing.lg),
                _TypeSelector(
                  selected: _type,
                  onChanged: (t) => setState(() {
                    _type = t;
                    _selectedCategory = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),
                _AmountField(controller: _amountController, type: _type),
                if (_type != 'TRANSFER' && filtered.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _sectionLabel('Kategori'),
                  const SizedBox(height: AppSpacing.sm),
                  _CategoryGrid(
                    categories: filtered,
                    selected: _selectedCategory,
                    onSelected: (c) => setState(() => _selectedCategory = c),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _sectionLabel('Hesap'),
                const SizedBox(height: AppSpacing.sm),
                _AccountChips(
                  accounts: accounts,
                  selected: _selectedAccount,
                  onSelected: (a) => setState(() => _selectedAccount = a),
                ),
                if (_type == 'TRANSFER') ...[
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel('Hedef Hesap'),
                  const SizedBox(height: AppSpacing.sm),
                  _AccountChips(
                    accounts: accounts
                        .where((a) => a.id != _selectedAccount?.id)
                        .toList(),
                    selected: _transferToAccount,
                    onSelected: (a) =>
                        setState(() => _transferToAccount = a),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _TitleField(controller: _titleController),
                const SizedBox(height: AppSpacing.md),
                _DatePicker(
                  date: _date,
                  onChanged: (d) => setState(() => _date = d),
                ),
                const SizedBox(height: AppSpacing.md),
                _NoteField(controller: _noteController),
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
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Kaydet'),
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant),
      );
}

// ── Tip seçici ─────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const types = [
      (label: 'Gider', value: 'EXPENSE', color: AppColors.tertiary),
      (label: 'Gelir', value: 'INCOME', color: AppColors.secondary),
      (label: 'Transfer', value: 'TRANSFER', color: AppColors.primary),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: types.map((t) {
          final isSelected = selected == t.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? t.color.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl - 4),
                ),
                child: Center(
                  child: Text(
                    t.label,
                    style: AppTypography.bodyMd.copyWith(
                      color:
                          isSelected ? t.color : AppColors.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Tutar alanı ────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.type});
  final TextEditingController controller;
  final String type;

  @override
  Widget build(BuildContext context) {
    final color = type == 'INCOME'
        ? AppColors.secondary
        : type == 'TRANSFER'
            ? AppColors.primary
            : AppColors.tertiary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('₺', style: AppTypography.displayLg.copyWith(color: color)),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 180,
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            autofocus: true,
            textAlign: TextAlign.left,
            style: AppTypography.displayLg.copyWith(color: color),
            cursorColor: color,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: AppTypography.displayLg.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Kategori grid ──────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });
  final List<CategoryModel> categories;
  final CategoryModel? selected;
  final ValueChanged<CategoryModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final isSelected = selected?.id == cat.id;
        final color = cat.cardColor;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: isSelected
                  ? Border.all(color: color, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconMapper.fromString(cat.icon),
                  size: 24,
                  color: isSelected ? color : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  cat.name,
                  style: AppTypography.labelSm.copyWith(
                    color:
                        isSelected ? color : AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Hesap chip'leri ────────────────────────────────────────────────────────

class _AccountChips extends StatelessWidget {
  const _AccountChips({
    required this.accounts,
    required this.selected,
    required this.onSelected,
  });
  final List<AccountModel> accounts;
  final AccountModel? selected;
  final ValueChanged<AccountModel> onSelected;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Text(
        'Hesap bulunamadı',
        style: AppTypography.bodySm
            .copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: accounts.map((a) {
        final isSelected = selected?.id == a.id;
        return GestureDetector(
          onTap: () => onSelected(a),
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
              a.name,
              style: AppTypography.bodyMd.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Açıklama ve not alanları ───────────────────────────────────────────────

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => _field(
        controller: controller,
        hint: 'Açıklama (opsiyonel)',
        icon: Icons.edit_outlined,
        maxLines: 1,
        action: TextInputAction.next,
      );
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => _field(
        controller: controller,
        hint: 'Not (opsiyonel)',
        icon: Icons.notes_outlined,
        maxLines: 2,
        action: TextInputAction.done,
      );
}

Widget _field({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  required int maxLines,
  required TextInputAction action,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    textInputAction: action,
    style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: maxLines > 1 ? 20 : 0),
        child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
      ),
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
        vertical: AppSpacing.lg,
      ),
    ),
  );
}

// ── Tarih seçici ───────────────────────────────────────────────────────────

class _DatePicker extends StatelessWidget {
  const _DatePicker({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final label = isToday
        ? 'Bugün'
        : '${date.day} ${_months[date.month - 1]} ${date.year}';

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
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
        if (picked != null) onChanged(picked);
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
              label,
              style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
