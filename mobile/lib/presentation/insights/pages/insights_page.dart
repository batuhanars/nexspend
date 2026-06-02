import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/insights_repository.dart';
import '../bloc/insights_bloc.dart';
import '../bloc/insights_event.dart';
import '../bloc/insights_state.dart';
import '../widgets/insight_card.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InsightsBloc(
        insightsRepository: getIt<InsightsRepository>(),
      )..add(const InsightsFetchRequested()),
      child: const _InsightsView(),
    );
  }
}

class _InsightsView extends StatefulWidget {
  const _InsightsView();

  @override
  State<_InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<_InsightsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String _periodForIndex(int index) {
    final now = DateTime.now();
    if (index == 0) {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }
    final prev = DateTime(now.year, now.month - 1);
    return '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      context.read<InsightsBloc>().add(
            InsightsFetchRequested(period: _periodForIndex(_tabController.index)),
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Akıllı Öneriler'),
        titleTextStyle: AppTypography.headlineSm.copyWith(color: colors.onSurface),
        iconTheme: IconThemeData(color: colors.onSurface),
        actions: [
          BlocBuilder<InsightsBloc, InsightsState>(
            buildWhen: (prev, curr) =>
                curr is InsightsLoaded || curr is InsightReadMarked,
            builder: (context, state) {
              final hasUnread = state is InsightsLoaded &&
                  state.insights.any((i) => !i.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  context.read<InsightsBloc>().add(const InsightsMarkAllReadRequested());
                },
                child: Text(
                  'Tümünü Okundu İşaretle',
                  style: AppTypography.bodySm.copyWith(color: colors.primary),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          indicatorColor: colors.primary,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: AppStrings.of(context).periodThisMonth),
            Tab(text: AppStrings.of(context).tabLastMonth),
          ],
        ),
      ),
      body: BlocBuilder<InsightsBloc, InsightsState>(
        builder: (context, state) {
          return switch (state) {
            InsightsLoading() => const _LoadingView(),
            InsightsError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<InsightsBloc>().add(
                      InsightsFetchRequested(
                          period: _periodForIndex(_tabController.index)),
                    ),
              ),
            InsightsLoaded(:final insights) ||
            InsightDismissed(insights: final insights) ||
            InsightReadMarked(insights: final insights) =>
              insights.isEmpty
                  ? const _EmptyView()
                  : _InsightsList(
                      insights: insights,
                      onDismiss: (id) => context
                          .read<InsightsBloc>()
                          .add(InsightsDismissRequested(insightId: id)),
                      onMarkRead: (id) => context
                          .read<InsightsBloc>()
                          .add(InsightsMarkReadRequested(insightId: id)),
                    ),
            _ => const _LoadingView(),
          };
        },
      ),
    );
  }
}

class _InsightsList extends StatelessWidget {
  const _InsightsList({
    required this.insights,
    required this.onDismiss,
    required this.onMarkRead,
  });

  final List insights;
  final void Function(String id) onDismiss;
  final void Function(String id) onMarkRead;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: insights.length,
      separatorBuilder: (context, i) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final insight = insights[index];
        return GestureDetector(
          onTap: () {
            if (!insight.isRead) onMarkRead(insight.id);
          },
          child: InsightCard(
            insight: insight,
            onDismiss: () => onDismiss(insight.id),
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: colors.success),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Harika! Hiç öneriniz yok 🎉',
              style: AppTypography.titleSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bu dönem için finansal öneriniz bulunmuyor.',
              style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: 4,
      separatorBuilder: (context, i) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(message,
                style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onRetry,
              child: Text('Tekrar Dene',
                  style: AppTypography.bodyMd.copyWith(color: colors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
