import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/data/models/debt_model.dart';
import 'summary_card.dart';

// ── Özet kartları ──────────────────────────────────────────────────────────

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.summary});
  final DebtSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: SummaryCard(
              label: 'Alacaklarım',
              total: summary.totalLent,
              remaining: summary.totalLentRemaining,
              color: AppColors.secondary,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SummaryCard(
              label: 'Borçlarım',
              total: summary.totalBorrowed,
              remaining: summary.totalBorrowedRemaining,
              color: AppColors.tertiary,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
