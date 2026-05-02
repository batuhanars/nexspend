import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/category_model.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });
  final List<CategoryModel> categories;
  final CategoryModel? selected;
  final ValueChanged<CategoryModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: categories.map((cat) {
        final isSelected = selected?.id == cat.id;
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.cardColor.withValues(alpha: 0.2)
                  : AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected
                    ? cat.cardColor
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconMapper.fromString(cat.icon),
                  size: 16,
                  color: isSelected ? cat.cardColor : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  cat.name,
                  style: AppTypography.bodySm.copyWith(
                    color: isSelected ? cat.cardColor : AppColors.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
