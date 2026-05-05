import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/app_events.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../navigation/route_names.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/account_carousel.dart';
import '../widgets/balance_card.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/debt_shortcut_card.dart';
import '../widgets/empty_accounts_card.dart';
import '../widgets/recent_transactions_section.dart';
import '../../shared/widgets/error_view.dart';

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
  void initState() {
    super.initState();
    getIt<AppEvents>().addListener(_onTransactionAdded);
  }

  @override
  void dispose() {
    getIt<AppEvents>().removeListener(_onTransactionAdded);
    super.dispose();
  }

  void _onTransactionAdded() {
    if (mounted) {
      context.read<DashboardBloc>().add(const DashboardRefreshRequested());
    }
  }

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
    if (state is DashboardLoaded && state.dashboard.userFirstName != null) {
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
      DashboardLoading() || DashboardInitial() => const DashboardShimmer(),
      DashboardError(:final message) => ErrorView(
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: Row(
                children: [
                  Text('Hesaplarım', style: AppTypography.titleSm),
                  const Spacer(),
                  if (dashboard.accounts.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        final bloc = context.read<DashboardBloc>();
                        await context.push(RouteNames.addAccount);
                        if (mounted) {
                          bloc.add(const DashboardRefreshRequested());
                        }
                      },
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
            if (dashboard.accounts.isEmpty)
              EmptyAccountsCard(
                onTap: () async {
                  final bloc = context.read<DashboardBloc>();
                  await context.push(RouteNames.addAccount);
                  if (mounted) bloc.add(const DashboardRefreshRequested());
                },
              )
            else
              AccountCarousel(
                accounts: dashboard.accounts,
                isBalanceHidden: _isBalanceHidden,
                onAccountTap: (account) => context.push(
                  RouteNames.accountDetail(account.id),
                  extra: account,
                ),
                onAddAccount: () async {
                  final bloc = context.read<DashboardBloc>();
                  await context.push(RouteNames.addAccount);
                  if (mounted) bloc.add(const DashboardRefreshRequested());
                },
              ),
            const SizedBox(height: AppSpacing.xl),
            DebtShortcutCard(
              onTap: () => context.push(RouteNames.debts),
            ),
            const SizedBox(height: AppSpacing.xl),
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
