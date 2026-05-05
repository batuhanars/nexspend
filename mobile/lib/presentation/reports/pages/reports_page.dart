import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/presentation/reports/widgets/cash_flow_chart.dart';
import 'package:wallet_app/presentation/reports/widgets/expense_distribution_section.dart';
import 'package:wallet_app/presentation/reports/widgets/period_filter.dart';
import 'package:wallet_app/presentation/reports/widgets/section_title.dart';
import 'package:wallet_app/presentation/reports/widgets/trend_list.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/report_repository.dart';
import '../bloc/reports_bloc.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ReportsBloc(reportRepository: getIt<ReportRepository>())
            ..add(const ReportsLoadRequested()),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context).reportsTitle, style: AppTypography.headlineSm),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<ReportsBloc, ReportsState>(
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
                    onPressed: () => context.read<ReportsBloc>().add(
                      const ReportsLoadRequested(),
                    ),
                    child: Text(AppStrings.of(context).retry),
                  ),
                ],
              ),
            );
          }
          final loaded = state as ReportsLoaded;
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
                SectionTitle(title: AppStrings.of(context).expenseDistributionTitle),
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
      ),
    );
  }
}
