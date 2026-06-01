import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/inflation_model.dart';

class InflationSuggestionCard extends StatelessWidget {
  const InflationSuggestionCard({
    super.key,
    required this.suggestion,
    required this.budgetName,
    required this.isApplying,
    required this.onApply,
  });

  final InflationSuggestionModel suggestion;
  final String budgetName;
  final bool isApplying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final increase = suggestion.suggestedAmount - suggestion.currentAmount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'ENFLASYON ÖNERİSİ',
                  style: AppTypography.labelSm.copyWith(
                    color: colors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.trending_up_rounded, size: 16,
                  color: colors.primary.withValues(alpha: 0.7)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(budgetName, style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Son ${suggestion.monthsSinceUpdate} ayda %${suggestion.cumulativeRate.toStringAsFixed(1)} kümülatif enflasyon',
            style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _AmountCell(
                label: 'Mevcut',
                amount: suggestion.currentAmount,
                color: colors.onSurfaceVariant,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: colors.onSurfaceVariant),
              ),
              _AmountCell(
                label: 'Önerilen',
                amount: suggestion.suggestedAmount,
                color: colors.primary,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.expense.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '+${CurrencyFormatter.formatNoDecimal(increase)}',
                  style: AppTypography.labelSm.copyWith(
                    color: colors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton(
              onPressed: isApplying ? null : onApply,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: isApplying
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Text(
                      'Bütçeyi Güncelle  ${CurrencyFormatter.format(suggestion.suggestedAmount)}\'ye',
                      style: AppTypography.bodySm.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  const _AmountCell({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: context.colors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(CurrencyFormatter.format(amount), style: AppTypography.titleSm.copyWith(color: color)),
      ],
    );
  }
}
