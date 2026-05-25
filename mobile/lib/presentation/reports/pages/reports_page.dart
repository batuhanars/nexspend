import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/presentation/reports/widgets/cash_flow_chart.dart';
import 'package:wallet_app/presentation/reports/widgets/expense_distribution_section.dart';
import 'package:wallet_app/presentation/reports/widgets/period_filter.dart';
import 'package:wallet_app/presentation/reports/widgets/section_title.dart';
import 'package:wallet_app/presentation/reports/widgets/trend_list.dart';
import 'package:wallet_app/presentation/shared/widgets/empty_state_view.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/inflation_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../inflation/bloc/inflation_bloc.dart';
import '../../inflation/bloc/inflation_event.dart';
import '../../inflation/bloc/inflation_state.dart';
import '../../inflation/widgets/inflation_comparison_table.dart';
import '../../inflation/widgets/inflation_trend_chart.dart';
import '../bloc/reports_bloc.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ReportsBloc(reportRepository: getIt<ReportRepository>())
                ..add(const ReportsLoadRequested()),
        ),
        BlocProvider(
          create: (_) => InflationBloc(
            inflationRepository: getIt<InflationRepository>(),
          ),
        ),
      ],
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(
            AppStrings.of(context).reportsTitle,
            style: AppTypography.headlineSm,
          ),
          centerTitle: false,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            labelStyle:
                AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTypography.bodySm,
            dividerColor: AppColors.surfaceContainerHighest,
            tabs: const [
              Tab(text: 'Genel'),
              Tab(text: 'Enflasyon'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GeneralReportTab(),
            _InflationReportTab(),
          ],
        ),
      ),
    );
  }
}

class _GeneralReportTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        if (state is ReportsLoading || state is ReportsInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is ReportsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  state.message,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.tonal(
                  onPressed: () => context
                      .read<ReportsBloc>()
                      .add(const ReportsLoadRequested()),
                  child: Text(AppStrings.of(context).retry),
                ),
              ],
            ),
          );
        }
        final loaded = state as ReportsLoaded;
        final hasNoData = loaded.cashFlow.isEmpty &&
            loaded.distribution.isEmpty &&
            loaded.trends.isEmpty;
        if (hasNoData) {
          return Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: PeriodFilter(activePeriod: loaded.period),
              ),
              Expanded(
                child: EmptyStateView(
                  icon: Icons.bar_chart_rounded,
                  title: AppStrings.of(context).reportsEmptyTitle,
                  subtitle: AppStrings.of(context).reportsEmptySubtitle,
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          children: [
            const SizedBox(height: AppSpacing.lg),
            PeriodFilter(activePeriod: loaded.period),
            const SizedBox(height: AppSpacing.xl),
            if (loaded.cashFlow.isNotEmpty) ...[
              SectionTitle(title: AppStrings.of(context).cashFlowTitle),
              const SizedBox(height: AppSpacing.md),
              CashFlowChart(items: loaded.cashFlow),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (loaded.distribution.isNotEmpty) ...[
              SectionTitle(
                  title: AppStrings.of(context).expenseDistributionTitle),
              const SizedBox(height: AppSpacing.md),
              ExpenseDistributionSection(items: loaded.distribution),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (loaded.trends.isNotEmpty) ...[
              SectionTitle(title: AppStrings.of(context).categoryTrendsTitle),
              const SizedBox(height: AppSpacing.md),
              TrendList(trends: loaded.trends),
            ],
            const SizedBox(height: AppSpacing.xxxl),
          ],
        );
      },
    );
  }
}

class _InflationReportTab extends StatefulWidget {
  @override
  State<_InflationReportTab> createState() => _InflationReportTabState();
}

class _InflationReportTabState extends State<_InflationReportTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<InflationBloc>().add(const InflationReportFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<InflationBloc, InflationState>(
      buildWhen: (_, curr) =>
          curr is InflationReportLoading ||
          curr is InflationReportLoaded ||
          curr is InflationReportError,
      builder: (context, state) {
        if (state is InflationReportLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is InflationReportError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  state.message,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.tonal(
                  onPressed: () => context
                      .read<InflationBloc>()
                      .add(const InflationReportFetchRequested()),
                  child: Text(AppStrings.of(context).retry),
                ),
              ],
            ),
          );
        }

        if (state is! InflationReportLoaded) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final comparison = state.comparison;
        final history = state.history;

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          children: [
            const SizedBox(height: AppSpacing.lg),
            if (comparison.rows.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                  child: Text(
                    'Enflasyon verisi henüz hazir degil',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else ...[
              SectionTitle(title: 'Harcama vs Enflasyon'),
              const SizedBox(height: AppSpacing.xs),
              Text(
                comparison.period,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InflationComparisonTable(comparison: comparison),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (history.isNotEmpty) ...[
              SectionTitle(title: 'Enflasyon Trendi'),
              const SizedBox(height: AppSpacing.md),
              InflationTrendChart(history: history),
            ],
            const SizedBox(height: AppSpacing.xxxl),
          ],
        );
      },
    );
  }
}
