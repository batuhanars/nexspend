part of 'subscriptions_bloc.dart';

sealed class SubscriptionsState {}

class SubscriptionsInitial extends SubscriptionsState {}

class SubscriptionsLoading extends SubscriptionsState {}

class SubscriptionsLoaded extends SubscriptionsState {
  SubscriptionsLoaded({
    required this.subscriptions,
    required this.summary,
  });

  final List<SubscriptionModel> subscriptions;
  final SubscriptionSummaryModel summary;

  List<SubscriptionModel> get activeSubscriptions =>
      subscriptions.where((s) => s.isActive).toList();
  List<SubscriptionModel> get upcomingRenewals =>
      subscriptions.where((s) => s.isActive && s.isRenewingSoon).toList();

  SubscriptionsLoaded copyWith({
    List<SubscriptionModel>? subscriptions,
    SubscriptionSummaryModel? summary,
  }) =>
      SubscriptionsLoaded(
        subscriptions: subscriptions ?? this.subscriptions,
        summary: summary ?? this.summary,
      );
}

class SubscriptionsError extends SubscriptionsState {
  SubscriptionsError(this.message);
  final String message;
}
