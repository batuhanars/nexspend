part of 'subscriptions_bloc.dart';

sealed class SubscriptionsEvent {
  const SubscriptionsEvent();
}

class SubscriptionsLoadRequested extends SubscriptionsEvent {
  const SubscriptionsLoadRequested();
}

class SubscriptionsRefreshRequested extends SubscriptionsEvent {
  const SubscriptionsRefreshRequested();
}

class SubscriptionToggleRequested extends SubscriptionsEvent {
  const SubscriptionToggleRequested(this.id);
  final String id;
}

class SubscriptionDeleteRequested extends SubscriptionsEvent {
  const SubscriptionDeleteRequested(this.id);
  final String id;
}

class SubscriptionCreated extends SubscriptionsEvent {
  const SubscriptionCreated(this.data);
  final Map<String, dynamic> data;
}

class SubscriptionUpdateRequested extends SubscriptionsEvent {
  const SubscriptionUpdateRequested({
    required this.id,
    required this.name,
    required this.amount,
  });
  final String id;
  final String name;
  final double amount;
}

class SubscriptionPayRequested extends SubscriptionsEvent {
  const SubscriptionPayRequested({
    required this.id,
    required this.amount,
    this.paidDate,
  });
  final String id;
  final double amount;
  final String? paidDate;
}
