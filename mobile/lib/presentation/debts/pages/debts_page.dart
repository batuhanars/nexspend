import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/presentation/debts/widgets/add_debt_sheet.dart';
import 'package:wallet_app/presentation/debts/widgets/debt_list.dart';
import 'package:wallet_app/presentation/debts/widgets/debts_shimmer.dart';
import 'package:wallet_app/presentation/debts/widgets/empty_view.dart';
import 'package:wallet_app/presentation/debts/widgets/error_view.dart';
import 'package:wallet_app/presentation/debts/widgets/filter_chips.dart';
import 'package:wallet_app/presentation/debts/widgets/summary_cards.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../bloc/debts_bloc.dart';

class DebtsPage extends StatelessWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<DebtsBloc>().add(const DebtsLoadRequested());
    return const _DebtsView();
  }
}

class _DebtsView extends StatelessWidget {
  const _DebtsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DebtsBloc, DebtsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                context.read<DebtsBloc>().add(const DebtsRefreshRequested()),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                if (state is DebtsLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: DebtsShimmer(),
                  )
                else if (state is DebtsError)
                  SliverFillRemaining(
                    child: ErrorView(
                      message: state.message,
                      onRetry: () => context
                          .read<DebtsBloc>()
                          .add(const DebtsLoadRequested()),
                    ),
                  )
                else if (state is DebtsLoaded) ...[
                  SliverToBoxAdapter(
                    child: SummaryCards(
                      summary: state.summary,
                      activeFilter: state.filter,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FilterChips(activeFilter: state.filter),
                  ),
                  if (state.debts.isEmpty)
                    SliverFillRemaining(
                      child: EmptyView(
                        onAdd: () => _showAddDebtSheet(context),
                      ),
                    )
                  else
                    DebtList(debts: state.debts),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      title: Text('Borçlar', style: AppTypography.headlineSm),
      centerTitle: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          onPressed: () => _showAddDebtSheet(context),
        ),
      ],
    );
  }

  void _showAddDebtSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<DebtsBloc>(),
        child: const AddDebtSheet(),
      ),
    );
  }
}
