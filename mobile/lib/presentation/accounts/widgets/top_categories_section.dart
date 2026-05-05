import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_analytics_model.dart';

class TopCategoriesSection extends StatelessWidget {
  const TopCategoriesSection({super.key, required this.categories});
  final List<CategoryBreakdownModel> categories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bu Ay En Çok Harcanan', style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.md),
          ...categories.map((cat) => CategoryBreakdownRow(category: cat)),
        ],
      ),
    );
  }
}

class CategoryBreakdownRow extends StatelessWidget {
  const CategoryBreakdownRow({super.key, required this.category});
  final CategoryBreakdownModel category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: category.cardColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(category.iconData, size: 18, color: category.cardColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(category.name, style: AppTypography.bodyMd)),
          Text(
            CurrencyFormatter.format(category.amount),
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
