import 'package:flutter/material.dart';
import 'package:wallet_app/data/models/subscription_model.dart';
import '../../../core/constants/app_spacing.dart';
import 'subscription_card.dart';

class SubscriptionList extends StatelessWidget {
  const SubscriptionList({super.key, required this.subscriptions});
  final List<SubscriptionModel> subscriptions;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => SubscriptionCard(sub: subscriptions[i]),
          childCount: subscriptions.length,
        ),
      ),
    );
  }
}
