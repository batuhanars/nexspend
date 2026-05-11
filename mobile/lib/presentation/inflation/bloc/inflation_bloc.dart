import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/inflation_model.dart';
import '../../../data/repositories/inflation_repository.dart';
import 'inflation_event.dart';
import 'inflation_state.dart';

class InflationBloc extends Bloc<InflationEvent, InflationState> {
  InflationBloc({required InflationRepository inflationRepository})
      : _repo = inflationRepository,
        super(const InflationInitial()) {
    on<InflationSuggestionsFetchRequested>(_onFetchSuggestions);
    on<InflationApplyRequested>(_onApply);
    on<InflationReportFetchRequested>(_onFetchReport);
  }

  final InflationRepository _repo;

  Future<void> _onFetchSuggestions(
    InflationSuggestionsFetchRequested event,
    Emitter<InflationState> emit,
  ) async {
    if (event.budgetIds.isEmpty) {
      emit(const InflationSuggestionsLoaded(suggestions: {}));
      return;
    }
    emit(const InflationSuggestionsLoading());
    try {
      final entries = await Future.wait(
        event.budgetIds.map((id) async {
          final suggestion = await _repo.getSuggestion(id);
          return MapEntry(id, suggestion);
        }),
      );
      emit(InflationSuggestionsLoaded(suggestions: Map.fromEntries(entries)));
    } catch (e) {
      emit(InflationSuggestionsError(_parseError(e)));
    }
  }

  Future<void> _onApply(
    InflationApplyRequested event,
    Emitter<InflationState> emit,
  ) async {
    emit(InflationApplying(budgetId: event.budgetId));
    try {
      await _repo.applyInflation(event.budgetId, event.newAmount);
      emit(InflationApplied(budgetId: event.budgetId));
    } catch (e) {
      emit(InflationApplyError(_parseError(e)));
    }
  }

  Future<void> _onFetchReport(
    InflationReportFetchRequested event,
    Emitter<InflationState> emit,
  ) async {
    emit(const InflationReportLoading());
    try {
      final results = await Future.wait([
        _repo.getComparison(period: event.period),
        _repo.getHistory(months: event.months),
      ]);
      emit(InflationReportLoaded(
        comparison: results[0] as InflationComparisonModel,
        history: results[1] as Map<String, List<InflationRateModel>>,
      ));
    } catch (e) {
      emit(InflationReportError(_parseError(e)));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException')) return 'İnternet bağlantınızı kontrol edin.';
    if (msg.contains('404')) return 'Bütçe bulunamadı.';
    if (msg.contains('422')) return 'Bu kategori için enflasyon verisi yok.';
    return 'Enflasyon verisi yüklenemedi.';
  }
}
