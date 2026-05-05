import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionsBloc>().add(TransactionsLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _buildAppBar(),
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
                      filters: const [
                        (label: 'Hepsi', value: null),
                        (label: 'Gelir', value: 'INCOME'),
                        (label: 'Gider', value: 'EXPENSE'),
                        (label: 'Transfer', value: 'TRANSFER'),
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
                        title: 'Henüz işlem yok',
                        subtitle: 'İlk işleminizi ekleyerek\ngelir ve giderlerinizi takip edin.',
                        buttonLabel: 'İşlem Ekle',
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
                    TransactionList(grouped: state.grouped),
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

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      title: Text('İşlemler', style: AppTypography.headlineSm),
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
    );
  }
}
