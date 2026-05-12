import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/insight_model.dart';
import '../../../data/repositories/insights_repository.dart';
import 'insights_event.dart';
import 'insights_state.dart';

class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  InsightsBloc({required InsightsRepository insightsRepository})
      : _repo = insightsRepository,
        super(const InsightsInitial()) {
    on<InsightsFetchRequested>(_onFetch);
    on<InsightsSummaryFetchRequested>(_onFetchSummary);
    on<InsightsMarkReadRequested>(_onMarkRead);
    on<InsightsDismissRequested>(_onDismiss);
    on<InsightsGenerateRequested>(_onGenerate);
    on<InsightsMarkAllReadRequested>(_onMarkAllRead);
  }

  final InsightsRepository _repo;
  List<InsightModel> _insights = [];
  String? _currentPeriod;

  // Returns the current list — falls back to the emitted state so that
  // test seeding (which bypasses event handlers) is handled correctly.
  List<InsightModel> _getList() {
    if (_insights.isNotEmpty) return _insights;
    final s = state;
    return switch (s) {
      InsightsLoaded(:final insights) => insights.toList(),
      InsightDismissed(:final insights) => insights.toList(),
      InsightReadMarked(:final insights) => insights.toList(),
      _ => [],
    };
  }

  Future<void> _onFetch(
    InsightsFetchRequested event,
    Emitter<InsightsState> emit,
  ) async {
    emit(const InsightsLoading());
    try {
      final insights = await _repo.getInsights(period: event.period);
      _insights = insights;
      _currentPeriod = event.period;
      emit(InsightsLoaded(insights: insights, period: event.period));
    } catch (e) {
      emit(InsightsError(_parseError(e)));
    }
  }

  Future<void> _onFetchSummary(
    InsightsSummaryFetchRequested event,
    Emitter<InsightsState> emit,
  ) async {
    emit(const InsightsSummaryLoading());
    try {
      final summary = await _repo.getSummary();
      emit(InsightsSummaryLoaded(summary: summary));
    } catch (e) {
      emit(InsightsSummaryError(_parseError(e)));
    }
  }

  Future<void> _onMarkRead(
    InsightsMarkReadRequested event,
    Emitter<InsightsState> emit,
  ) async {
    try {
      final updated = await _repo.markRead(event.insightId);
      final current = _getList();
      _insights = current.map((i) => i.id == event.insightId ? updated : i).toList();
      emit(InsightReadMarked(insights: List.unmodifiable(_insights)));
      emit(InsightsLoaded(insights: List.unmodifiable(_insights), period: _currentPeriod));
    } catch (_) {
      // Silent — read marking is best-effort
    }
  }

  Future<void> _onDismiss(
    InsightsDismissRequested event,
    Emitter<InsightsState> emit,
  ) async {
    final current = _getList(); // Capture before state changes
    emit(InsightDismissing(insightId: event.insightId));
    try {
      await _repo.dismiss(event.insightId);
      _insights = current.where((i) => i.id != event.insightId).toList();
      final remaining = List<InsightModel>.unmodifiable(_insights);
      emit(InsightDismissed(insightId: event.insightId, insights: remaining));
      emit(InsightsLoaded(insights: remaining, period: _currentPeriod));
    } catch (e) {
      emit(InsightsError(_parseError(e)));
    }
  }

  Future<void> _onGenerate(
    InsightsGenerateRequested event,
    Emitter<InsightsState> emit,
  ) async {
    emit(const InsightsGenerating());
    try {
      final result = await _repo.generate();
      emit(InsightsGenerated(generated: result.generated, period: result.period));
    } catch (e) {
      emit(InsightsGenerateError(_parseError(e)));
    }
  }

  Future<void> _onMarkAllRead(
    InsightsMarkAllReadRequested event,
    Emitter<InsightsState> emit,
  ) async {
    final list = _getList();
    final unreadIds = list.where((i) => !i.isRead).map((i) => i.id).toList();
    _insights = list;
    for (final id in unreadIds) {
      try {
        final updated = await _repo.markRead(id);
        _insights = _insights.map((i) => i.id == id ? updated : i).toList();
      } catch (_) {
        // Skip on individual failure
      }
    }
    final all = List<InsightModel>.unmodifiable(_insights);
    emit(InsightReadMarked(insights: all));
    emit(InsightsLoaded(insights: all, period: _currentPeriod));
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException')) return 'İnternet bağlantınızı kontrol edin.';
    if (msg.contains('401')) return 'Oturum süreniz dolmuş.';
    if (msg.contains('404')) return 'Öneri bulunamadı.';
    return 'Öneriler yüklenemedi.';
  }
}
