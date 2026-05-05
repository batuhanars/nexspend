import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/category_extensions.dart';
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

  static const _previewCount = 8;

  List<CategoryModel> get _previewCategories {
    if (categories.length <= _previewCount) return categories;
    final first = categories.take(_previewCount).toList();
    if (selected == null || first.any((c) => c.id == selected!.id)) return first;
    return [...categories.take(_previewCount - 1), selected!];
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewCategories;
    final hasMore = categories.length > _previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: preview
              .map((cat) => _CategoryChip(
                    category: cat,
                    isSelected: selected?.id == cat.id,
                    onTap: () => onSelect(cat),
                  ))
              .toList(),
        ),
        if (hasMore) ...[
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => _showAll(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '${AppStrings.of(context).viewAll} (${categories.length})',
              style: AppTypography.bodySm.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }

  void _showAll(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding, 0, AppSpacing.pagePadding, AppSpacing.md,
              ),
              child: Text(
                AppStrings.of(context).categoryLabel,
                style: AppTypography.titleSm,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  0,
                  AppSpacing.pagePadding,
                  AppSpacing.xxl,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: categories
                      .map((cat) => _CategoryChip(
                            category: cat,
                            isSelected: selected?.id == cat.id,
                            onTap: () {
                              onSelect(cat);
                              Navigator.of(ctx).pop();
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.cardColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconMapper.fromString(category.icon),
              size: 16,
              color: isSelected ? color : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              category.localizedName(context),
              style: AppTypography.bodySm.copyWith(
                color: isSelected ? color : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
