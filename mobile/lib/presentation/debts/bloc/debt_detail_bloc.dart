import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/repositories/debt_repository.dart';

part 'debt_detail_event.dart';
part 'debt_detail_state.dart';

class DebtDetailBloc extends Bloc<DebtDetailEvent, DebtDetailState> {
  DebtDetailBloc({required DebtRepository debtRepository})
      : _repo = debtRepository,
        super(DebtDetailInitial()) {
    on<DebtDetailLoadRequested>(_onLoad);
    on<DebtDetailRefreshRequested>(_onRefresh);
    on<DebtDetailPaymentMade>(_onPayment);
  }

  final DebtRepository _repo;
  DebtModel? _debt;

  Future<void> _onLoad(
      DebtDetailLoadRequested event, Emitter<DebtDetailState> emit) async {
    _debt = event.debt;
    emit(DebtDetailLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
      DebtDetailRefreshRequested event, Emitter<DebtDetailState> emit) async {
    await _fetch(emit);
  }

  Future<void> _onPayment(
      DebtDetailPaymentMade event, Emitter<DebtDetailState> emit) async {
    final current = state;
    if (current is! DebtDetailLoaded) return;
    try {
      await _repo.recordPayment(_debt!.id, event.data);
      await _fetch(emit);
    } catch (e) {
      emit(DebtDetailError(_parseError(e)));
      emit(current);
    }
  }

  Future<void> _fetch(Emitter<DebtDetailState> emit) async {
    final debtId = _debt!.id;
    try {
      final results = await Future.wait([
        _repo.getInstallments(debtId),
        _repo.getPayments(debtId),
      ]);
      emit(DebtDetailLoaded(
        debt: _debt!,
        installments: results[0] as List<DebtInstallmentModel>,
        payments: results[1] as List<DebtPaymentModel>,
      ));
    } catch (e) {
      emit(DebtDetailError(_parseError(e)));
    }
  }

  String _parseError(Object e) {
    if (e.toString().contains('SocketException')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    return 'Veriler yüklenemedi.';
  }
}
