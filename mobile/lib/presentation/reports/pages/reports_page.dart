import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../bloc/reports_bloc.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportsBloc(reportRepository: getIt<ReportRepository>())
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
        title: Text('Raporlar', style: AppTypography.headlineSm),
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
                  Icon(Icons.wifi_off_rounded,
                      size: 48,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(state.message,
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.tonal(
                    onPressed: () => context
                        .read<ReportsBloc>()
                        .add(const ReportsLoadRequested()),
                    child: const Text('Tekrar Dene'),
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
              _PeriodFilter(activePeriod: loaded.period),
              const SizedBox(height: AppSpacing.xl),
              if (loaded.cashFlow.isNotEmpty) ...[
                _SectionTitle('Nakit Akışı'),
                const SizedBox(height: AppSpacing.md),
                _CashFlowChart(items: loaded.cashFlow),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (loaded.distribution.isNotEmpty) ...[
                _SectionTitle('Harcama Dağılımı'),
                const SizedBox(height: AppSpacing.md),
                _ExpenseDistributionSection(items: loaded.distribution),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (loaded.trends.isNotEmpty) ...[
                _SectionTitle('Kategori Trendleri'),
                const SizedBox(height: AppSpacing.md),
                _TrendList(trends: loaded.trends),
              ],
              const SizedBox(height: AppSpacing.xxxl),
            ],
          );
        },
      ),
    );
  }
}

// ── Dönem filtresi ─────────────────────────────────────────────────────────

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({required this.activePeriod});
  final String activePeriod;

  static const _periods = [
    (label: 'Bu Ay', value: 'THIS_MONTH'),
    (label: '3 Ay', value: 'LAST_3_MONTHS'),
    (label: 'Bu Yıl', value: 'THIS_YEAR'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _periods.map((p) {
        final isActive = activePeriod == p.value;
        final isLast = p == _periods.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
            child: GestureDetector(
              onTap: () => context
                  .read<ReportsBloc>()
                  .add(ReportsPeriodChanged(p.value)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: isActive
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Nakit akışı bar chart ─────────────────────────────────────────────────

class _CashFlowChart extends StatelessWidget {
  const _CashFlowChart({required this.items});
  final List<CashFlowItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final maxVal = items
        .expand((i) => [i.income, i.expense])
        .reduce(math.max);
    final topY = (maxVal * 1.2).ceilToDouble();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: BarChart(
        BarChartData(
          maxY: topY > 0 ? topY : 100,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceContainerHighest,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = rodIndex == 0 ? 'Gelir' : 'Gider';
                return BarTooltipItem(
                  '$label\n${CurrencyFormatter.formatCompact(rod.toY)}',
                  AppTypography.bodySm.copyWith(
                    color: rodIndex == 0
                        ? AppColors.secondary
                        : AppColors.tertiary,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= items.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      items[i].label,
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, _) => Text(
                  CurrencyFormatter.formatCompact(value),
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant, fontSize: 9),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.surfaceContainerHighest,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(items.length, (i) {
            final item = items[i];
            return BarChartGroupData(
              x: i,
              groupVertically: false,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: item.income,
                  color: AppColors.secondary,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: item.expense,
                  color: AppColors.tertiary,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Harcama dağılımı (Donut + liste) ─────────────────────────────────────

class _ExpenseDistributionSection extends StatefulWidget {
  const _ExpenseDistributionSection({required this.items});
  final List<ExpenseDistributionItem> items;

  @override
  State<_ExpenseDistributionSection> createState() =>
      _ExpenseDistributionSectionState();
}

class _ExpenseDistributionSectionState
    extends State<_ExpenseDistributionSection> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final items = widget.items.take(8).toList();
    final colors = _generateColors(items.length);

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: List.generate(items.length, (i) {
                    final isTouched = i == _touchedIndex;
                    return PieChartSectionData(
                      color: colors[i],
                      value: items[i].percentage,
                      title: isTouched
                          ? '${items[i].percentage.toStringAsFixed(1)}%'
                          : '',
                      radius: isTouched ? 40 : 32,
                      titleStyle: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  math.min(items.length, 5),
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            items[i].categoryName,
                            style: AppTypography.bodySm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${items[i].percentage.toStringAsFixed(1)}%',
                          style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(items.length, (i) {
          final item = items[i];
          return Padding(
            padding:
                const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors[i].withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconMapper.fromString(item.categoryIcon),
                    size: 18,
                    color: colors[i],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.categoryName,
                          style: AppTypography.bodyMd
                              .copyWith(fontWeight: FontWeight.w500)),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        child: LinearProgressIndicator(
                          value: item.percentage / 100,
                          backgroundColor:
                              colors[i].withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(colors[i]),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatCompact(item.amount),
                      style: AppTypography.bodyMd
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${item.percentage.toStringAsFixed(1)}%',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<Color> _generateColors(int count) {
    const base = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      Color(0xFF7C9EFF),
      Color(0xFF50C8A8),
      Color(0xFFFFD580),
      Color(0xFFF28BCA),
      Color(0xFF95D5F5),
    ];
    return List.generate(count, (i) => base[i % base.length]);
  }
}

// ── Kategori trendleri ─────────────────────────────────────────────────────

class _TrendList extends StatelessWidget {
  const _TrendList({required this.trends});
  final List<TrendItem> trends;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: trends.take(6).map((trend) {
        final isIncrease = trend.isIncrease;
        final color =
            isIncrease ? AppColors.tertiary : AppColors.secondary;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trend.categoryName,
                          style: AppTypography.bodyMd
                              .copyWith(fontWeight: FontWeight.w500)),
                      Text(
                        '${CurrencyFormatter.formatCompact(trend.currentAmount)} (önceki: ${CurrencyFormatter.formatCompact(trend.previousAmount)})',
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isIncrease
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: color,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isIncrease ? '+' : ''}${trend.changePercent.toStringAsFixed(1)}%',
                      style: AppTypography.bodyMd.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Bölüm başlığı ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleSm.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
