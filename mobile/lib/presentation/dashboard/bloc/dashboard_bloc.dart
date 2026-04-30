import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/repositories/dashboard_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required DashboardRepository dashboardRepository})
      : _repo = dashboardRepository,
        super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  final DashboardRepository _repo;

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<DashboardState> emit) async {
    try {
      final dashboard = await _repo.getDashboard();
      emit(DashboardLoaded(dashboard));
    } catch (e) {
      emit(DashboardError(_parseError(e)));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    if (msg.contains('401')) return 'Oturum süreniz doldu. Tekrar giriş yapın.';
    return 'Veriler yüklenemedi. Lütfen tekrar deneyin.';
  }
}
