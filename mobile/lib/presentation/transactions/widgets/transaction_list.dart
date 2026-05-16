import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/family_model.dart';
import '../../../data/models/transaction_model.dart';
import 'transaction_tile.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({
    super.key,
    required this.transactions,
    this.personalBudgets = const [],
    this.sharedBudgets = const [],
  });

  final List<TransactionModel> transactions;
  final List<BudgetModel> personalBudgets;
  final List<MySharedBudgetModel> sharedBudgets;

  Map<String, List<TransactionModel>> _group(String locale) {
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    final map = <String, List<TransactionModel>>{};
    for (final t in sorted) {
      final key = DateFormatter.formatGroupHeaderLocalized(t.date, locale);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  /// Transaction'in bagli oldugu butce icin gosterilecek kisa etiket:
  /// - Ortak butce -> "Ev · Market" (grup adi · butce adi)
  /// - Kisisel butce -> "Market" (butce adi)
  /// - Bagsiz -> null (etiket cikmaz)
  String? _budgetLabel(TransactionModel tx) {
    if (tx.type != TransactionType.EXPENSE) return null;

    if (tx.sharedBudgetId != null) {
      final match =
          sharedBudgets.where((b) => b.id == tx.sharedBudgetId).toList();
      if (match.isEmpty) return null;
      final b = match.first;
      return b.groupName.isNotEmpty ? '${b.groupName} · ${b.name}' : b.name;
    }

    final catId = tx.category?.id;
    if (catId == null) return null;
    for (final b in personalBudgets) {
      if (!b.isActive) continue;
      if (b.category?.id != catId) continue;
      if (tx.date.isBefore(b.startDate)) continue;
      if (b.endDate != null && tx.date.isAfter(b.endDate!)) continue;
      return b.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final grouped = _group(locale);
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
                (t) => TransactionTile(
                  transaction: t,
                  budgetLabel: _budgetLabel(t),
                ),
              ),
            ],
          );
        },
        childCount: entries.length,
      ),
    );
  }
}
