import 'package:flutter/material.dart';
import 'package:wallet_app/data/models/debt_model.dart';
import 'package:wallet_app/presentation/debts/widgets/debt_card.dart';

class DebtList extends StatelessWidget {
  const DebtList({super.key, required this.debts});
  final List<DebtModel> debts;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => DebtCard(debt: debts[i]),
        childCount: debts.length,
      ),
    );
  }
}
