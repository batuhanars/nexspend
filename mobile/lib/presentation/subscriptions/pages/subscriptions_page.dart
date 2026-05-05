import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../bloc/subscriptions_bloc.dart';
import '../widgets/add_subscription_sheet.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/error_view.dart';
import '../widgets/subscription_list.dart';
import '../widgets/subscriptions_shimmer.dart';
import '../widgets/summary_card.dart';
import '../widgets/upcoming_banner.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<SubscriptionsBloc>().add(const SubscriptionsLoadRequested());
    return const _SubscriptionsView();
  }
}

class _SubscriptionsView extends StatelessWidget {
  const _SubscriptionsView();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: BlocBuilder<SubscriptionsBloc, SubscriptionsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => context.read<SubscriptionsBloc>().add(
              const SubscriptionsRefreshRequested(),
            ),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: Text(s.subscriptionsTitle, style: AppTypography.headlineSm),
                  centerTitle: false,
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                      onPressed: () => _showAddSheet(context),
                    ),
                  ],
                ),
                if (state is SubscriptionsLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: SubscriptionsShimmer(),
                  )
                else if (state is SubscriptionsError)
                  SliverFillRemaining(
                    child: ErrorView(
                      message: state.message,
                      onRetry: () => context
                          .read<SubscriptionsBloc>()
                          .add(const SubscriptionsLoadRequested()),
                    ),
                  )
                else if (state is SubscriptionsLoaded) ...[
                  SliverToBoxAdapter(child: SummaryCard(state: state)),
                  if (state.upcomingRenewals.isNotEmpty)
                    SliverToBoxAdapter(
                      child: UpcomingBanner(renewals: state.upcomingRenewals),
                    ),
                  if (state.subscriptions.isEmpty)
                    SliverFillRemaining(
                      child: EmptyStateView(
                        icon: Icons.subscriptions_outlined,
                        title: s.noSubscriptions,
                        subtitle: s.noSubscriptionsSubtitle,
                        buttonLabel: s.addSubscriptionBtn,
                        onAction: () => _showAddSheet(context),
                      ),
                    )
                  else
                    SubscriptionList(subscriptions: state.subscriptions),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
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
        value: context.read<SubscriptionsBloc>(),
        child: const AddSubscriptionSheet(),
      ),
    );
  }
}
