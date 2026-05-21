import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/repositories/budget_repository.dart';
import 'budgets_event.dart';
import 'budgets_state.dart';

class BudgetsBloc extends Bloc<BudgetsEvent, BudgetsState> {
  BudgetsBloc({required BudgetRepository budgetRepository})
      : _repo = budgetRepository,
        super(BudgetsInitial()) {
    on<BudgetsLoadRequested>(_onLoad);
    on<BudgetsRefreshRequested>(_onRefresh);
    on<BudgetDeleteRequested>(_onDelete);
    on<BudgetUpdateRequested>(_onUpdate);
  }

  final BudgetRepository _repo;

  Future<void> _onLoad(
      BudgetsLoadRequested event, Emitter<BudgetsState> emit) async {
    emit(BudgetsLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
      BudgetsRefreshRequested event, Emitter<BudgetsState> emit) async {
    await _fetch(emit);
  }

  Future<void> _onDelete(
      BudgetDeleteRequested event, Emitter<BudgetsState> emit) async {
    final current = state;
    try {
      await _repo.delete(event.id);
      if (current is BudgetsLoaded) {
        final budgets =
            current.budgets.where((b) => b.id != event.id).toList();
        final totalBudget = budgets.fold(0.0, (s, b) => s + b.amount);
        final totalSpent = budgets.fold(0.0, (s, b) => s + b.spent);
        final percentage = totalBudget > 0
            ? ((totalSpent / totalBudget) * 100).round()
            : 0;
        emit(BudgetsLoaded(
          overview: BudgetOverviewModel(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            remaining: totalBudget - totalSpent,
            percentage: percentage,
            count: budgets.length,
          ),
          budgets: budgets,
        ));
      }
    } catch (_) {
      // Keep current state on delete error
    }
  }

  Future<void> _onUpdate(
      BudgetUpdateRequested event, Emitter<BudgetsState> emit) async {
    final current = state;
    if (current is BudgetsLoaded) {
      final name = event.data['name'] as String?;
      final amount = (event.data['amount'] as num?)?.toDouble();
      final periodStr = event.data['period'] as String?;
      final period = periodStr != null
          ? BudgetPeriod.values.firstWhere((p) => p.name == periodStr, orElse: () => BudgetPeriod.MONTHLY)
          : null;
      final smartTracking = event.data['smartTracking'] as bool?;
      final hasEndDate = event.data.containsKey('endDate');
      final endDateStr = event.data['endDate'] as String?;

      final optimistic = current.budgets.map((b) {
        if (b.id != event.id) return b;
        final newAmount = amount ?? b.amount;
        final newRemaining = newAmount - b.spent;
        final newPct = newAmount > 0 ? ((b.spent / newAmount) * 100).round() : 0;
        return BudgetModel(
          id: b.id,
          name: name ?? b.name,
          amount: newAmount,
          spent: b.spent,
          remaining: newRemaining,
          percentage: newPct,
          status: _statusForPct(newPct),
          period: period ?? b.period,
          smartTracking: smartTracking ?? b.smartTracking,
          isActive: b.isActive,
          startDate: b.startDate,
          endDate: hasEndDate ? (endDateStr != null ? DateTime.parse(endDateStr) : b.endDate) : b.endDate,
          category: b.category,
        );
      }).toList();
      emit(BudgetsLoaded(overview: current.overview, budgets: optimistic));
    }
    try {
      await _repo.update(event.id, event.data);
      await _fetch(emit);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        final msg = (e.response?.data?['message'] as String?) ??
            'Bütçe güncellenemedi';
        if (current is BudgetsLoaded) {
          emit(BudgetsUpdateError(
            message: msg,
            budgets: current.budgets,
            overview: current.overview,
          ));
        }
      } else {
        if (current is BudgetsLoaded) emit(current);
      }
    }
  }

  BudgetStatus _statusForPct(int pct) {
    if (pct >= 100) return BudgetStatus.EXCEEDED;
    if (pct >= 90) return BudgetStatus.CRITICAL;
    if (pct >= 75) return BudgetStatus.WARNING;
    return BudgetStatus.OK;
  }

  Future<void> _fetch(Emitter<BudgetsState> emit) async {
    try {
      final overviewFuture = _repo.getOverview();
      final budgetsFuture = _repo.getAll();
      final overview = await overviewFuture;
      final budgets = await budgetsFuture;
      emit(BudgetsLoaded(overview: overview, budgets: budgets));
    } catch (_) {
      emit(BudgetsError('Bütçeler yüklenemedi'));
    }
  }
}
