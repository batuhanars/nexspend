import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/repositories/subscription_repository.dart';

part 'subscriptions_event.dart';
part 'subscriptions_state.dart';

class SubscriptionsBloc extends Bloc<SubscriptionsEvent, SubscriptionsState> {
  SubscriptionsBloc({required SubscriptionRepository subscriptionRepository})
      : _repo = subscriptionRepository,
        super(SubscriptionsInitial()) {
    on<SubscriptionsLoadRequested>(_onLoad);
    on<SubscriptionsRefreshRequested>(_onRefresh);
    on<SubscriptionToggleRequested>(_onToggle);
    on<SubscriptionDeleteRequested>(_onDelete);
    on<SubscriptionCreated>(_onCreate);
    on<SubscriptionUpdateRequested>(_onUpdate);
  }

  final SubscriptionRepository _repo;

  Future<void> _onLoad(
      SubscriptionsLoadRequested event, Emitter<SubscriptionsState> emit) async {
    emit(SubscriptionsLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
      SubscriptionsRefreshRequested event, Emitter<SubscriptionsState> emit) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<SubscriptionsState> emit) async {
    try {
      final results = await Future.wait([
        _repo.getAll(),
        _repo.getSummary(),
      ]);
      emit(SubscriptionsLoaded(
        subscriptions: results[0] as List<SubscriptionModel>,
        summary: results[1] as SubscriptionSummaryModel,
      ));
    } catch (e) {
      emit(SubscriptionsError(_parseError(e)));
    }
  }

  Future<void> _onToggle(
      SubscriptionToggleRequested event, Emitter<SubscriptionsState> emit) async {
    final current = state;
    if (current is! SubscriptionsLoaded) return;
    // Optimistic update
    final updated = current.subscriptions.map((s) {
      if (s.id == event.id) {
        return SubscriptionModel(
          id: s.id,
          name: s.name,
          amount: s.amount,
          billingCycle: s.billingCycle,
          isActive: !s.isActive,
          autoDeduct: s.autoDeduct,
          description: s.description,
          icon: s.icon,
          color: s.color,
          accountId: s.accountId,
          accountName: s.accountName,
          nextRenewalDate: s.nextRenewalDate,
          categoryId: s.categoryId,
          categoryName: s.categoryName,
        );
      }
      return s;
    }).toList();
    emit(current.copyWith(subscriptions: updated));
    try {
      await _repo.toggle(event.id);
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _onDelete(
      SubscriptionDeleteRequested event, Emitter<SubscriptionsState> emit) async {
    final current = state;
    if (current is SubscriptionsLoaded) {
      final updated =
          current.subscriptions.where((s) => s.id != event.id).toList();
      emit(current.copyWith(subscriptions: updated));
    }
    try {
      await _repo.delete(event.id);
    } catch (_) {
      if (current is SubscriptionsLoaded) emit(current);
    }
  }

  Future<void> _onCreate(
      SubscriptionCreated event, Emitter<SubscriptionsState> emit) async {
    try {
      await _repo.create(event.data);
      await _fetch(emit);
    } catch (e) {
      emit(SubscriptionsError(_parseError(e)));
    }
  }

  Future<void> _onUpdate(
      SubscriptionUpdateRequested event, Emitter<SubscriptionsState> emit) async {
    final current = state;
    if (current is! SubscriptionsLoaded) return;
    final updated = current.subscriptions.map((s) {
      if (s.id == event.id) return s.copyWith(name: event.name, amount: event.amount);
      return s;
    }).toList();
    emit(current.copyWith(subscriptions: updated));
    try {
      await _repo.update(event.id, {'name': event.name, 'amount': event.amount});
    } catch (_) {
      emit(current);
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException')) return 'İnternet bağlantınızı kontrol edin.';
    return 'Veriler yüklenemedi.';
  }
}
