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
import '../../../core/utils/category_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../bloc/budgets_bloc.dart';
import '../bloc/budgets_event.dart';
import '../bloc/budgets_state.dart';
import '../widgets/edit_budget_sheet.dart';

class BudgetDetailPage extends StatefulWidget {
  const BudgetDetailPage({super.key, required this.budget});

  final BudgetModel budget;

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends State<BudgetDetailPage> {
  late BudgetModel _budget;
  late Future<List<TransactionModel>> _txFuture;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _txFuture = _loadTransactions();
  }

  Future<List<TransactionModel>> _loadTransactions() async {
    if (_budget.category == null) return [];
    final repo = getIt<TransactionRepository>();
    final end = _budget.endDate ?? DateTime.now();
    final result = await repo.getTransactions(
      page: 1,
      limit: 200,
      type: 'EXPENSE',
      categoryId: _budget.category!.id,
      startDate: _budget.startDate.toIso8601String(),
      endDate: end.toIso8601String(),
    );
    return result.data;
  }

  void _refreshFromBloc(BudgetModel updated) {
    setState(() {
      _budget = updated;
      _txFuture = _loadTransactions();
    });
  }

  Future<void> _openEdit() async {
    final bloc = context.read<BudgetsBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EditBudgetSheet(budget: _budget),
      ),
    );
  }

  Future<void> _addTransaction() async {
    if (_budget.category == null) return;
    await context.push(
      RouteNames.addTransaction,
      extra: {
        'type': 'EXPENSE',
        'categoryId': _budget.category!.id,
      },
    );
    if (!mounted) return;
    context.read<BudgetsBloc>().add(const BudgetsRefreshRequested());
    setState(() => _txFuture = _loadTransactions());
  }

  Future<void> _confirmDelete() async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(s.deleteBudgetTitle, style: AppTypography.titleSm),
        content: Text(
          s.deleteBudgetContent(_budget.name),
          style: AppTypography.bodyMd
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              s.cancel,
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.delete,
              style: AppTypography.bodyMd.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<BudgetsBloc>().add(BudgetDeleteRequested(_budget.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.of(context).budgetDeletedSuccess),
        backgroundColor: AppColors.secondary,
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BudgetsBloc, BudgetsState>(
      listenWhen: (_, curr) => curr is BudgetsLoaded,
      listener: (context, state) {
        if (state is BudgetsLoaded) {
          final matches =
              state.budgets.where((b) => b.id == _budget.id).toList();
          if (matches.isNotEmpty) {
            _refreshFromBloc(matches.first);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        floatingActionButton: _budget.category != null
            ? FloatingActionButton.extended(
                onPressed: _addTransaction,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                icon: const Icon(Icons.add_rounded),
                label: Text(AppStrings.of(context).budgetAddTransaction),
              )
            : null,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(_budget.name, style: AppTypography.headlineSm),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.onSurfaceVariant),
              onPressed: _openEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceContainerHigh,
          onRefresh: () async {
            context.read<BudgetsBloc>().add(const BudgetsRefreshRequested());
            setState(() => _txFuture = _loadTransactions());
            await _txFuture;
          },
          child: FutureBuilder<List<TransactionModel>>(
            future: _txFuture,
            builder: (context, snapshot) {
              final transactions = snapshot.data ?? const <TransactionModel>[];
              final loading =
                  snapshot.connectionState == ConnectionState.waiting;
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                children: [
                  _SummaryCard(budget: _budget),
                  const SizedBox(height: AppSpacing.xl),
                  if (transactions.isNotEmpty) ...[
                    _DailySpendChart(
                      transactions: transactions,
                      statusColor: _budget.statusColor,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  Text(
                    AppStrings.of(context).budgetTransactionsTitle,
                    style: AppTypography.labelSm,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxl),
                      child: Center(
                        child: Text(
                          AppStrings.of(context).budgetNoTransactions,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._buildGroupedTransactions(transactions),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTransactions(List<TransactionModel> transactions) {
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    final groups = <String, List<TransactionModel>>{};
    for (final t in sorted) {
      final key = DateFormatter.formatGroupHeader(t.date);
      groups.putIfAbsent(key, () => []).add(t);
    }
    final widgets = <Widget>[];
    groups.forEach((header, items) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(
            top: AppSpacing.md, bottom: AppSpacing.sm),
        child: Text(
          header,
          style: AppTypography.labelSm
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
      ));
      for (final t in items) {
        widgets.add(_BudgetTransactionTile(transaction: t));
      }
    });
    return widgets;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.budget});

  final BudgetModel budget;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final progress = (budget.percentage.clamp(0, 100) / 100).toDouble();
    final category = budget.category;

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
                  color: category?.cardColor.withValues(alpha: 0.15) ??
                      AppColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconMapper.fromString(category?.icon ?? 'account_balance'),
                  color: category?.cardColor ?? AppColors.primary,
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
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    Text(budget.periodLabel, style: AppTypography.titleSm),
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
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '%${budget.percentage} · ${budget.statusLabel}',
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
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHighest,
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
                      budget.remaining < 0 ? 0 : budget.remaining),
                  color: AppColors.onSurface,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: s.budgetStatStart,
                  value: DateFormatter.formatMini(budget.startDate),
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: s.budgetStatEnd,
                  value: budget.endDate != null
                      ? DateFormatter.formatMini(budget.endDate!)
                      : '—',
                  color: AppColors.onSurfaceVariant,
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
          style: AppTypography.labelSm
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMd
              .copyWith(color: color, fontWeight: FontWeight.w600),
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
    final now = DateTime.now();
    const days = 14;
    final buckets = List<double>.filled(days, 0);
    final startDay = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: days - 1));

    for (final t in transactions) {
      final local = t.date.toLocal();
      final d = DateTime(local.year, local.month, local.day);
      final idx = d.difference(startDay).inDays;
      if (idx >= 0 && idx < days) {
        buckets[idx] += t.amount;
      }
    }

    final maxVal =
        buckets.fold<double>(0, (m, v) => v > m ? v : m).clamp(1.0, double.infinity);

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
                    getTooltipColor: (_) => AppColors.surfaceContainerHighest,
                    getTooltipItem: (group, _, rod, idx) {
                      final date =
                          startDay.add(Duration(days: group.x));
                      return BarTooltipItem(
                        '${DateFormatter.formatMini(date)}\n'
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
                        if (idx % 3 != 0 || idx < 0 || idx >= days) {
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
                              ? statusColor
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

class _BudgetTransactionTile extends StatelessWidget {
  const _BudgetTransactionTile({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final iconData = IconMapper.fromString(
      transaction.category?.icon ?? 'shopping_cart',
    );
    final color = transaction.category?.color != null
        ? _hexColor(transaction.category!.color!)
        : AppColors.tertiary;

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
                  style: AppTypography.bodyMd
                      .copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.account?.name ?? ''}  •  '
                  '${DateFormatter.formatTime(transaction.date)}',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '-${CurrencyFormatter.format(transaction.amount)}',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.onSurfaceVariant;
    }
  }
}
