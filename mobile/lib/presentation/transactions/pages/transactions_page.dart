import 'dart:async';

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
import '../../../data/models/budget_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/family_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/family_repository.dart';
import '../../../navigation/route_names.dart';
import '../bloc/transaction_filter.dart';
import '../bloc/transactions_bloc.dart';
import '../widgets/summary_row.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/filter_chip_bar.dart';
import '../widgets/transaction_filter_sheet.dart';
import '../widgets/transaction_list.dart';
import '../widgets/transactions_shimmer.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<TransactionsBloc>().add(TransactionsLoadRequested());
    return const _TransactionsView();
  }
}

class _TransactionsView extends StatefulWidget {
  const _TransactionsView();

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  final _scrollController = ScrollController();
  List<BudgetModel> _personalBudgets = const [];
  List<MySharedBudgetModel> _sharedBudgets = const [];
  List<CategoryModel> _categories = const [];
  List<AccountModel> _accounts = const [];

  // Arama
  bool _searchActive = false;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    getIt<AppEvents>().addListener(_onTransactionAdded);
    _loadSupportData();
  }

  @override
  void dispose() {
    getIt<AppEvents>().removeListener(_onTransactionAdded);
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSupportData() async {
    try {
      final results = await Future.wait([
        getIt<BudgetRepository>().getAll(),
        getIt<FamilyRepository>().getMySharedBudgets(),
        getIt<CategoryRepository>().getCategories(),
        getIt<AccountRepository>().getAccounts(),
      ]);
      if (!mounted) return;
      setState(() {
        _personalBudgets = results[0] as List<BudgetModel>;
        _sharedBudgets = results[1] as List<MySharedBudgetModel>;
        _categories = results[2] as List<CategoryModel>;
        _accounts = results[3] as List<AccountModel>;
      });
    } catch (_) {
      // Bütçe/kategori/hesap yüklenemezse sessizce devam et
    }
  }

  void _onTransactionAdded() {
    if (mounted) {
      context.read<TransactionsBloc>().add(TransactionsRefreshRequested());
      _loadSupportData();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionsBloc>().add(TransactionsLoadMoreRequested());
    }
  }

  TransactionFilter _currentFilter(TransactionsState state) {
    if (state is TransactionsLoaded) return state.filter;
    return TransactionFilter.empty;
  }

  void _onTypeChipChanged(String? type, TransactionFilter current) {
    final newFilter = current.copyWith(type: type);
    context.read<TransactionsBloc>().add(TransactionsFilterChanged(newFilter));
  }

  void _openFilterSheet(TransactionFilter current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFilterSheet(
        initialFilter: current,
        categories: _categories,
        accounts: _accounts,
        onApply: (newFilter) {
          context
              .read<TransactionsBloc>()
              .add(TransactionsFilterChanged(newFilter));
        },
      ),
    );
  }

  void _onSearchChanged(String q, TransactionFilter current) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final search = q.trim().isEmpty ? null : q.trim();
      final newFilter = current.copyWith(search: search);
      context
          .read<TransactionsBloc>()
          .add(TransactionsFilterChanged(newFilter));
    });
  }

  void _removeActiveFilterChip(String key, TransactionFilter current) {
    TransactionFilter newFilter;
    switch (key) {
      case 'category':
        newFilter = current.copyWith(categoryId: null);
      case 'account':
        newFilter = current.copyWith(accountId: null);
      case 'date':
        newFilter = current.copyWith(startDate: null, endDate: null);
      case 'search':
        newFilter = current.copyWith(search: null);
        _searchController.clear();
      default:
        return;
    }
    context.read<TransactionsBloc>().add(TransactionsFilterChanged(newFilter));
  }

  Future<void> _confirmBulkDelete(
    BuildContext context,
    int count,
    AppStrings s,
  ) async {
    final bloc = context.read<TransactionsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(s.bulkDeleteTitle, style: AppTypography.titleSm),
        content: Text(
          s.bulkDeleteContent(count),
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      bloc.add(BulkDeleteRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerHigh,
        onRefresh: () async {
          context
              .read<TransactionsBloc>()
              .add(TransactionsRefreshRequested());
          await context.read<TransactionsBloc>().stream.firstWhere(
                (s) => s is TransactionsLoaded || s is TransactionsError,
              );
        },
        child: BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, state) {
            final filter = _currentFilter(state);
            final selectionMode =
                state is TransactionsLoaded && state.selectionMode;
            final selectedIds =
                state is TransactionsLoaded ? state.selectedIds : <String>{};
            final selectedCount = selectedIds.length;

            return CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (selectionMode)
                  // Contextual AppBar — seçim modu
                  SliverAppBar(
                    floating: true,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.onSurface),
                      onPressed: () => context
                          .read<TransactionsBloc>()
                          .add(SelectionCleared()),
                    ),
                    title: Text(
                      s.selectionCount(selectedCount),
                      style: AppTypography.headlineSm,
                    ),
                    centerTitle: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error),
                        onPressed: selectedCount == 0
                            ? null
                            : () => _confirmBulkDelete(context, selectedCount, s),
                      ),
                    ],
                  )
                else
                  // Normal AppBar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: AppColors.surface,
                    surfaceTintColor: Colors.transparent,
                    title: _searchActive
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: AppTypography.bodyMd,
                            decoration: InputDecoration(
                              hintText: s.searchLabel,
                              hintStyle: AppTypography.bodyMd
                                  .copyWith(color: AppColors.onSurfaceVariant),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (q) => _onSearchChanged(q, filter),
                          )
                        : Text(s.transactionsTitle,
                            style: AppTypography.headlineSm),
                    centerTitle: false,
                    actions: [
                      // Arama aç/kapat
                      IconButton(
                        icon: Icon(
                          _searchActive
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          color: _searchActive
                              ? AppColors.primary
                              : AppColors.onSurface,
                        ),
                        onPressed: () {
                          setState(() => _searchActive = !_searchActive);
                          if (!_searchActive) {
                            _searchController.clear();
                            _searchDebounce?.cancel();
                            // Arama filtresi kaldır
                            final newFilter = filter.copyWith(search: null);
                            context
                                .read<TransactionsBloc>()
                                .add(TransactionsFilterChanged(newFilter));
                          }
                        },
                      ),
                      // Filtre butonu + rozet
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.tune_rounded,
                              color: filter.activeCount > 0
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                            ),
                            onPressed: () => _openFilterSheet(filter),
                          ),
                          if (filter.activeCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${filter.activeCount}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onPrimary,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // İşlem ekle
                      IconButton(
                        icon: const Icon(Icons.add_rounded,
                            color: AppColors.primary),
                        onPressed: () async {
                          final bloc = context.read<TransactionsBloc>();
                          final added =
                              await context.push(RouteNames.addTransaction);
                          if (added == true && mounted) {
                            bloc.add(TransactionsRefreshRequested());
                          }
                        },
                      ),
                    ],
                  ),
                if (state is TransactionsLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: TransactionsShimmer(),
                  )
                else if (state is TransactionsError)
                  SliverFillRemaining(
                    child: ErrorView(
                      message: state.message,
                      onRetry: () => context
                          .read<TransactionsBloc>()
                          .add(TransactionsLoadRequested()),
                    ),
                  )
                else if (state is TransactionsLoaded) ...[
                  if (!selectionMode) ...[
                    SliverToBoxAdapter(child: SummaryRow(state: state)),
                    // Tip chip bar + filtre ikonu
                    SliverToBoxAdapter(
                      child: FilterChipBar(
                        filters: [
                          (label: s.filterAll, value: null),
                          (label: s.income, value: 'INCOME'),
                          (label: s.expense, value: 'EXPENSE'),
                          (label: s.transfer, value: 'TRANSFER'),
                        ],
                        activeFilter: filter.type,
                        onChanged: (v) => _onTypeChipChanged(v, filter),
                      ),
                    ),
                    // Aktif filtre özet chip'leri
                    if (filter.activeCount > 0)
                      SliverToBoxAdapter(
                        child: _ActiveFilterChips(
                          filter: filter,
                          categories: _categories,
                          accounts: _accounts,
                          onRemove: (key) =>
                              _removeActiveFilterChip(key, filter),
                          s: s,
                        ),
                      ),
                  ],
                  if (state.transactions.isEmpty)
                    SliverFillRemaining(
                      child: EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: s.noTransactions,
                        subtitle: s.noTransactionsSubtitle,
                        buttonLabel: s.addTransactionBtn,
                        onAction: () async {
                          final bloc = context.read<TransactionsBloc>();
                          final added =
                              await context.push(RouteNames.addTransaction);
                          if (added == true && mounted) {
                            bloc.add(TransactionsRefreshRequested());
                          }
                        },
                      ),
                    )
                  else ...[
                    TransactionList(
                      transactions: state.transactions,
                      personalBudgets: _personalBudgets,
                      sharedBudgets: _sharedBudgets,
                      selectionMode: selectionMode,
                      selectedIds: selectedIds,
                    ),
                    if (state.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Aktif filtre boyutlarını kaldırılabilir chip olarak gösterir.
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.filter,
    required this.categories,
    required this.accounts,
    required this.onRemove,
    required this.s,
  });

  final TransactionFilter filter;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final ValueChanged<String> onRemove;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final chips = <({String key, String label})>[];

    if (filter.categoryId != null) {
      final cat = categories.where((c) => c.id == filter.categoryId).firstOrNull;
      chips.add((key: 'category', label: cat?.name ?? s.categoryLabel));
    }
    if (filter.accountId != null) {
      final acc = accounts.where((a) => a.id == filter.accountId).firstOrNull;
      chips.add((key: 'account', label: acc?.name ?? s.accountLabel));
    }
    if (filter.startDate != null || filter.endDate != null) {
      final start = filter.startDate;
      final end = filter.endDate;
      String label;
      if (start != null && end != null) {
        label =
            '${start.day}.${start.month} – ${end.day}.${end.month}';
      } else if (start != null) {
        label = '≥ ${start.day}.${start.month}.${start.year}';
      } else {
        label = '≤ ${end!.day}.${end.month}.${end.year}';
      }
      chips.add((key: 'date', label: label));
    }
    if (filter.search != null && filter.search!.isNotEmpty) {
      chips.add((key: 'search', label: '"${filter.search}"'));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        children: chips
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _RemovableChip(
                  label: c.label,
                  onRemove: () => onRemove(c.key),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
