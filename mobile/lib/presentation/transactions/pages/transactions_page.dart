import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../navigation/route_names.dart';
import '../bloc/transactions_bloc.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/filter_chips.dart';
import '../widgets/summary_row.dart';
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
      body: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                context.read<TransactionsBloc>().add(TransactionsRefreshRequested()),
            child: CustomScrollView(
              controller: _scrollController,
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
                    child: FilterChips(activeFilter: state.filter),
                  ),
                  if (state.transactions.isEmpty)
                    const SliverFillRemaining(child: EmptyView())
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

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      title: Text('İşlemler', style: AppTypography.headlineSm),
      centerTitle: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    );
  }
}
