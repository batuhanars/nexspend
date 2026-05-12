import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event.dart';
import '../bloc/family_state.dart';
import '../widgets/contribution_bar.dart';

class ContributionReportPage extends StatefulWidget {
  const ContributionReportPage({
    super.key,
    required this.groupId,
    this.initialPeriod,
  });

  final String groupId;
  final String? initialPeriod;

  @override
  State<ContributionReportPage> createState() =>
      _ContributionReportPageState();
}

class _ContributionReportPageState extends State<ContributionReportPage> {
  late String _period;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _period = widget.initialPeriod ??
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _fetch();
  }

  void _fetch() {
    context.read<FamilyBloc>().add(FamilyContributionsLoadRequested(
          groupId: widget.groupId,
          period: _period,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: const Text('Katkı Raporu'),
        titleTextStyle: AppTypography.headlineSm,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => _showPeriodPicker(context),
            tooltip: 'Dönem Seç',
          ),
        ],
      ),
      body: BlocBuilder<FamilyBloc, FamilyState>(
        builder: (context, state) {
          return switch (state) {
            FamilyContributionsLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            FamilyContributionsLoaded(:final report) => RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainerHigh,
                onRefresh: () async => _fetch(),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  children: [
                    Row(
                      children: [
                        Text('DÖNEM', style: AppTypography.labelSm),
                        const SizedBox(width: AppSpacing.sm),
                        Text(report.period,
                            style: AppTypography.labelSm
                                .copyWith(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (report.members.isEmpty)
                      Center(
                        child: Text(
                          'Bu dönem için katkı verisi yok.',
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant),
                        ),
                      )
                    else
                      ...report.members.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xl),
                              child: ContributionBar(
                                member: entry.value,
                                colorIndex: entry.key,
                                expanded: true,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            FamilyContributionsError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message,
                        style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: _fetch,
                      child: Text('Tekrar Dene',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            _ => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          };
        },
      ),
    );
  }

  void _showPeriodPicker(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final dt = DateTime(now.year, now.month - i);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
    });

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                AppSpacing.lg,
              ),
              child: Text('Dönem Seç', style: AppTypography.titleSm),
            ),
            ...months.map(
              (period) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding),
                title: Text(period, style: AppTypography.bodyMd),
                trailing: _period == period
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 20)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _period = period);
                  _fetch();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
