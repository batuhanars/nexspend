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
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/family_model.dart';
import '../../../data/repositories/family_repository.dart';
import '../../shared/widgets/budget_add_entry_sheet.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event.dart';
import '../bloc/family_state.dart';
import '../widgets/shared_budget_edit_sheet.dart';

enum _BudgetMenuAction { edit, delete }

class SharedBudgetDetailPage extends StatefulWidget {
  const SharedBudgetDetailPage({
    super.key,
    required this.groupId,
    required this.budget,
    this.initialTabIndex = 0,
  });

  final String groupId;
  final SharedBudgetModel budget;
  final int initialTabIndex;

  @override
  State<SharedBudgetDetailPage> createState() => _SharedBudgetDetailPageState();
}

class _SharedBudgetDetailPageState extends State<SharedBudgetDetailPage>
    with SingleTickerProviderStateMixin {
  late SharedBudgetModel _budget;
  late Future<SharedBudgetDetailModel> _future;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _future = _load();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<SharedBudgetDetailModel> _load() async {
    final detail = await getIt<FamilyRepository>().getSharedBudgetExpenses(
      groupId: widget.groupId,
      budgetId: _budget.id,
    );
    if (mounted) {
      setState(() => _budget = detail.budget);
    }
    return detail;
  }

  Future<void> _openAddEntrySheet() async {
    final choice = await showBudgetAddEntrySheet(context);
    if (choice == null || !mounted) return;

    switch (choice) {
      case BudgetAddEntryChoice.expense:
        await context.push(
          RouteNames.addTransaction,
          extra: {
            'type': 'EXPENSE',
            'categoryId': _budget.categoryId,
            'sharedBudgetId': _budget.id,
          },
        );
        break;
      case BudgetAddEntryChoice.receipt:
        await context.push(
          RouteNames.receiptScanner,
          extra: <String, String?>{
            'categoryId': _budget.categoryId,
            'sharedBudgetId': _budget.id,
          },
        );
        break;
    }

    if (!mounted) return;
    setState(() => _future = _load());
  }

  Future<void> _openEdit() async {
    final bloc = context.read<FamilyBloc>();
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
        child: SharedBudgetEditSheet(groupId: widget.groupId, budget: _budget),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerHigh,
          title: Text(s.deleteSharedBudgetTitle, style: AppTypography.titleSm),
          content: Text(
            s.deleteBudgetContent(_budget.name),
            style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel,
                  style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.delete, style: TextStyle(color: colors.error)),
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) {
      context.read<FamilyBloc>().add(
        FamilySharedBudgetDeleteRequested(
          groupId: widget.groupId,
          budgetId: _budget.id,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).sharedBudgetDeletedSuccess),
          backgroundColor: context.colors.secondary,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    final isArchived = !_budget.isActive;

    return BlocListener<FamilyBloc, FamilyState>(
      listenWhen: (_, current) =>
          current is FamilySharedBudgetUpdated ||
          current is FamilySharedBudgetUpdateError,
      listener: (context, state) {
        if (state is FamilySharedBudgetUpdated) {
          setState(() {
            _budget = state.budget;
            _future = _load();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).budgetUpdatedSuccess),
              backgroundColor: context.colors.secondary,
            ),
          );
        } else if (state is FamilySharedBudgetUpdateError) {
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
          iconTheme: IconThemeData(color: colors.onSurface),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_budget.name, style: AppTypography.headlineSm),
              if (isArchived) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    s.budgetArchivedBadge,
                    style: AppTypography.labelSm.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (isArchived)
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
                        Icon(Icons.edit_outlined, size: 20,
                            color: colors.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.md),
                        Text(s.edit, style: AppTypography.bodyMd),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _BudgetMenuAction.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: colors.error),
                        const SizedBox(width: AppSpacing.md),
                        Text(s.delete,
                            style: AppTypography.bodyMd.copyWith(color: colors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
          bottom: isArchived
              ? null
              : TabBar(
                  controller: _tabController,
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.onSurfaceVariant,
                  indicatorColor: colors.primary,
                  labelStyle: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: AppTypography.bodySm,
                  tabs: [
                    Tab(text: s.budgetTabCurrentPeriod),
                    Tab(text: s.budgetTabHistory),
                  ],
                ),
        ),
        body: isArchived
            ? _CurrentPeriodView(
                groupId: widget.groupId,
                budget: _budget,
                future: _future,
                onRefresh: () => setState(() => _future = _load()),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _CurrentPeriodView(
                    groupId: widget.groupId,
                    budget: _budget,
                    future: _future,
                    onRefresh: () => setState(() => _future = _load()),
                  ),
                  _HistoryView(groupId: widget.groupId, budgetId: _budget.id),
                ],
              ),
      ),
    );
  }
}

