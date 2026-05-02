import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class DebtsShimmer extends StatelessWidget {
  const DebtsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerHighest,
      child: Column(
        children: [
          // Summary cards
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(child: _box(height: 80)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _box(height: 80)),
              ],
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _box(height: 32, width: 64),
                const SizedBox(width: AppSpacing.sm),
                _box(height: 32, width: 72),
                const SizedBox(width: AppSpacing.sm),
                _box(height: 32, width: 56),
                const SizedBox(width: AppSpacing.sm),
                _box(height: 32, width: 68),
              ],
            ),
          ),
          // Debt cards with progress bar
          ...List.generate(3, (_) => _debtCard()),
        ],
      ),
    );
  }

  Widget _box({required double height, double? width}) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      );

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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(height: 13, width: 100),
                        const SizedBox(height: 5),
                        _box(height: 10, width: 70),
                      ],
                    ),
                  ),
                  _box(height: 13, width: 72),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _box(height: 6, width: double.infinity),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _box(height: 10, width: 70),
                  _box(height: 10, width: 90),
                ],
              ),
            ],
          ),
        ),
      );
}
