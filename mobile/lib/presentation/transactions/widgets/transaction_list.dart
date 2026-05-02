import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/transaction_model.dart';
import 'transaction_tile.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key, required this.grouped});
  final Map<String, List<TransactionModel>> grouped;

  @override
  Widget build(BuildContext context) {
    final entries = grouped.entries.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = entries[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.lg,
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                ),
                child: Text(
                  entry.key,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...entry.value.map(
                (t) => TransactionTile(transaction: t),
              ),
            ],
          );
        },
        childCount: entries.length,
      ),
    );
  }
}
