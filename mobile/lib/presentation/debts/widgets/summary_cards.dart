import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/data/models/debt_model.dart';
import 'package:wallet_app/presentation/debts/bloc/debts_bloc.dart';
import 'summary_card.dart';

// ── Özet kartları ──────────────────────────────────────────────────────────

class SummaryCards extends StatelessWidget {
  const SummaryCards({
    super.key,
    required this.summary,
    required this.activeFilter,
  });
  final DebtSummaryModel summary;
  final String? activeFilter;

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
              label: AppStrings.of(context).summaryLent,
              total: summary.totalLent,
              remaining: summary.totalLentRemaining,
              color: AppColors.secondary,
              icon: Icons.arrow_downward_rounded,
              isActive: activeFilter == 'LENT',
              onTap: () => context.read<DebtsBloc>().add(
                    DebtsFilterChanged(
                      activeFilter == 'LENT' ? null : 'LENT',
                    ),
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SummaryCard(
              label: AppStrings.of(context).summaryBorrowed,
              total: summary.totalBorrowed,
              remaining: summary.totalBorrowedRemaining,
              color: AppColors.tertiary,
              icon: Icons.arrow_upward_rounded,
              isActive: activeFilter == 'BORROWED',
              onTap: () => context.read<DebtsBloc>().add(
                    DebtsFilterChanged(
                      activeFilter == 'BORROWED' ? null : 'BORROWED',
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
