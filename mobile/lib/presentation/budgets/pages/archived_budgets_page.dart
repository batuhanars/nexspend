import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/family_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/family_repository.dart';
import '../../../navigation/route_names.dart';

class ArchivedBudgetsPage extends StatefulWidget {
  const ArchivedBudgetsPage({super.key});

  @override
  State<ArchivedBudgetsPage> createState() => _ArchivedBudgetsPageState();
}

class _ArchivedBudgetsPageState extends State<ArchivedBudgetsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<BudgetModel>> _personalFuture;
  late Future<
    List<({String groupName, String groupId, SharedBudgetModel budget})>
  >
  _sharedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _personalFuture = _loadPersonal();
    _sharedFuture = _loadShared();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<BudgetModel>> _loadPersonal() async {
    final all = await getIt<BudgetRepository>().getAll(includeArchived: true);
    return all.where((b) => !b.isActive).toList();
  }

  Future<List<({String groupName, String groupId, SharedBudgetModel budget})>>
  _loadShared() async {
    final groups = await getIt<FamilyRepository>().getGroups();
    final result =
        <({String groupName, String groupId, SharedBudgetModel budget})>[];
    await Future.wait(
      groups.map((g) async {
        try {
          final budgets = await getIt<FamilyRepository>().getSharedBudgets(
            g.id,
            includeArchived: true,
          );
          for (final b in budgets.where((b) => !b.isActive)) {
            result.add((groupName: g.name, groupId: g.id, budget: b));
          }
        } catch (_) {}
      }),
    );
    return result;
  }

  Future<void> _refreshPersonal() async {
    setState(() => _personalFuture = _loadPersonal());
    await _personalFuture;
  }

  Future<void> _refreshShared() async {
    setState(() => _sharedFuture = _loadShared());
    await _sharedFuture;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colors.onSurface),
        title: Text(s.archivedBudgetsTitle, style: AppTypography.titleSm),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          indicatorColor: colors.primary,
          labelStyle: AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTypography.bodySm,
          tabs: [
            Tab(text: s.archivedBudgetsTabPersonal),
            Tab(text: s.archivedBudgetsTabShared),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PersonalArchivedTab(
            future: _personalFuture,
            onRefresh: _refreshPersonal,
          ),
          _SharedArchivedTab(future: _sharedFuture, onRefresh: _refreshShared),
        ],
      ),
    );
  }
}

class _PersonalArchivedTab extends StatelessWidget {
  const _PersonalArchivedTab({required this.future, required this.onRefresh});
  final Future<List<BudgetModel>> future;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surfaceContainerHigh,
      onRefresh: onRefresh,
      child: FutureBuilder<List<BudgetModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }
          final budgets = snapshot.data ?? [];
          if (budgets.isEmpty) {
            return _RefreshableEmpty(message: s.archivedBudgetsEmpty);
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: budgets.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final b = budgets[i];
              return _ArchivedBudgetCard(
                name: b.name,
                categoryName: b.category?.name ?? '',
                startDate: b.startDate,
                endDate: b.endDate,
                spent: b.spent,
                amount: b.amount,
                percentage: b.percentage,
                onTap: () async {
                  await context.push(
                    RouteNames.budgetDetail(b.id),
                    extra: {'budget': b},
                  );
                  if (context.mounted) await onRefresh();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SharedArchivedTab extends StatelessWidget {
  const _SharedArchivedTab({required this.future, required this.onRefresh});
  final Future<
    List<({String groupName, String groupId, SharedBudgetModel budget})>
  >
  future;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surfaceContainerHigh,
      onRefresh: onRefresh,
      child:
          FutureBuilder<
            List<({String groupName, String groupId, SharedBudgetModel budget})>
          >(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: colors.primary),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return _RefreshableEmpty(message: s.archivedBudgetsEmpty);
              }
              final byGroup =
                  <
                    String,
                    List<
                      ({
                        String groupName,
                        String groupId,
                        SharedBudgetModel budget,
                      })
                    >
                  >{};
              for (final item in items) {
                byGroup.putIfAbsent(item.groupName, () => []).add(item);
              }
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  for (final entry in byGroup.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: AppTypography.labelSm.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    for (final item in entry.value) ...[
                      _ArchivedBudgetCard(
                        name: item.budget.name,
                        categoryName: item.budget.categoryName,
                        startDate: DateTime.parse(item.budget.startDate),
                        endDate: item.budget.endDate,
                        spent: item.budget.spent,
                        amount: item.budget.amount,
                        percentage: (item.budget.spentPercent * 100).round(),
                        onTap: () async {
                          await context.push(
                            RouteNames.sharedBudgetDetail(
                              item.groupId,
                              item.budget.id,
                            ),
                            extra: {'budget': item.budget},
                          );
                          if (context.mounted) await onRefresh();
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ],
              );
            },
          ),
    );
  }
}

class _ArchivedBudgetCard extends StatelessWidget {
  const _ArchivedBudgetCard({
    required this.name,
    required this.categoryName,
    required this.startDate,
    required this.endDate,
    required this.spent,
    required this.amount,
    required this.percentage,
    required this.onTap,
  });

  final String name;
  final String categoryName;
  final DateTime startDate;
  final DateTime endDate;
  final double spent;
  final double amount;
  final int percentage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = (percentage / 100).clamp(0.0, 1.0);
    final color = percentage >= 100
        ? colors.expense
        : percentage >= 90
            ? colors.expense.withValues(alpha: 0.7)
            : colors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                      Text(name, style: AppTypography.titleSm),
                      const SizedBox(height: 2),
                      Text(
                        categoryName,
                        style: AppTypography.bodySm.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
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
                    color: colors.onSurfaceVariant.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '%$percentage',
                    style: AppTypography.labelSm.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${DateFormatter.formatMini(startDate, context)} — ${DateFormatter.formatMini(endDate, context)}',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  CurrencyFormatter.format(spent),
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  ' / ${CurrencyFormatter.format(amount)}',
                  style: AppTypography.bodySm.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshableEmpty extends StatelessWidget {
  const _RefreshableEmpty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: _EmptyState(message: message),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: colors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyMd.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
