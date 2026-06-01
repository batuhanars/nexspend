import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_palette.dart';
import '../../shared/widgets/shimmer_box.dart';

class TransactionsShimmer extends StatelessWidget {
  const TransactionsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHigh,
      highlightColor: colors.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.md,
            ),
            child: const Row(
              children: [
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
            child: const Row(
              children: [
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
          ...List.generate(5, (_) => _row(colors)),
          const SizedBox(height: AppSpacing.md),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, 0, 0, AppSpacing.sm,
            ),
            child: ShimmerBox(height: 12, width: 80),
          ),
          ...List.generate(3, (_) => _row(colors)),
        ],
      ),
    );
  }

  Widget _row(AppPalette colors) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.xs,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: const Row(
            children: [
              ShimmerBox(height: 36, width: 36, shape: BoxShape.circle),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 13, width: 110),
                    SizedBox(height: 5),
                    ShimmerBox(height: 10, width: 70),
                  ],
                ),
              ),
              ShimmerBox(height: 13, width: 60),
            ],
          ),
        ),
      );
}
