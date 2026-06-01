import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_palette.dart';

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHigh,
      highlightColor: colors.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            height: 160,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                4,
                (_) => Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              itemCount: 3,
              separatorBuilder: (_, index) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, index) => Container(
                width: 200,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 80,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 14,
                    width: 70,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
