import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/transaction_model.dart';
import '../../../navigation/route_names.dart';
import '../bloc/transactions_bloc.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<TransactionsBloc>().add(TransactionsLoadRequested());
    return const _TransactionsView();
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                context.read<TransactionsBloc>().add(TransactionsRefreshRequested()),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                if (state is TransactionsLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (state is TransactionsError)
                  SliverFillRemaining(child: _ErrorView(message: state.message))
                else if (state is TransactionsLoaded) ...[
                  SliverToBoxAdapter(child: _SummaryRow(state: state)),
                  SliverToBoxAdapter(
                    child: _FilterChips(activeFilter: state.filter),
                  ),
                  if (state.transactions.isEmpty)
                    const SliverFillRemaining(child: _EmptyView())
                  else
                    _TransactionList(grouped: state.grouped),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await context.push(RouteNames.addTransaction);
          if (added == true && context.mounted) {
            context.read<TransactionsBloc>().add(TransactionsRefreshRequested());
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      title: Text('İşlemler', style: AppTypography.headlineSm),
      centerTitle: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    );
  }
}

// ── Özet kartları ──────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.state});
  final TransactionsLoaded state;

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
              label: 'Gelir',
              amount: state.income,
              color: AppColors.secondary,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryCard(
              label: 'Gider',
              amount: state.expense,
              color: AppColors.tertiary,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryCard(
              label: 'Net',
              amount: state.net,
              color: state.net >= 0 ? AppColors.secondary : AppColors.tertiary,
              icon: Icons.account_balance_wallet_outlined,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
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
              Text(
                label,
                style: AppTypography.labelSm.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: AppTypography.titleSm.copyWith(
              color: AppColors.onSurface,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    (label: 'Hepsi', value: null),
    (label: 'Gelir', value: 'INCOME'),
    (label: 'Gider', value: 'EXPENSE'),
    (label: 'Transfer', value: 'TRANSFER'),
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
                    .read<TransactionsBloc>()
                    .add(TransactionsFilterChanged(f.value)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surfaceContainerHigh,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
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

// ── İşlem listesi (tarih gruplu) ───────────────────────────────────────────

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.grouped});
  final Map<String, List<TransactionModel>> grouped;

  @override
  Widget build(BuildContext context) {
    final entries = grouped.entries.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = entries[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.lg,
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                ),
                child: Text(
                  entry.key,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...entry.value.map(
                (t) => _TransactionTile(transaction: t),
              ),
            ],
          );
        },
        childCount: entries.length,
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
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
        : isIncome
            ? AppColors.secondary
            : AppColors.tertiary;

    final iconData = transaction.category?.icon != null
        ? IconMapper.fromString(transaction.category!.icon)
        : isIncome
            ? Icons.arrow_downward_rounded
            : isTransfer
                ? Icons.swap_horiz_rounded
                : Icons.arrow_upward_rounded;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: AppColors.errorContainer,
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => context
          .read<TransactionsBloc>()
          .add(TransactionDeleteRequested(transaction.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: categoryColor, size: 20),
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
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.account?.name ?? ''}  •  ${DateFormatter.formatTime(transaction.date)}',
                    style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${isIncome ? '+' : isTransfer ? '' : '-'}${CurrencyFormatter.format(transaction.amount)}',
              style: AppTypography.bodyMd.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('İşlemi Sil', style: AppTypography.titleSm),
        content: Text(
          'Bu işlem silinecek ve hesap bakiyesi güncellenecek.',
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
            child: Text('Sil',
                style: TextStyle(color: AppColors.error)),
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
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Henüz işlem yok', style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sağ alttaki + butonuyla\nilk işleminizi ekleyin',
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
              size: 48, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.lg),
          Text(message,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonal(
            onPressed: () => context
                .read<TransactionsBloc>()
                .add(TransactionsLoadRequested()),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}
