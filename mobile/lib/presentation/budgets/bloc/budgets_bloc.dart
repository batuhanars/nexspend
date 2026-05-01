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
