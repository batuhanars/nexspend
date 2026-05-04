import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/account_analytics_model.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../navigation/route_names.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_detail_bloc.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({
    super.key,
    required this.accountId,
    this.initialAccount,
  });

  final String accountId;
  final AccountModel? initialAccount;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late AccountModel? _displayAccount = widget.initialAccount;

  @override
  void initState() {
    super.initState();
    context.read<AccountDetailBloc>().add(
          AccountDetailLoadRequested(accountId: widget.accountId),
        );
  }

  Future<void> _addTransaction() async {
    final bloc = context.read<AccountDetailBloc>();
    await context.push(RouteNames.addTransaction);
    if (mounted) {
      bloc.add(AccountDetailRefreshRequested(accountId: widget.accountId));
    }
  }

  Future<void> _openEdit(AccountModel account) async {
    final updated = await context.push<AccountModel>(
      RouteNames.editAccount(account.id),
      extra: account,
    );
    if (updated != null && mounted) {
      setState(() => _displayAccount = updated);
      context.read<AccountDetailBloc>().add(
            AccountDetailAccountUpdated(updated),
          );
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String content,
    required String confirm,
    bool isDanger = false,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: Text(title, style: AppTypography.titleSm),
          content: Text(
            content,
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
              child: Text(
                confirm,
                style: TextStyle(
                  color: isDanger ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AccountBloc, AccountState>(
          listener: (context, state) {
            if (state is AccountDeleted) {
              context.pop();
            } else if (state is AccountActionDone) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              context.read<AccountDetailBloc>().add(
                    AccountDetailRefreshRequested(
                        accountId: widget.accountId),
                  );
            } else if (state is AccountError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AccountDetailBloc, AccountDetailState>(
        builder: (context, state) {
          final account = state is AccountDetailLoaded
              ? state.account
              : _displayAccount;

          return Scaffold(
            body: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
              onRefresh: () async {
                context.read<AccountDetailBloc>().add(
                      AccountDetailRefreshRequested(
                          accountId: widget.accountId),
                    );
                await context
                    .read<AccountDetailBloc>()
                    .stream
                    .firstWhere((s) =>
                        s is AccountDetailLoaded ||
                        s is AccountDetailError);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(context, account),
                  SliverToBoxAdapter(
                    child: _buildContent(context, state, account),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AccountModel? account) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.pop(),
      ),
      title: Text(
        account?.name ?? 'Hesap Detayı',
        style: AppTypography.headlineSm,
      ),
      actions: [
        if (account != null)
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: _addTransaction,
          ),
        if (account != null)
          BlocBuilder<AccountBloc, AccountState>(
            builder: (context, state) {
              final isLoading = state is AccountSubmitting;
              if (isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }
              return PopupMenuButton<String>(
                color: AppColors.surfaceContainerHigh,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.onSurface,
                ),
                onSelected: (value) =>
                    _handleMenuAction(value, account),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 18,
                            color: AppColors.onSurfaceVariant),
                        SizedBox(width: AppSpacing.md),
                        Text('Düzenle'),
                      ],
                    ),
                  ),
                  if (!account.isDefault)
                    const PopupMenuItem(
                      value: 'set_default',
                      child: Row(
                        children: [
                          Icon(Icons.star_outline_rounded,
                              size: 18,
                              color: AppColors.onSurfaceVariant),
                          SizedBox(width: AppSpacing.md),
                          Text('Varsayılan Yap'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined,
                            size: 18,
                            color: AppColors.onSurfaceVariant),
                        SizedBox(width: AppSpacing.md),
                        Text('Arşivle'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Hesabı Sil',
                          style:
                              TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  void _handleMenuAction(String action, AccountModel account) async {
    switch (action) {
      case 'edit':
        _openEdit(account);
      case 'set_default':
        context.read<AccountBloc>().add(
              AccountSetDefaultRequested(account.id),
            );
      case 'archive':
        final confirm = await _confirmAction(
          title: 'Hesabı Arşivle',
          content:
              'Hesap gizlenecek, işlem geçmişi korunacak. Arşivlenen hesapları ayarlardan geri getirebilirsiniz.',
          confirm: 'Arşivle',
        );
        if (confirm == true && mounted) {
          context.read<AccountBloc>().add(
                AccountArchiveRequested(account.id),
              );
        }
      case 'delete':
        final confirm = await _confirmAction(
          title: 'Hesabı Sil',
          content:
              'Bu hesap kalıcı olarak silinecek. İşlem geçmişi olan hesaplar silinemez.',
          confirm: 'Sil',
          isDanger: true,
        );
        if (confirm == true && mounted) {
          context.read<AccountBloc>().add(
                AccountDeleteRequested(account.id),
              );
        }
    }
  }

  Widget _buildContent(
    BuildContext context,
    AccountDetailState state,
    AccountModel? account,
  ) {
    if (state is AccountDetailLoading || state is AccountDetailInitial) {
      return _DetailShimmer(account: _displayAccount);
    }
    if (state is AccountDetailError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<AccountDetailBloc>().add(
              AccountDetailLoadRequested(accountId: widget.accountId),
            ),
      );
    }
    if (state is AccountDetailLoaded) {
      return _DetailContent(
        account: state.account,
        analytics: state.analytics,
        transactions: state.transactions,
        onAddTransaction: _addTransaction,
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Yüklenmiş detay içeriği ────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.account,
    required this.analytics,
    required this.transactions,
    required this.onAddTransaction,
  });

  final AccountModel account;
  final AccountAnalyticsModel analytics;
  final List<TransactionModel> transactions;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _AccountHeaderCard(account: account),
        const SizedBox(height: AppSpacing.xl),
        _ThisMonthSection(analytics: analytics),
        if (analytics.months.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _MonthlyChartSection(months: analytics.months),
        ],
        if (analytics.topCategories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _TopCategoriesSection(categories: analytics.topCategories),
        ],
        const SizedBox(height: AppSpacing.xl),
        _TransactionsSection(
          transactions: transactions,
          onAddTransaction: onAddTransaction,
        ),
      ],
    );
  }
}

// ── Hesap başlık kartı ─────────────────────────────────────────────────────

class _AccountHeaderCard extends StatelessWidget {
  const _AccountHeaderCard({required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final isCC = account.type == AccountType.CREDIT_CARD;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: account.cardColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: account.cardColor.withValues(alpha: 0.2),
          width: 1,
        ),
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
                  color: account.cardColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(account.iconData,
                    color: account.cardColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: AppTypography.titleSm),
                    Text(
                      account.type.label,
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (account.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Varsayılan',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isCC ? 'KULLANILAN' : 'BAKİYE',
            style: AppTypography.labelSm
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.format(
              isCC ? account.creditUsed : account.balance,
            ),
            style: AppTypography.displayMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isCC && account.creditLimit != null) ...[
            const SizedBox(height: AppSpacing.md),
            _CreditBar(account: account),
          ],
        ],
      ),
    );
  }
}

class _CreditBar extends StatelessWidget {
  const _CreditBar({required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final percent = account.creditUsagePercent;
    final barColor = percent > 0.8
        ? AppColors.error
        : percent > 0.6
            ? AppColors.warning
            : AppColors.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kullanılan / Limit',
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              style: AppTypography.labelSm.copyWith(color: barColor),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor:
                AppColors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              CurrencyFormatter.format(account.creditUsed),
              style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant),
            ),
            Text(
              CurrencyFormatter.format(account.creditLimit!),
              style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Bu ay gelir/gider ──────────────────────────────────────────────────────

class _ThisMonthSection extends StatelessWidget {
  const _ThisMonthSection({required this.analytics});
  final AccountAnalyticsModel analytics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bu Ay', style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _FlowChip(
                  label: 'Gelir',
                  amount: analytics.currentMonthIncome,
                  color: AppColors.secondary,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _FlowChip(
                  label: 'Gider',
                  amount: analytics.currentMonthExpense,
                  color: AppColors.tertiary,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowChip extends StatelessWidget {
  const _FlowChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
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
              Text(label,
                  style:
                      AppTypography.labelSm.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: AppTypography.titleSm,
          ),
        ],
      ),
    );
  }
}

// ── Aylık bar chart ────────────────────────────────────────────────────────

class _MonthlyChartSection extends StatelessWidget {
  const _MonthlyChartSection({required this.months});
  final List<MonthlyFlowModel> months;

  static const _monthAbbr = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  String _abbr(String monthStr) {
    final m = int.tryParse(monthStr.split('-').last) ?? 1;
    return _monthAbbr[(m - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = months.fold<double>(
      1,
      (m, e) => max(m, max(e.income, e.expense)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Son 6 Ay', style: AppTypography.titleSm),
              const Spacer(),
              _LegendDot(color: AppColors.secondary, label: 'Gelir'),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(color: AppColors.tertiary, label: 'Gider'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.3,
                barGroups: months.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        fromY: 0,
                        toY: e.value.income,
                        color: AppColors.secondary,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        fromY: 0,
                        toY: e.value.expense,
                        color: AppColors.tertiary,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
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
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _abbr(months[i].month),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label =
                          rodIndex == 0 ? 'Gelir' : 'Gider';
                      return BarTooltipItem(
                        '$label\n${CurrencyFormatter.formatCompact(rod.toY)}',
                        AppTypography.labelSm.copyWith(
                          color: rod.color,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSm
              .copyWith(color: AppColors.onSurfaceVariant, fontSize: 10),
        ),
      ],
    );
  }
}

// ── En çok harcanan kategoriler ────────────────────────────────────────────

class _TopCategoriesSection extends StatelessWidget {
  const _TopCategoriesSection({required this.categories});
  final List<CategoryBreakdownModel> categories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bu Ay En Çok Harcanan', style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.md),
          ...categories.map((cat) => _CategoryRow(category: cat)),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});
  final CategoryBreakdownModel category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: category.cardColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              category.iconData,
              size: 18,
              color: category.cardColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              category.name,
              style: AppTypography.bodyMd,
            ),
          ),
          Text(
            CurrencyFormatter.format(category.amount),
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

// ── İşlem geçmişi ──────────────────────────────────────────────────────────

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({
    required this.transactions,
    required this.onAddTransaction,
  });
  final List<TransactionModel> transactions;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Text('İşlem Geçmişi', style: AppTypography.titleSm),
        ),
        const SizedBox(height: AppSpacing.md),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color:
                        AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Henüz işlem yok',
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onAddTransaction,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('İşlem Ekle'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...transactions.map((t) => _TxTile(transaction: t)),
      ],
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.transaction});
  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.INCOME;
    final isTransfer = transaction.type == TransactionType.TRANSFER;
    final amountColor = isTransfer
        ? AppColors.onSurfaceVariant
        : isIncome
            ? AppColors.secondary
            : AppColors.tertiary;

    final categoryColor = transaction.category?.color != null
        ? _hexColor(transaction.category!.color!)
        : amountColor;

    final iconData = transaction.category?.icon != null
        ? IconMapper.fromString(transaction.category!.icon)
        : isIncome
            ? Icons.arrow_downward_rounded
            : isTransfer
                ? Icons.swap_horiz_rounded
                : Icons.arrow_upward_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: categoryColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ??
                      transaction.category?.name ??
                      (isTransfer ? 'Transfer' : 'İşlem'),
                  style: AppTypography.bodyMd
                      .copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormatter.formatShort(transaction.date),
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : isTransfer ? '' : '-'}${CurrencyFormatter.format(transaction.amount)}',
            style: AppTypography.bodyMd.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(
          int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.onSurfaceVariant;
    }
  }
}

// ── Shimmer (yüklenirken) ──────────────────────────────────────────────────

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer({this.account});
  final AccountModel? account;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        if (account != null) _AccountHeaderCard(account: account!),
        if (account == null)
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding),
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Hata ekranı ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 56,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Tekrar Dene',
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
