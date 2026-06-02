import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../navigation/route_names.dart';
import '../../../core/utils/category_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/budget_add_entry_sheet.dart';
import '../bloc/budgets_bloc.dart';
import '../bloc/budgets_event.dart';
import '../bloc/budgets_state.dart';
import '../widgets/edit_budget_sheet.dart';

enum _BudgetMenuAction { edit, delete }

class BudgetDetailPage extends StatefulWidget {
  const BudgetDetailPage({
    super.key,
    this.budget,
    this.budgetId,
    this.initialTabIndex = 0,
  }) : assert(budget != null || budgetId != null);

  final BudgetModel? budget;
  final String? budgetId;
  final int initialTabIndex;

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends State<BudgetDetailPage>
    with SingleTickerProviderStateMixin {
  BudgetModel? _budget;
  bool _loading = false;
  late Future<List<TransactionModel>> _txFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    if (widget.budget != null) {
      _budget = widget.budget;
      _txFuture = _loadTransactions();
    } else {
      _loading = true;
      _txFuture = Future.value(const []);
      _fetchById();
    }
  }

  Future<void> _fetchById() async {
    try {
      final budget = await getIt<BudgetRepository>().getById(widget.budgetId!);
      if (!mounted) return;
      setState(() {
        _budget = budget;
        _loading = false;
        _txFuture = _loadTransactions();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<TransactionModel>> _loadTransactions() async {
    final budget = _budget;
    if (budget == null || budget.category == null) return [];
    final repo = getIt<TransactionRepository>();
    final result = await repo.getTransactions(
      page: 1,
      limit: 200,
      type: 'EXPENSE',
      categoryId: budget.category!.id,
      sharedBudgetId: 'null',
      startDate: budget.startDate.toIso8601String(),
      endDate: budget.endDate.toIso8601String(),
    );
    return result.data;
  }

  void _refreshFromBloc(BudgetModel updated) {
    setState(() {
      _budget = updated;
      _txFuture = _loadTransactions();
    });
  }

  String get _budgetId => _budget?.id ?? widget.budgetId!;

  Future<void> _openEdit() async {
    final budget = _budget;
    if (budget == null) return;
    final bloc = context.read<BudgetsBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EditBudgetSheet(budget: budget),
      ),
    );
  }

  Future<void> _openAddEntrySheet() async {
    final budget = _budget;
    if (budget == null || budget.category == null) return;
    final choice = await showBudgetAddEntrySheet(context);
    if (choice == null || !mounted) return;

    switch (choice) {
      case BudgetAddEntryChoice.expense:
        await context.push(
          RouteNames.addTransaction,
          extra: {'type': 'EXPENSE', 'categoryId': budget.category!.id},
        );
        break;
      case BudgetAddEntryChoice.receipt:
        await context.push(
          RouteNames.receiptScanner,
          extra: <String, String?>{'categoryId': budget.category!.id},
        );
        break;
    }

    if (!mounted) return;
    context.read<BudgetsBloc>().add(const BudgetsRefreshRequested());
    setState(() {
      _txFuture = _loadTransactions();
    });
  }

  Future<void> _confirmDelete() async {
    final budget = _budget;
    if (budget == null) return;
    final s = AppStrings.of(context);
    final colors = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceContainerHigh,
        title: Text(s.deleteBudgetTitle, style: AppTypography.titleSm),
        content: Text(
          s.deleteBudgetContent(budget.name),
          style: AppTypography.bodyMd.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              s.cancel,
              style: AppTypography.bodyMd.copyWith(color: colors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.delete,
              style: AppTypography.bodyMd.copyWith(color: colors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<BudgetsBloc>().add(BudgetDeleteRequested(budget.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).budgetDeletedSuccess),
          backgroundColor: context.colors.income,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    final budget = _budget;
    if (budget == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: Text(
            s.serverError,
            style: AppTypography.bodyMd.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return BlocListener<BudgetsBloc, BudgetsState>(
      listenWhen: (_, curr) =>
          curr is BudgetsLoaded || curr is BudgetsUpdateError,
      listener: (context, state) {
        if (state is BudgetsLoaded) {
          final match = state.budgets.where((b) => b.id == budget.id).toList();
          if (match.isNotEmpty) _refreshFromBloc(match.first);
        } else if (state is BudgetsUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: context.colors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(budget.name, style: AppTypography.headlineSm),
              if (!budget.isActive) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    s.budgetArchivedBadge,
                    style: AppTypography.labelSm.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!budget.isActive)
              IconButton(
                icon: Icon(Icons.delete_outline, color: colors.error),
                tooltip: s.delete,
                onPressed: _confirmDelete,
              )
            else ...[
              IconButton(
                icon: Icon(Icons.add_rounded, color: colors.primary),
                tooltip: s.budgetAddTransaction,
                onPressed: _openAddEntrySheet,
              ),
              PopupMenuButton<_BudgetMenuAction>(
                icon: Icon(Icons.more_vert, color: colors.onSurface),
                color: colors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                onSelected: (action) {
                  switch (action) {
                    case _BudgetMenuAction.edit:
                      _openEdit();
                    case _BudgetMenuAction.delete:
                      _confirmDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _BudgetMenuAction.edit,
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 20, color: colors.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.md),
                        Text(s.edit, style: AppTypography.bodyMd),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _BudgetMenuAction.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 20, color: colors.error),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          s.delete,
                          style: AppTypography.bodyMd.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
          bottom: budget.isActive
              ? TabBar(
                  controller: _tabController,
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.onSurfaceVariant,
                  indicatorColor: colors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(text: s.budgetTabCurrentPeriod),
                    Tab(text: s.budgetTabHistory),
                  ],
                )
              : null,
        ),
        body: budget.isActive
            ? TabBarView(
                controller: _tabController,
                children: [
                  _CurrentPeriodView(
                    budget: budget,
                    txFuture: _txFuture,
                    onRefresh: () async {
                      context.read<BudgetsBloc>().add(
                        const BudgetsRefreshRequested(),
                      );
                      setState(() {
                        _txFuture = _loadTransactions();
                      });
                      await _txFuture;
                    },
                    onTransactionChanged: () {
                      context.read<BudgetsBloc>().add(
                        const BudgetsRefreshRequested(),
                      );
                      setState(() {
                        _txFuture = _loadTransactions();
                      });
                    },
                  ),
                  _HistoryView(budgetId: _budgetId),
                ],
              )
            : _CurrentPeriodView(
                budget: budget,
                txFuture: _txFuture,
                onRefresh: () async {
                  context.read<BudgetsBloc>().add(
                    const BudgetsRefreshRequested(),
                  );
                  setState(() {
                    _txFuture = _loadTransactions();
                  });
                  await _txFuture;
                },
                onTransactionChanged: () {
                  context.read<BudgetsBloc>().add(
                    const BudgetsRefreshRequested(),
                  );
                  setState(() {
                    _txFuture = _loadTransactions();
                  });
                },
              ),
      ),
    );
  }
}

class _CurrentPeriodView extends StatelessWidget {
  const _CurrentPeriodView({
    required this.budget,
    required this.txFuture,
    required this.onRefresh,
    this.onTransactionChanged,
  });

  final BudgetModel budget;
  final Future<List<TransactionModel>> txFuture;
  final Future<void> Function() onRefresh;
  final VoidCallback? onTransactionChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surfaceContainerHigh,
      onRefresh: onRefresh,
      child: FutureBuilder<List<TransactionModel>>(
        future: txFuture,
        builder: (context, snapshot) {
          final transactions = snapshot.data ?? const <TransactionModel>[];
          final loading = snapshot.connectionState == ConnectionState.waiting;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              0,
            ),
            children: [
              _SummaryCard(budget: budget),
              const SizedBox(height: AppSpacing.xl),
              if (transactions.isNotEmpty) ...[
                _DailySpendChart(
                  transactions: transactions,
                  statusColor: budget.statusColor,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text(s.budgetTransactionsTitle, style: AppTypography.labelSm),
              const SizedBox(height: AppSpacing.md),
              if (loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  ),
                )
              else if (transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(
                    child: Text(
                      s.budgetNoTransactions,
                      style: AppTypography.bodyMd.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ..._buildGroupedTransactions(
                  transactions,
                  context,
                  onTransactionChanged: onTransactionChanged,
                ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedTransactions(
    List<TransactionModel> transactions,
    BuildContext context, {
    VoidCallback? onTransactionChanged,
  }) {
    final colors = context.colors;
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    final groups = <String, List<TransactionModel>>{};
    for (final t in sorted) {
      final key = DateFormatter.formatGroupHeader(t.date, context);
      groups.putIfAbsent(key, () => []).add(t);
    }
    final widgets = <Widget>[];
    groups.forEach((header, items) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            header,
            style: AppTypography.labelSm.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      );
      for (final t in items) {
        widgets.add(
          _BudgetTransactionTile(
            transaction: t,
            onChanged: onTransactionChanged,
          ),
        );
      }
    });
    return widgets;
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView({required this.budgetId});
  final String budgetId;

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  late Future<List<BudgetHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<BudgetRepository>().getHistory(widget.budgetId);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    return FutureBuilder<List<BudgetHistoryEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_toggle_off_outlined,
                    size: 48,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    s.budgetHistoryEmpty,
                    style: AppTypography.bodyMd.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.md,
          ),
          children: [
            _HistoryBarChart(entries: entries),
            const SizedBox(height: AppSpacing.xl),
            for (final entry in entries) ...[
              _HistoryEntryCard(entry: entry),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      },
    );
  }
}

class _HistoryBarChart extends StatelessWidget {
  const _HistoryBarChart({required this.entries});
  final List<BudgetHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    final display = entries.length > 12 ? entries.sublist(0, 12) : entries;
    final reversed = display.reversed.toList();

    final maxVal = reversed
        .expand((e) => [e.amount, e.spent])
        .fold<double>(1, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.budgetHistoryChartTitle, style: AppTypography.labelSm),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceContainerHighest,
                    getTooltipItem: (group, _, rod, rodIdx) {
                      final e = reversed[group.x];
                      return BarTooltipItem(
                        rodIdx == 0
                            ? CurrencyFormatter.format(e.amount)
                            : CurrencyFormatter.format(e.spent),
                        AppTypography.labelSm.copyWith(
                          color: colors.onSurface,
                        ),
                      );
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= reversed.length) {
                          return const SizedBox.shrink();
                        }
                        final e = reversed[idx];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${e.startDate.month}/${e.startDate.day.toString().padLeft(2, '0')}',
                            style: AppTypography.labelSm.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 8,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < reversed.length; i++)
                    BarChartGroupData(
                      x: i,
                      groupVertically: false,
                      barRods: [
                        BarChartRodData(
                          toY: reversed[i].amount,
                          width: 6,
                          borderRadius: BorderRadius.circular(3),
                          color: colors.primary.withValues(alpha: 0.3),
                        ),
                        BarChartRodData(
                          toY: reversed[i].spent,
                          width: 6,
                          borderRadius: BorderRadius.circular(3),
                          color: reversed[i].percentage >= 100
                              ? colors.expense
                              : colors.income,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({required this.entry});
  final BudgetHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = entry.percentage.clamp(0, 200).toDouble();
    final color = pct >= 100
        ? colors.expense
        : pct >= 90
            ? colors.warning
            : pct >= 75
                ? colors.expense.withValues(alpha: 0.7)
                : colors.income;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormatter.formatMini(entry.startDate, context)}'
                      ' → ${DateFormatter.formatMini(entry.endDate, context)}',
                      style: AppTypography.bodySm.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(entry.name, style: AppTypography.titleSm),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '%${entry.percentage.toInt()}',
                  style: AppTypography.labelSm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                CurrencyFormatter.format(entry.spent),
                style: AppTypography.bodyMd.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' / ${CurrencyFormatter.format(entry.amount)}',
                style: AppTypography.bodyMd.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.budget});
  final BudgetModel budget;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    final progress = (budget.percentage.clamp(0, 100) / 100).toDouble();
    final category = budget.category;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category?.cardColor.withValues(alpha: 0.15) ??
                      colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconMapper.fromString(
                      category?.icon ?? 'account_balance'),
                  color: category?.cardColor ?? colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category != null)
                      Text(
                        category.localizedName(context),
                        style: AppTypography.bodySm.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      budget.periodLabel(AppStrings.of(context)),
                      style: AppTypography.titleSm,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: budget.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '%${budget.percentage} · ${budget.statusLabel(AppStrings.of(context))}',
                  style: AppTypography.labelSm.copyWith(
                    color: budget.statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            CurrencyFormatter.format(budget.spent),
            style: AppTypography.displayLg.copyWith(
              fontSize: 36,
              color: budget.statusColor,
            ),
          ),
          Text(
            '/ ${CurrencyFormatter.format(budget.amount)}',
            style: AppTypography.bodyMd.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(budget.statusColor),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: s.budgetStatRemaining,
                  value: CurrencyFormatter.format(
                    budget.remaining < 0 ? 0 : budget.remaining,
                  ),
                  color: colors.onSurface,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: s.budgetStatStart,
                  value: DateFormatter.formatMini(budget.startDate, context),
                  color: colors.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: s.budgetStatEnd,
                  value: DateFormatter.formatMini(budget.endDate, context),
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMd.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DailySpendChart extends StatelessWidget {
  const _DailySpendChart({
    required this.transactions,
    required this.statusColor,
  });

  final List<TransactionModel> transactions;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    const days = 14;
    final buckets = List<double>.filled(days, 0);
    final startDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: days - 1));

    for (final t in transactions) {
      final local = t.date.toLocal();
      final d = DateTime(local.year, local.month, local.day);
      final idx = d.difference(startDay).inDays;
      if (idx >= 0 && idx < days) {
        buckets[idx] += t.amount;
      }
    }

    final maxVal = buckets
        .fold<double>(0, (m, v) => v > m ? v : m)
        .clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.of(context).budgetDailyChartTitle,
            style: AppTypography.labelSm,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxVal,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceContainerHighest,
                    getTooltipItem: (group, _, rod, idx) {
                      final date = startDay.add(Duration(days: group.x));
                      return BarTooltipItem(
                        '${DateFormatter.formatMini(date, context)}\n'
                        '${CurrencyFormatter.format(rod.toY)}',
                        AppTypography.labelSm.copyWith(
                          color: colors.onSurface,
                        ),
                      );
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx % 3 != 0 || idx < 0 || idx >= days) {
                          return const SizedBox.shrink();
                        }
                        final date = startDay.add(Duration(days: idx));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${date.day}',
                            style: AppTypography.labelSm.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < days; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: buckets[i],
                          width: 10,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          color: buckets[i] > 0
                              ? statusColor
                              : colors.surfaceContainerHighest,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetTransactionTile extends StatelessWidget {
  const _BudgetTransactionTile({
    required this.transaction,
    this.onChanged,
  });

  final TransactionModel transaction;
  final VoidCallback? onChanged;

  static Color _hexColor(String hex, Color fallback) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconData = IconMapper.fromString(
      transaction.category?.icon ?? 'shopping_cart',
    );
    final color = transaction.category?.color != null
        ? _hexColor(transaction.category!.color!, colors.expense)
        : colors.expense;

    return InkWell(
      onTap: () async {
        final changed = await context.push<bool>(
          RouteNames.transactionDetail(transaction.id),
          extra: {'transaction': transaction},
        );
        if (changed == true && context.mounted) {
          onChanged?.call();
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ??
                        transaction.category?.localizedName(context) ??
                        AppStrings.of(context).transactionFallback,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.account?.name ?? ''}  •  '
                    '${DateFormatter.formatTime(transaction.date)}',
                    style: AppTypography.bodySm.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '-${CurrencyFormatter.format(transaction.amount)}',
              style: AppTypography.bodyMd.copyWith(
                color: colors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
