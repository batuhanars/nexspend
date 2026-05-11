import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/inflation_model.dart';
import '../../../navigation/route_names.dart';
import '../../inflation/bloc/inflation_bloc.dart';
import '../../inflation/bloc/inflation_event.dart';
import '../../inflation/bloc/inflation_state.dart';
import '../../inflation/widgets/inflation_suggestion_card.dart';
import '../bloc/budgets_bloc.dart';
import '../bloc/budgets_event.dart';
import '../bloc/budgets_state.dart';
import '../widgets/budget_card.dart';
import '../widgets/budgets_shimmer.dart';
import '../widgets/edit_budget_sheet.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/error_view.dart';
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
    final s = AppStrings.of(context);
    return MultiBlocListener(
      listeners: [
        // İlk yüklemede (Loading→Loaded) aktif bütçeler için suggestion çek
        BlocListener<BudgetsBloc, BudgetsState>(
          listenWhen: (prev, curr) =>
              curr is BudgetsLoaded && prev is! BudgetsLoaded,
          listener: (context, state) {
            if (state is BudgetsLoaded && state.budgets.isNotEmpty) {
              final ids = state.budgets
                  .where((b) => b.isActive)
                  .map((b) => b.id)
                  .toList();
              context.read<InflationBloc>().add(
                    InflationSuggestionsFetchRequested(budgetIds: ids),
                  );
            }
          },
        ),
        // Apply başarılı → bütçeleri + suggestion'ları yenile
        BlocListener<InflationBloc, InflationState>(
          listener: (context, state) {
            if (state is InflationApplied) {
              context.read<BudgetsBloc>().add(const BudgetsRefreshRequested());
              final budgetsState = context.read<BudgetsBloc>().state;
              if (budgetsState is BudgetsLoaded) {
                final ids = budgetsState.budgets
                    .where((b) => b.isActive)
                    .map((b) => b.id)
                    .toList();
                context.read<InflationBloc>().add(
                      InflationSuggestionsFetchRequested(budgetIds: ids),
                    );
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Bütçe enflasyona göre güncellendi'),
                backgroundColor: AppColors.secondary,
              ));
            } else if (state is InflationApplyError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ));
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: BlocBuilder<BudgetsBloc, BudgetsState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
              onRefresh: () async {
                context
                    .read<BudgetsBloc>()
                    .add(const BudgetsRefreshRequested());
                final newState = await context
                    .read<BudgetsBloc>()
                    .stream
                    .firstWhere((s) => s is BudgetsLoaded || s is BudgetsError);
                // _onRefresh intermediate BudgetsLoading emit etmediği için
                // listenWhen tetiklenmiyor → suggestion fetch'i burada açıkça
                // tetikliyoruz, aksi halde değişen updatedAt'ler yansımıyor.
                if (newState is BudgetsLoaded && context.mounted) {
                  final ids = newState.budgets
                      .where((b) => b.isActive)
                      .map((b) => b.id)
                      .toList();
                  context.read<InflationBloc>().add(
                        InflationSuggestionsFetchRequested(budgetIds: ids),
                      );
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    backgroundColor: AppColors.surface,
                    surfaceTintColor: Colors.transparent,
                    title:
                        Text(s.budgetsTitle, style: AppTypography.headlineSm),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.add_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () async {
                          await context.push(RouteNames.addBudget);
                          if (context.mounted) {
                            context
                                .read<BudgetsBloc>()
                                .add(const BudgetsRefreshRequested());
                          }
                        },
                      ),
                    ],
                  ),
                  _buildBody(context, state, s),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, BudgetsState state, AppStrings s) {
    return switch (state) {
      BudgetsInitial() || BudgetsLoading() => const SliverFillRemaining(
          child: BudgetsShimmer(),
        ),
      BudgetsError(:final message) => SliverFillRemaining(
          child: ErrorView(
            message: message,
            onRetry: () =>
                context.read<BudgetsBloc>().add(const BudgetsLoadRequested()),
          ),
        ),
      BudgetsLoaded(:final overview, :final budgets) => SliverList(
          delegate: SliverChildListDelegate([
            if (overview.count > 0) ...[
              OverviewCard(overview: overview),
              const SizedBox(height: AppSpacing.xl),
            ],
            _InflationSuggestionsSection(budgets: budgets),
            if (budgets.isEmpty)
              EmptyStateView(
                icon: Icons.account_balance_wallet_outlined,
                title: s.noBudgets,
                subtitle: s.noBudgetsSubtitle,
                buttonLabel: s.createBudgetBtn,
                onAction: () async {
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
                    Text(s.activeBudgets, style: AppTypography.titleSm),
                    const SizedBox(height: AppSpacing.md),
                    ...budgets.map(
                      (b) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: BudgetCard(
                          budget: b,
                          onDelete: () {
                            context
                                .read<BudgetsBloc>()
                                .add(BudgetDeleteRequested(b.id));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(AppStrings.of(context)
                                  .budgetDeletedSuccess),
                              backgroundColor: AppColors.secondary,
                            ));
                          },
                          onEdit: () {
                            final bloc = context.read<BudgetsBloc>();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor:
                                  AppColors.surfaceContainerHigh,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                      AppSpacing.radiusLg),
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

/// Aktif bütçeler için enflasyon öneri kartlarını gösterir.
/// Null suggestion (204) olan bütçeler için kart render edilmez.
class _InflationSuggestionsSection extends StatelessWidget {
  const _InflationSuggestionsSection({required this.budgets});

  final List<BudgetModel> budgets;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InflationBloc, InflationState>(
      builder: (context, state) {
        if (state is! InflationSuggestionsLoaded) {
          return const SizedBox.shrink();
        }

        final pairs = budgets
            .where((b) => b.isActive && state.suggestions[b.id] != null)
            .map((b) => (budget: b, suggestion: state.suggestions[b.id]!))
            .toList();

        if (pairs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...pairs.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _SuggestionCardWrapper(
                    budget: p.budget,
                    suggestion: p.suggestion,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }
}

class _SuggestionCardWrapper extends StatelessWidget {
  const _SuggestionCardWrapper({
    required this.budget,
    required this.suggestion,
  });

  final BudgetModel budget;
  final InflationSuggestionModel suggestion;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InflationBloc, InflationState>(
      buildWhen: (_, curr) =>
          curr is InflationApplying ||
          curr is InflationApplied ||
          curr is InflationApplyError ||
          curr is InflationSuggestionsLoaded,
      builder: (context, state) {
        final isApplying = state is InflationApplying &&
            state.budgetId == suggestion.budgetId;
        return InflationSuggestionCard(
          suggestion: suggestion,
          budgetName: budget.name,
          isApplying: isApplying,
          onApply: () => context.read<InflationBloc>().add(
                InflationApplyRequested(
                  budgetId: suggestion.budgetId,
                  newAmount: suggestion.suggestedAmount,
                ),
              ),
        );
      },
    );
  }
}
