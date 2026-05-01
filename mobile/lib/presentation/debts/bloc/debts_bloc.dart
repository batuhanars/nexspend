import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/repositories/debt_repository.dart';

part 'debts_event.dart';
part 'debts_state.dart';

class DebtsBloc extends Bloc<DebtsEvent, DebtsState> {
  DebtsBloc({required DebtRepository debtRepository})
      : _repo = debtRepository,
        super(DebtsInitial()) {
    on<DebtsLoadRequested>(_onLoad);
    on<DebtsRefreshRequested>(_onRefresh);
    on<DebtsFilterChanged>(_onFilterChanged);
    on<DebtDeleteRequested>(_onDelete);
    on<DebtCreated>(_onCreate);
    on<DebtPaymentRecorded>(_onPayment);
  }

  final DebtRepository _repo;
  String? _activeFilter;

  Future<void> _onLoad(DebtsLoadRequested event, Emitter<DebtsState> emit) async {
    emit(DebtsLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
      DebtsRefreshRequested event, Emitter<DebtsState> emit) async {
    await _fetch(emit);
  }

  Future<void> _onFilterChanged(
      DebtsFilterChanged event, Emitter<DebtsState> emit) async {
    _activeFilter = event.filter;
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<DebtsState> emit) async {
    try {
      final results = await Future.wait([
        _repo.getAll(type: _activeFilter),
        _repo.getSummary(),
      ]);
      emit(DebtsLoaded(
        debts: results[0] as List<DebtModel>,
        summary: results[1] as DebtSummaryModel,
        filter: _activeFilter,
      ));
    } catch (e) {
      emit(DebtsError(_parseError(e)));
    }
  }

  Future<void> _onDelete(
      DebtDeleteRequested event, Emitter<DebtsState> emit) async {
    final current = state;
    if (current is! DebtsLoaded) return;
    final updated = current.debts.where((d) => d.id != event.id).toList();
    emit(current.copyWith(debts: updated));
    try {
      await _repo.delete(event.id);
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _onCreate(
      DebtCreated event, Emitter<DebtsState> emit) async {
    try {
      await _repo.create(event.data);
      await _fetch(emit);
    } catch (e) {
      emit(DebtsError(_parseError(e)));
    }
  }

  Future<void> _onPayment(
      DebtPaymentRecorded event, Emitter<DebtsState> emit) async {
    try {
      await _repo.recordPayment(event.debtId, event.data);
      await _fetch(emit);
    } catch (e) {
      emit(DebtsError(_parseError(e)));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException')) return 'İnternet bağlantınızı kontrol edin.';
    return 'Veriler yüklenemedi.';
  }
}
