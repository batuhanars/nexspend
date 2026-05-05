import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../shared/widgets/shimmer_box.dart';

class SubscriptionsShimmer extends StatelessWidget {
  const SubscriptionsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerHighest,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.md,
            ),
            child: ShimmerBox(height: 100),
          ),
          ...List.generate(4, (_) => _subscriptionCard()),
        ],
      ),
    );
  }

  Widget _subscriptionCard() => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.xs,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              const ShimmerBox(
                height: 44,
                width: 44,
                radius: AppSpacing.radiusMd,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(height: 13, width: 100),
                    SizedBox(height: 6),
                    ShimmerBox(height: 10, width: 70),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  ShimmerBox(height: 13, width: 60),
                  SizedBox(height: 6),
                  ShimmerBox(height: 20, width: 40, radius: AppSpacing.radiusSm),
                ],
              ),
            ],
          ),
        ),
      );
}
