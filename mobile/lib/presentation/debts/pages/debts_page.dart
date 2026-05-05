import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/presentation/debts/widgets/add_debt_sheet.dart';
import 'package:wallet_app/presentation/debts/widgets/debt_list.dart';
import 'package:wallet_app/presentation/debts/widgets/debts_shimmer.dart';
import 'package:wallet_app/presentation/shared/widgets/empty_state_view.dart';
import 'package:wallet_app/presentation/shared/widgets/error_view.dart';
import 'package:wallet_app/presentation/shared/widgets/filter_chip_bar.dart';
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
                    child: FilterChipBar(
                      filters: [
                        (label: AppStrings.of(context).allOption, value: null),
                        (label: AppStrings.of(context).debtTypeLent, value: 'LENT'),
                        (label: AppStrings.of(context).debtTypeBorrowed, value: 'BORROWED'),
                      ],
                      activeFilter: state.filter,
                      onChanged: (v) => context
                          .read<DebtsBloc>()
                          .add(DebtsFilterChanged(v)),
                    ),
                  ),
                  if (state.debts.isEmpty)
                    SliverFillRemaining(
                      child: EmptyStateView(
                        icon: Icons.handshake_outlined,
                        title: AppStrings.of(context).noDebtsTitle,
                        subtitle: AppStrings.of(context).noDebtsSubtitle,
                        buttonLabel: AppStrings.of(context).addDebtBtn,
                        onAction: () => _showAddDebtSheet(context),
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
      title: Text(AppStrings.of(context).debtsTitle, style: AppTypography.headlineSm),
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
