import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/app_strings.dart';
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

class SharedBudgetDetailPage extends StatefulWidget {
  const SharedBudgetDetailPage({
    super.key,
    required this.groupId,
    required this.budget,
  });

  final String groupId;
  final SharedBudgetModel budget;

  @override
  State<SharedBudgetDetailPage> createState() =>
      _SharedBudgetDetailPageState();
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
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _confirmDelete() async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title:
            Text(s.deleteSharedBudgetTitle, style: AppTypography.titleSm),
        content: Text(
          s.deleteBudgetContent(_budget.name),
          style: AppTypography.bodyMd
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel,
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<FamilyBloc>().add(
            FamilySharedBudgetDeleteRequested(
              groupId: widget.groupId,
              budgetId: _budget.id,
            ),
          );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.of(context).sharedBudgetDeletedSuccess),
        backgroundColor: AppColors.secondary,
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isArchived = !_budget.isActive;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_budget.name, style: AppTypography.headlineSm),
            if (isArchived) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  s.budgetArchivedBadge,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!isArchived)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _confirmDelete,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          labelStyle: AppTypography.bodySm
              .copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.bodySm,
          tabs: [
            Tab(text: s.budgetTabCurrentPeriod),
            Tab(text: s.budgetTabHistory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CurrentPeriodView(
            groupId: widget.groupId,
            budget: _budget,
            future: _future,
            onAddEntry: _openAddEntrySheet,
            onRefresh: () {
              setState(() => _future = _load());
            },
          ),
          _HistoryView(
            groupId: widget.groupId,
            budgetId: _budget.id,
          ),
        ],
      ),
    );
  }
}

class _CurrentPeriodView extends StatelessWidget {
  const _CurrentPeriodView({
    required this.groupId,
    required this.budget,
    required this.future,
    required this.onAddEntry,
    required this.onRefresh,
  });

  final String groupId;
  final SharedBudgetModel budget;
  final Future<SharedBudgetDetailModel> future;
  final VoidCallback onAddEntry;
  final VoidCallback onRefresh;

  List<Widget> _buildGrouped(
      List<SharedBudgetExpenseModel> expenses,
      SharedBudgetModel budget,
      BuildContext context) {
    final sorted = [...expenses]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final groups = <String, List<SharedBudgetExpenseModel>>{};
    for (final e in sorted) {
      final key = DateFormatter.formatGroupHeader(e.transactionDate, context);
      groups.putIfAbsent(key, () => []).add(e);
    }
    final widgets = <Widget>[];
    groups.forEach((header, items) {
      widgets.add(Padding(
        padding:
            const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
        child: Text(
          header,
          style: AppTypography.labelSm
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
      ));
      for (final e in items) {
        widgets.add(_ExpenseTile(expense: e, budget: budget));
      }
    });
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerHigh,
      onRefresh: () async {
        onRefresh();
        await future;
      },
      child: FutureBuilder<SharedBudgetDetailModel>(
        future: future,
        builder: (context, snapshot) {
          final loading =
              snapshot.connectionState == ConnectionState.waiting;
          final detail = snapshot.data;
          final currentBudget = detail?.budget ?? budget;
          final expenses =
              detail?.expenses ?? const <SharedBudgetExpenseModel>[];

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
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
              if (currentBudget.isActive)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.sharedBudgetExpensesTitle,
                        style: AppTypography.labelSm,
                      ),
                    ),
                    _AddTransactionInlineAction(onTap: onAddEntry),
                  ],
                )
              else
                Text(s.sharedBudgetExpensesTitle,
                    style: AppTypography.labelSm),
              const SizedBox(height: AppSpacing.md),
              if (loading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (expenses.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(
                    child: Text(
                      s.sharedBudgetNoExpenses,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
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
    final s = AppStrings.of(context);
    return FutureBuilder<List<BudgetHistoryEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primary));
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Text(
              s.budgetHistoryEmpty,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
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
    final recent = entries.take(6).toList().reversed.toList();
    final maxVal = recent
        .fold<double>(
            0, (m, e) => e.amount > m ? e.amount : m)
        .clamp(1.0, double.infinity);

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxVal,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceContainerHighest,
              getTooltipItem: (group, _, rod, i) {
                return BarTooltipItem(
                  CurrencyFormatter.format(rod.toY),
                  AppTypography.labelSm
                      .copyWith(color: AppColors.onSurface),
                );
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
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
                        color: AppColors.onSurfaceVariant,
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
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  BarChartRodData(
                    toY: recent[i].spent,
                    width: 8,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    color: recent[i].percentage >= 100
                        ? AppColors.tertiary
                        : AppColors.secondary,
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
    final pct = (entry.percentage / 100).clamp(0.0, 1.0);
    final color = entry.percentage >= 100
        ? AppColors.tertiary
        : entry.percentage >= 90
            ? AppColors.tertiary.withValues(alpha: 0.7)
            : AppColors.secondary;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name, style: AppTypography.titleSm),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormatter.formatMini(entry.startDate, context)} — ${DateFormatter.formatMini(entry.endDate, context)}',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
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
                style: AppTypography.bodyMd
                    .copyWith(fontWeight: FontWeight.w600, color: color),
              ),
              Text(
                ' / ${CurrencyFormatter.format(entry.amount)}',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTransactionInlineAction extends StatelessWidget {
  const _AddTransactionInlineAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.of(context).budgetAddTransaction,
              style:
                  AppTypography.labelSm.copyWith(color: AppColors.primary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.budget});

  final SharedBudgetModel budget;

  @override
  Widget build(BuildContext context) {
    final pct = budget.spentPercent;
    final color = pct >= 0.9
        ? AppColors.tertiary
        : pct >= 0.7
            ? AppColors.tertiary.withValues(alpha: 0.7)
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.categoryName,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(budget.period, style: AppTypography.titleSm),
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
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
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
            style: AppTypography.displayLg.copyWith(
              fontSize: 36,
              color: color,
            ),
          ),
          Text(
            '/ ${CurrencyFormatter.format(budget.amount)}',
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyExpenseChart extends StatelessWidget {
  const _DailyExpenseChart({required this.expenses});

  final List<SharedBudgetExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
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
                    getTooltipColor: (_) =>
                        AppColors.surfaceContainerHighest,
                    getTooltipItem: (group, _, rod, idx) {
                      final date = startDay.add(Duration(days: group.x));
                      return BarTooltipItem(
                        '${DateFormatter.formatMini(date, context)}\n'
                        '${CurrencyFormatter.format(rod.toY)}',
                        AppTypography.labelSm
                            .copyWith(color: AppColors.onSurface),
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
                        if (idx % 3 != 0 ||
                            idx < 0 ||
                            idx >= days) {
                          return const SizedBox.shrink();
                        }
                        final date =
                            startDay.add(Duration(days: idx));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${date.day}',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
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
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          color: buckets[i] > 0
                              ? AppColors.primary
                              : AppColors.surfaceContainerHighest,
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
        color: AppColors.surfaceContainerHigh,
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.primary),
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
                          backgroundColor:
                              AppColors.surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  CurrencyFormatter.format(e.total),
                  style: AppTypography.bodyMd
                      .copyWith(fontWeight: FontWeight.w600),
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

  Color _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.tertiary;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(budget.categoryColor);
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
                  style: AppTypography.bodyMd
                      .copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${expense.userName}  •  '
                  '${DateFormatter.formatTime(expense.transactionDate)}',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '-${CurrencyFormatter.format(expense.amount)}',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