class _CurrentPeriodView extends StatelessWidget {
  const _CurrentPeriodView({
    required this.groupId,
    required this.budget,
    required this.future,
    required this.onRefresh,
  });

  final String groupId;
  final SharedBudgetModel budget;
  final Future<SharedBudgetDetailModel> future;
  final VoidCallback onRefresh;

  List<Widget> _buildGrouped(
    List<SharedBudgetExpenseModel> expenses,
    SharedBudgetModel budget,
    BuildContext context,
  ) {
    final colors = context.colors;
    final sorted = [...expenses]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final groups = <String, List<SharedBudgetExpenseModel>>{};
    for (final e in sorted) {
      final key = DateFormatter.formatGroupHeader(e.transactionDate, context);
      groups.putIfAbsent(key, () => []).add(e);
    }
    final widgets = <Widget>[];
    groups.forEach((header, items) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
          child: Text(
            header,
            style: AppTypography.labelSm.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      );
      for (final e in items) {
        widgets.add(_ExpenseTile(expense: e, budget: budget));
      }
    });
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surfaceContainerHigh,
      onRefresh: () async {
        onRefresh();
        await future;
      },
      child: FutureBuilder<SharedBudgetDetailModel>(
        future: future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final detail = snapshot.data;
          final currentBudget = detail?.budget ?? budget;
          final expenses = detail?.expenses ?? const <SharedBudgetExpenseModel>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              0,
            ),
            children: [
              _SummaryCard(budget: currentBudget),
              const SizedBox(height: AppSpacing.xl),
              if (expenses.isNotEmpty) ...[
                _DailyExpenseChart(expenses: expenses),
                const SizedBox(height: AppSpacing.xl),
                _MemberBreakdown(expenses: expenses),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text(s.sharedBudgetExpensesTitle, style: AppTypography.labelSm),
              const SizedBox(height: AppSpacing.md),
              if (loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  ),
                )
              else if (expenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(
                    child: Text(
                      s.sharedBudgetNoExpenses,
                      style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ..._buildGrouped(expenses, currentBudget, context),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView({required this.groupId, required this.budgetId});

  final String groupId;
  final String budgetId;

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  late Future<List<BudgetHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<FamilyRepository>().getSharedBudgetHistory(
      groupId: widget.groupId,
      budgetId: widget.budgetId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
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
                    style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            Text(s.budgetHistoryChartTitle, style: AppTypography.labelSm),
            const SizedBox(height: AppSpacing.md),
            _HistoryBarChart(entries: entries),
            const SizedBox(height: AppSpacing.xl),
            for (final e in entries) ...[
              _HistoryEntryCard(entry: e),
              const SizedBox(height: AppSpacing.md),
            ],
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
    final colors = context.colors;
    final recent = entries.take(6).toList().reversed.toList();
    final maxVal = recent
        .fold<double>(0, (m, e) => e.amount > m ? e.amount : m)
        .clamp(1.0, double.infinity);

    final tooltipBg = colors.surfaceContainerHighest;
    final onSurfaceColor = colors.onSurface;
    final labelColor = colors.onSurfaceVariant;
    final primaryFaded = colors.primary.withValues(alpha: 0.4);

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxVal,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => tooltipBg,
              getTooltipItem: (group, _, rod, i) {
                return BarTooltipItem(
                  CurrencyFormatter.format(rod.toY),
                  AppTypography.labelSm.copyWith(color: onSurfaceColor),
                );
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= recent.length) {
                    return const SizedBox.shrink();
                  }
                  final e = recent[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormatter.formatMini(e.startDate, context),
                      style: AppTypography.labelSm.copyWith(
                        color: labelColor,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < recent.length; i++)
              BarChartGroupData(
                x: i,
                groupVertically: false,
                barRods: [
                  BarChartRodData(
                    toY: recent[i].amount,
                    width: 8,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    color: primaryFaded,
                  ),
                  BarChartRodData(
                    toY: recent[i].spent,
                    width: 8,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    color: recent[i].percentage >= 100
                        ? colors.expense
                        : colors.income,
                  ),
                ],
              ),
          ],
        ),
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
    final pct = (entry.percentage / 100).clamp(0.0, 1.0);
    final color = entry.percentage >= 100
        ? colors.expense
        : entry.percentage >= 90
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
                    Text(entry.name, style: AppTypography.titleSm),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormatter.formatMini(entry.startDate, context)} — ${DateFormatter.formatMini(entry.endDate, context)}',
                      style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '%${entry.percentage.toStringAsFixed(0)}',
                  style: AppTypography.labelSm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                CurrencyFormatter.format(entry.spent),
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                ' / ${CurrencyFormatter.format(entry.amount)}',
                style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
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

  final SharedBudgetModel budget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    final pct = budget.spentPercent;
    final color = pct >= 0.9
        ? colors.expense
        : pct >= 0.7
        ? colors.expense.withValues(alpha: 0.7)
        : colors.primary;

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
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shopping_bag_outlined, color: colors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.categoryName,
                      style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
                    ),
                    Text(budget.period, style: AppTypography.titleSm),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '%${(pct * 100).toStringAsFixed(0)}',
                  style: AppTypography.labelSm.copyWith(
                    color: color,
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
            style: AppTypography.displayLg.copyWith(fontSize: 36, color: color),
          ),
          Text(
            '/ ${CurrencyFormatter.format(budget.amount)}',
            style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: s.budgetStatRemaining,
                  value: CurrencyFormatter.format(
                    (budget.amount - budget.spent).clamp(0, double.infinity),
                  ),
                  color: colors.onSurface,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: s.budgetStatStart,
                  value: DateFormatter.formatMini(
                    DateTime.tryParse(budget.startDate) ?? budget.endDate,
                    context,
                  ),
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
          style: AppTypography.labelSm.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMd.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _DailyExpenseChart extends StatelessWidget {
  const _DailyExpenseChart({required this.expenses});

  final List<SharedBudgetExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    const days = 14;
    final buckets = List<double>.filled(days, 0);
    final startDay = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: days - 1));

    for (final e in expenses) {
      final local = e.transactionDate.toLocal();
      final d = DateTime(local.year, local.month, local.day);
      final idx = d.difference(startDay).inDays;
      if (idx >= 0 && idx < days) {
        buckets[idx] += e.amount;
      }
    }

    final maxVal = buckets
        .fold<double>(0, (m, v) => v > m ? v : m)
        .clamp(1.0, double.infinity);

    final tooltipBg = colors.surfaceContainerHighest;
    final onSurfaceColor = colors.onSurface;
    final labelColor = colors.onSurfaceVariant;
    final primaryColor = colors.primary;
    final emptyBarColor = colors.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.of(context).budgetDailyChartTitle, style: AppTypography.labelSm),
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
                    getTooltipColor: (_) => tooltipBg,
                    getTooltipItem: (group, _, rod, idx) {
                      final date = startDay.add(Duration(days: group.x));
                      return BarTooltipItem(
                        '${DateFormatter.formatMini(date, context)}\n'
                        '${CurrencyFormatter.format(rod.toY)}',
                        AppTypography.labelSm.copyWith(color: onSurfaceColor),
                      );
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                              color: labelColor,
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
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          color: buckets[i] > 0 ? primaryColor : emptyBarColor,
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

class _MemberBreakdown extends StatelessWidget {
  const _MemberBreakdown({required this.expenses});

  final List<SharedBudgetExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final byUser = <String, ({String name, double total})>{};
    for (final e in expenses) {
      final entry = byUser[e.userId];
      byUser[e.userId] = (
        name: e.userName,
        total: (entry?.total ?? 0) + e.amount,
      );
    }
    final entries = byUser.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final grand = entries.fold<double>(0, (s, e) => s + e.total);
    if (grand <= 0) return const SizedBox.shrink();

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
            AppStrings.of(context).sharedBudgetMembersTotal.toUpperCase(),
            style: AppTypography.labelSm,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final e in entries) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                    style: AppTypography.labelSm.copyWith(color: colors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name, style: AppTypography.bodyMd),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (e.total / grand).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: colors.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  CurrencyFormatter.format(e.total),
                  style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.budget});

  final SharedBudgetExpenseModel expense;
  final SharedBudgetModel budget;

  Color _hexColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = _hexColor(budget.categoryColor, colors.expense);
    final icon = IconMapper.fromString(budget.categoryIcon ?? 'shopping_cart');

    return Padding(
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
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description ??
                      expense.note ??
                      AppStrings.of(context).transactionFallback,
                  style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    expense.userName,
                    if (expense.accountName != null && expense.accountName!.isNotEmpty)
                      expense.accountName!,
                  ].join('  •  '),
                  style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${CurrencyFormatter.format(expense.amount)}',
                style: AppTypography.bodyMd.copyWith(
                  color: colors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.formatTime(expense.transactionDate),
                style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
