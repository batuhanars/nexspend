import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../navigation/route_names.dart';
import '../bloc/budgets_bloc.dart';
import '../bloc/budgets_event.dart';
import '../bloc/budgets_state.dart';
import '../widgets/budget_card.dart';
import '../widgets/budgets_shimmer.dart';
import '../widgets/edit_budget_sheet.dart';
import '../widgets/empty_budgets_view.dart';
import '../widgets/error_view.dart';
import '../widgets/overview_card.dart';
import '../widgets/warning_banner.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BudgetsView();
  }
}

class _BudgetsView extends StatelessWidget {
  const _BudgetsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<BudgetsBloc, BudgetsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerHigh,
            onRefresh: () async {
              context.read<BudgetsBloc>().add(const BudgetsRefreshRequested());
              await context
                  .read<BudgetsBloc>()
                  .stream
                  .firstWhere((s) => s is BudgetsLoaded || s is BudgetsError);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  title: Text('Bütçeler', style: AppTypography.headlineSm),
                ),
                _buildBody(context, state),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<BudgetsBloc, BudgetsState>(
        builder: (context, state) {
          if (state is! BudgetsLoaded || state.budgets.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () async {
              await context.push(RouteNames.addBudget);
              if (context.mounted) {
                context
                    .read<BudgetsBloc>()
                    .add(const BudgetsRefreshRequested());
              }
            },
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BudgetsState state) {
    return switch (state) {
      BudgetsInitial() || BudgetsLoading() => const SliverFillRemaining(
          child: BudgetsShimmer(),
        ),
      BudgetsError(:final message) => SliverFillRemaining(
          child: ErrorView(
            message: message,
            onRetry: () => context
                .read<BudgetsBloc>()
                .add(const BudgetsLoadRequested()),
          ),
        ),
      BudgetsLoaded(:final overview, :final budgets) => SliverList(
          delegate: SliverChildListDelegate([
            if (overview.count > 0) ...[
              OverviewCard(overview: overview),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (budgets.isEmpty)
              EmptyBudgetsView(
                onAdd: () async {
                  await context.push(RouteNames.addBudget);
                  if (context.mounted) {
                    context
                        .read<BudgetsBloc>()
                        .add(const BudgetsRefreshRequested());
                  }
                },
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WarningBanner(budgets: budgets),
                    Text('Aktif Bütçeler', style: AppTypography.titleSm),
                    const SizedBox(height: AppSpacing.md),
                    ...budgets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: BudgetCard(
                          budget: b,
                          onDelete: () => context
                              .read<BudgetsBloc>()
                              .add(BudgetDeleteRequested(b.id)),
                          onEdit: () {
                            final bloc = context.read<BudgetsBloc>();
                            showModalBottomSheet(
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
                                child: EditBudgetSheet(budget: b),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ]),
        ),
    };
  }
}
