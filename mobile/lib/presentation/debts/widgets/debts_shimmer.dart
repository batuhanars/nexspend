import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../shared/widgets/shimmer_box.dart';

class DebtsShimmer extends StatelessWidget {
  const DebtsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerHighest,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                const Expanded(child: ShimmerBox(height: 80)),
                const SizedBox(width: AppSpacing.md),
                const Expanded(child: ShimmerBox(height: 80)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const ShimmerBox(height: 32, width: 64),
                const SizedBox(width: AppSpacing.sm),
                const ShimmerBox(height: 32, width: 72),
                const SizedBox(width: AppSpacing.sm),
                const ShimmerBox(height: 32, width: 56),
                const SizedBox(width: AppSpacing.sm),
                const ShimmerBox(height: 32, width: 68),
              ],
            ),
          ),
          ...List.generate(3, (_) => _debtCard()),
        ],
      ),
    );
  }

  Widget _debtCard() => Padding(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerBox(height: 36, width: 36, shape: BoxShape.circle),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(height: 13, width: 100),
                        SizedBox(height: 5),
                        ShimmerBox(height: 10, width: 70),
                      ],
                    ),
                  ),
                  const ShimmerBox(height: 13, width: 72),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const ShimmerBox(height: 6),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ShimmerBox(height: 10, width: 70),
                  ShimmerBox(height: 10, width: 90),
                ],
              ),
            ],
          ),
        ),
      );
}
