import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../navigation/route_names.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_actions_row.dart';
import '../widgets/account_carousel.dart';
import '../widgets/recent_transactions_section.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardBloc(
        dashboardRepository: getIt<DashboardRepository>(),
      )..add(const DashboardLoadRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  bool _isBalanceHidden = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerHigh,
            onRefresh: () async {
              context
                  .read<DashboardBloc>()
                  .add(const DashboardRefreshRequested());
              await context.read<DashboardBloc>().stream.firstWhere(
                    (s) => s is DashboardLoaded || s is DashboardError,
                  );
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context, state),
                SliverToBoxAdapter(
                  child: _buildBody(context, state),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, DashboardState state) {
    String greeting = 'Merhaba';
    if (state is DashboardLoaded &&
        state.dashboard.userFirstName != null) {
      greeting = 'Merhaba, ${state.dashboard.userFirstName}';
    }

    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(greeting, style: AppTypography.headlineSm),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.onSurface),
          onPressed: () => context.push(RouteNames.settings),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    return switch (state) {
      DashboardLoading() || DashboardInitial() => const _DashboardShimmer(),
      DashboardError(:final message) => _DashboardError(
          message: message,
          onRetry: () => context
              .read<DashboardBloc>()
              .add(const DashboardLoadRequested()),
        ),
      DashboardLoaded(:final dashboard) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            BalanceCard(
              dashboard: dashboard,
              isBalanceHidden: _isBalanceHidden,
              onToggleVisibility: () =>
                  setState(() => _isBalanceHidden = !_isBalanceHidden),
            ),
            const SizedBox(height: AppSpacing.xl),
            QuickActionsRow(
              onIncome: () => context.push(
                RouteNames.addTransaction,
                extra: {'type': 'INCOME'},
              ),
              onExpense: () => context.push(
                RouteNames.addTransaction,
                extra: {'type': 'EXPENSE'},
              ),
              onTransfer: () => context.push(
                RouteNames.addTransaction,
                extra: {'type': 'TRANSFER'},
              ),
              onScan: () => context.push(RouteNames.receiptScanner),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (dashboard.accounts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Row(
                  children: [
                    Text('Hesaplarım', style: AppTypography.titleSm),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          context.push(RouteNames.addAccount),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '+ Ekle',
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AccountCarousel(
                accounts: dashboard.accounts,
                isBalanceHidden: _isBalanceHidden,
                onAddAccount: () => context.push(RouteNames.addAccount),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            RecentTransactionsSection(
              transactions: dashboard.recentTransactions,
              onViewAll: () => context.go(RouteNames.transactions),
            ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 64,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Tekrar Dene',
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Balance card shimmer
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Quick actions shimmer
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                4,
                (_) => Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Accounts shimmer
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              itemCount: 3,
              separatorBuilder: (_, index) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, index) => Container(
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Transactions shimmer
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 14,
                    width: 70,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
