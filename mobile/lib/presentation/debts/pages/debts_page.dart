import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/debt_model.dart';
import '../bloc/debts_bloc.dart';

class DebtsPage extends StatelessWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<DebtsBloc>().add(const DebtsLoadRequested());
    return const _DebtsView();
  }
}

class _DebtsView extends StatelessWidget {
  const _DebtsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DebtsBloc, DebtsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                context.read<DebtsBloc>().add(const DebtsRefreshRequested()),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                if (state is DebtsLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (state is DebtsError)
                  SliverFillRemaining(child: _ErrorView(message: state.message))
                else if (state is DebtsLoaded) ...[
                  SliverToBoxAdapter(
                    child: _SummaryCards(summary: state.summary),
                  ),
                  SliverToBoxAdapter(
                    child: _FilterChips(activeFilter: state.filter),
                  ),
                  if (state.debts.isEmpty)
                    const SliverFillRemaining(child: _EmptyView())
                  else
                    _DebtList(debts: state.debts),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      title: Text('Borçlar', style: AppTypography.headlineSm),
      centerTitle: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    );
  }

  void _showAddDebtSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<DebtsBloc>(),
        child: const _AddDebtSheet(),
      ),
    );
  }
}

// ── Özet kartları ──────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});
  final DebtSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Alacaklarım',
              total: summary.totalLent,
              remaining: summary.totalLentRemaining,
              color: AppColors.secondary,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryCard(
              label: 'Borçlarım',
              total: summary.totalBorrowed,
              remaining: summary.totalBorrowedRemaining,
              color: AppColors.tertiary,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.total,
    required this.remaining,
    required this.color,
    required this.icon,
  });
  final String label;
  final double total;
  final double remaining;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.labelSm.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            CurrencyFormatter.format(remaining),
            style: AppTypography.titleSm.copyWith(color: AppColors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Toplam: ${CurrencyFormatter.formatCompact(total)}',
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Filtre chip'leri ───────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.activeFilter});
  final String? activeFilter;

  static const _filters = [
    (label: 'Tümü', value: null),
    (label: 'Alacak', value: 'LENT'),
    (label: 'Borç', value: 'BORROWED'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: _filters.map((f) {
          final isActive = activeFilter == f.value;
          final isLast = f == _filters.last;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
              child: GestureDetector(
                onTap: () => context
                    .read<DebtsBloc>()
                    .add(DebtsFilterChanged(f.value)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: isActive
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      height: 1.0,
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

// ── Borç listesi ──────────────────────────────────────────────────────────

class _DebtList extends StatelessWidget {
  const _DebtList({required this.debts});
  final List<DebtModel> debts;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _DebtCard(debt: debts[i]),
        childCount: debts.length,
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt});
  final DebtModel debt;

  @override
  Widget build(BuildContext context) {
    final isLent = debt.type == DebtType.LENT;
    final color = debt.type.color;

    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: AppColors.errorContainer,
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) =>
          context.read<DebtsBloc>().add(DebtDeleteRequested(debt.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.xs,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(debt.type.icon, size: 18, color: color),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: AppTypography.bodyMd
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (debt.description != null)
                          Text(
                            debt.description!,
                            style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(debt.remainingAmount),
                        style: AppTypography.titleSm.copyWith(color: color),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: debt.status.color.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          debt.status.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: debt.status.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: debt.progress,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CurrencyFormatter.formatCompact(debt.paidAmount)} ödendi',
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  Row(
                    children: [
                      if (debt.hasInstallments)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Icon(Icons.receipt_long_outlined,
                              size: 12,
                              color: AppColors.onSurfaceVariant),
                        ),
                      if (debt.dueDate != null)
                        Text(
                          _dueDateLabel(debt.dueDate!),
                          style: AppTypography.bodySm.copyWith(
                            color: _dueDateColor(debt.dueDate!),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (debt.status != DebtStatus.PAID) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showPaymentSheet(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color, width: 1.5),
                      foregroundColor: color,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                    ),
                    child: Text(
                      isLent ? 'Ödeme Aldım' : 'Ödeme Yap',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dueDateLabel(DateTime due) {
    final diff = due.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Vadesi geçti';
    if (diff == 0) return 'Bugün vadesi doluyor';
    if (diff == 1) return 'Yarın vadesi doluyor';
    return '${due.day}.${due.month.toString().padLeft(2, '0')}.${due.year}';
  }

  Color _dueDateColor(DateTime due) {
    final diff = due.difference(DateTime.now()).inDays;
    if (diff < 0) return AppColors.error;
    if (diff <= 3) return AppColors.warning;
    return AppColors.onSurfaceVariant;
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Borcu Sil', style: AppTypography.titleSm),
        content: Text(
          '${debt.personName} ile olan borç kaydı silinecek.',
          style: AppTypography.bodyMd
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<DebtsBloc>(),
        child: _PaymentSheet(debt: debt),
      ),
    );
  }
}

// ── Ödeme bottom sheet ─────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.debt});
  final DebtModel debt;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text =
        widget.debt.remainingAmount.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountStr = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;
    context.read<DebtsBloc>().add(DebtPaymentRecorded(
          debtId: widget.debt.id,
          data: {
            'amount': amount,
            if (_noteController.text.trim().isNotEmpty)
              'note': _noteController.text.trim(),
          },
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLent = widget.debt.type == DebtType.LENT;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLent ? 'Ödeme Aldım' : 'Ödeme Yap',
                style: AppTypography.headlineSm,
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.debt.personName,
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: AppTypography.headlineSm,
            decoration: InputDecoration(
              labelText: 'Tutar (₺)',
              labelStyle: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: AppColors.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            style: AppTypography.bodyMd,
            decoration: InputDecoration(
              hintText: 'Not (opsiyonel)',
              hintStyle: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: AppColors.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
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
            child: Text(isLent ? 'Tahsilat Kaydet' : 'Ödeme Kaydet'),
          ),
        ],
      ),
    );
  }
}

// ── Borç ekleme bottom sheet ───────────────────────────────────────────────

class _AddDebtSheet extends StatefulWidget {
  const _AddDebtSheet();

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  String _type = 'BORROWED';
  DateTime? _dueDate;
  bool _hasInstallments = false;
  int _installmentCount = 3;

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final amountStr = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);

    if (name.isEmpty) return;
    if (amount == null || amount <= 0) return;

    final data = <String, dynamic>{
      'type': _type,
      'personName': name,
      'totalAmount': amount,
      if (_descController.text.trim().isNotEmpty)
        'description': _descController.text.trim(),
      if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
      'hasInstallments': _hasInstallments,
      if (_hasInstallments) 'installmentCount': _installmentCount,
    };

    context.read<DebtsBloc>().add(DebtCreated(data));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Borç Ekle', style: AppTypography.headlineSm),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _TypeToggle(
              selected: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: AppSpacing.lg),
            _inputField(_nameController, 'Kişi / Kurum Adı', Icons.person_outline),
            const SizedBox(height: AppSpacing.md),
            _inputField(
              _amountController,
              'Tutar (₺)',
              Icons.attach_money_rounded,
              numeric: true,
            ),
            const SizedBox(height: AppSpacing.md),
            _inputField(
                _descController, 'Açıklama (opsiyonel)', Icons.notes_outlined),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
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
                          ? 'Vade tarihi (opsiyonel)'
                          : '${_dueDate!.day} ${_months[_dueDate!.month - 1]} ${_dueDate!.year}',
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
                          child: Text('Taksitli',
                              style: AppTypography.bodyMd),
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
                          Text('Taksit Sayısı:',
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
                          Text(
                            '$_installmentCount',
                            style: AppTypography.titleSm,
                          ),
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
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool numeric = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.onSurfaceVariant, fontSize: 14),
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
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const types = [
      (label: 'Borç', value: 'BORROWED', color: AppColors.tertiary),
      (label: 'Alacak', value: 'LENT', color: AppColors.secondary),
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
                      color: isSelected ? t.color : AppColors.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
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

// ── Boş ve hata ekranları ──────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 64,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Borç kaydı yok', style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sağ alttaki + butonuyla\nilk borç kaydını ekleyin',
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.lg),
          Text(message,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonal(
            onPressed: () =>
                context.read<DebtsBloc>().add(const DebtsLoadRequested()),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}
