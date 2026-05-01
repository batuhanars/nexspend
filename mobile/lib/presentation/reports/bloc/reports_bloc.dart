import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

part 'reports_event.dart';
part 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({required ReportRepository reportRepository})
      : _repo = reportRepository,
        super(ReportsInitial()) {
    on<ReportsLoadRequested>(_onLoad);
    on<ReportsPeriodChanged>(_onPeriodChanged);
  }

  final ReportRepository _repo;
  String _period = 'THIS_MONTH';

  Future<void> _onLoad(
      ReportsLoadRequested event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    await _fetch(emit);
  }

  Future<void> _onPeriodChanged(
      ReportsPeriodChanged event, Emitter<ReportsState> emit) async {
    _period = event.period;
    emit(ReportsLoading());
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<ReportsState> emit) async {
    try {
      final results = await Future.wait([
        _repo.getExpenseDistribution(period: _period),
        _repo.getCashFlow(period: _period),
        _repo.getTrends(period: _period),
      ]);
      emit(ReportsLoaded(
        distribution: results[0] as List<ExpenseDistributionItem>,
        cashFlow: results[1] as List<CashFlowItem>,
        trends: results[2] as List<TrendItem>,
        period: _period,
      ));
    } catch (e) {
      emit(ReportsError(_parseError(e)));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException')) return 'İnternet bağlantınızı kontrol edin.';
    return 'Raporlar yüklenemedi.';
  }
}
