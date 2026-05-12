import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/insights_repository.dart';
import '../../../navigation/route_names.dart';
import '../../insights/bloc/insights_bloc.dart';
import '../../insights/bloc/insights_event.dart';
import '../../insights/bloc/insights_state.dart';
import '../../insights/widgets/insight_card.dart';

class InsightsCarousel extends StatelessWidget {
  const InsightsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InsightsBloc(
        insightsRepository: getIt<InsightsRepository>(),
      )..add(const InsightsFetchRequested()),
      child: const _InsightsCarouselView(),
    );
  }
}

class _InsightsCarouselView extends StatelessWidget {
  const _InsightsCarouselView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsightsBloc, InsightsState>(
      builder: (context, state) {
        return switch (state) {
          InsightsLoading() || InsightsInitial() => const _CarouselShimmer(),
          InsightsLoaded(:final insights) => _buildContent(context, insights,
              unreadCount: insights.where((i) => !i.isRead).length),
          InsightDismissed(:final insights) => _buildContent(context, insights,
              unreadCount: insights.where((i) => !i.isRead).length),
          InsightReadMarked(:final insights) => _buildContent(context, insights,
              unreadCount: insights.where((i) => !i.isRead).length),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List insights, {
    required int unreadCount,
  }) {
    final preview = insights.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('AKILLI ÖNERİLER', style: AppTypography.labelSm),
              const SizedBox(width: AppSpacing.sm),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.onTertiary),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(RouteNames.insights),
                child: Row(
                  children: [
                    Text(
                      'Tümü',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (preview.isEmpty)
            _EmptyCarousel()
          else
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: preview.length,
                separatorBuilder: (context, i) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final insight = preview[index];
                  return SizedBox(
                    width: 260,
                    child: InsightCard(
                      insight: insight,
                      compact: true,
                      onDismiss: () {
                        context.read<InsightsBloc>().add(
                              InsightsDismissRequested(
                                  insightId: insight.id),
                            );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Text(
        'Harika! Hiç öneriniz yok 🎉',
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CarouselShimmer extends StatelessWidget {
  const _CarouselShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}
