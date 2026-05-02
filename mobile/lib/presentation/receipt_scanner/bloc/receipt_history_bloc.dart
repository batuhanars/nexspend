import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/receipt_model.dart';
import '../../../data/repositories/receipt_repository.dart';

part 'receipt_history_event.dart';
part 'receipt_history_state.dart';

class ReceiptHistoryBloc
    extends Bloc<ReceiptHistoryEvent, ReceiptHistoryState> {
  ReceiptHistoryBloc({required ReceiptRepository receiptRepository})
      : _repo = receiptRepository,
        super(ReceiptHistoryInitial()) {
    on<ReceiptHistoryLoadRequested>(_onLoad);
    on<ReceiptHistoryRefreshRequested>(_onRefresh);
    on<ReceiptHistoryDeleteRequested>(_onDelete);
  }

  final ReceiptRepository _repo;

  Future<void> _onLoad(
      ReceiptHistoryLoadRequested event,
      Emitter<ReceiptHistoryState> emit) async {
    emit(ReceiptHistoryLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
      ReceiptHistoryRefreshRequested event,
      Emitter<ReceiptHistoryState> emit) async {
    await _fetch(emit);
  }

  Future<void> _onDelete(
      ReceiptHistoryDeleteRequested event,
      Emitter<ReceiptHistoryState> emit) async {
    final current = state;
    if (current is! ReceiptHistoryLoaded) return;
    final updated = current.receipts.where((r) => r.id != event.id).toList();
    emit(ReceiptHistoryLoaded(updated));
    try {
      await _repo.delete(event.id);
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _fetch(Emitter<ReceiptHistoryState> emit) async {
    try {
      final receipts = await _repo.getHistory();
      emit(ReceiptHistoryLoaded(receipts));
    } catch (e) {
      final msg = e.toString().contains('SocketException')
          ? 'İnternet bağlantınızı kontrol edin.'
          : 'Veriler yüklenemedi.';
      emit(ReceiptHistoryError(msg));
    }
  }
}
