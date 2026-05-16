import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/app_events.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/family_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/family_repository.dart';
import '../../../navigation/route_names.dart';
import '../bloc/transactions_bloc.dart';
import '../widgets/summary_row.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/filter_chip_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    getIt<AppEvents>().addListener(_onTransactionAdded);
    _loadBudgets();
  }

  @override
  void dispose() {
    getIt<AppEvents>().removeListener(_onTransactionAdded);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBudgets() async {
    try {
      final results = await Future.wait([
        getIt<BudgetRepository>().getAll(),
        getIt<FamilyRepository>().getMySharedBudgets(),
      ]);
      if (!mounted) return;
      setState(() {
        _personalBudgets = results[0] as List<BudgetModel>;
        _sharedBudgets = results[1] as List<MySharedBudgetModel>;
      });
    } catch (_) {
      // Bütçe etiketleri gösterilmesin diye sessizce yutalım — liste yine çalışır.
    }
  }

  void _onTransactionAdded() {
    if (mounted) {
      context.read<TransactionsBloc>().add(TransactionsRefreshRequested());
      _loadBudgets();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionsBloc>().add(TransactionsLoadMoreRequested());
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
            return CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: Text(s.transactionsTitle, style: AppTypography.headlineSm),
                  centerTitle: false,
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                      onPressed: () async {
                        final bloc = context.read<TransactionsBloc>();
                        final added = await context.push(RouteNames.addTransaction);
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
                  SliverToBoxAdapter(child: SummaryRow(state: state)),
                  SliverToBoxAdapter(
                    child: FilterChipBar(
                      filters: [
                        (label: s.filterAll, value: null),
                        (label: s.income, value: 'INCOME'),
                        (label: s.expense, value: 'EXPENSE'),
                        (label: s.transfer, value: 'TRANSFER'),
                      ],
                      activeFilter: state.filter,
                      onChanged: (v) => context
                          .read<TransactionsBloc>()
                          .add(TransactionsFilterChanged(v)),
                    ),
                  ),
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
