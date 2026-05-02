import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../bloc/subscriptions_bloc.dart';
import '../widgets/add_subscription_sheet.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/subscription_list.dart';
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
                _buildAppBar(context),
                if (state is SubscriptionsLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (state is SubscriptionsError)
                  SliverFillRemaining(child: ErrorView(message: state.message))
                else if (state is SubscriptionsLoaded) ...[
                  SliverToBoxAdapter(child: SummaryCard(state: state)),
                  if (state.upcomingRenewals.isNotEmpty)
                    SliverToBoxAdapter(
                      child: UpcomingBanner(renewals: state.upcomingRenewals),
                    ),
                  if (state.subscriptions.isEmpty)
                    const SliverFillRemaining(child: EmptyView())
                  else
                    SubscriptionList(subscriptions: state.subscriptions),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      title: Text('Abonelikler', style: AppTypography.headlineSm),
      centerTitle: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
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
