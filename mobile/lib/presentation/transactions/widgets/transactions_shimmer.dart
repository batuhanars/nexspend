import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

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
          // Summary row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(child: _box(height: 72)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _box(height: 72)),
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
                _box(height: 32, width: 72),
                const SizedBox(width: AppSpacing.sm),
                _box(height: 32, width: 60),
                const SizedBox(width: AppSpacing.sm),
                _box(height: 32, width: 56),
              ],
            ),
          ),
          // Date header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, AppSpacing.md, 0, AppSpacing.sm),
            child: _box(height: 12, width: 100),
          ),
          // Transaction rows
          ...List.generate(5, (_) => _row()),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, 0, 0, AppSpacing.sm),
            child: _box(height: 12, width: 80),
          ),
          ...List.generate(3, (_) => _row()),
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
                    _box(height: 13, width: 110),
                    const SizedBox(height: 5),
                    _box(height: 10, width: 70),
                  ],
                ),
              ),
              _box(height: 13, width: 60),
            ],
          ),
        ),
      );
}
