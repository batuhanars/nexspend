import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../shared/widgets/shimmer_box.dart';

class TransactionsShimmer extends StatelessWidget {
  const TransactionsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: const [
                Expanded(child: ShimmerBox(height: 72)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: ShimmerBox(height: 72)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: const [
                ShimmerBox(height: 32, width: 72),
                SizedBox(width: AppSpacing.sm),
                ShimmerBox(height: 32, width: 60),
                SizedBox(width: AppSpacing.sm),
                ShimmerBox(height: 32, width: 56),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, AppSpacing.md, 0, AppSpacing.sm,
            ),
            child: ShimmerBox(height: 12, width: 100),
          ),
          ...List.generate(5, (_) => _row()),
          const SizedBox(height: AppSpacing.md),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, 0, 0, AppSpacing.sm,
            ),
            child: ShimmerBox(height: 12, width: 80),
          ),
          ...List.generate(3, (_) => _row()),
        ],
      ),
    );
  }

  Widget _row() => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.xs,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              const ShimmerBox(height: 36, width: 36, shape: BoxShape.circle),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(height: 13, width: 110),
                    SizedBox(height: 5),
                    ShimmerBox(height: 10, width: 70),
                  ],
                ),
              ),
              const ShimmerBox(height: 13, width: 60),
            ],
          ),
        ),
      );
}
