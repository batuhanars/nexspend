import '../../../data/models/budget_model.dart';

sealed class BudgetsState {}

class BudgetsInitial extends BudgetsState {}

class BudgetsLoading extends BudgetsState {}

class BudgetsLoaded extends BudgetsState {
  BudgetsLoaded({required this.overview, required this.budgets});
  final BudgetOverviewModel overview;
  final List<BudgetModel> budgets;
}

class BudgetsError extends BudgetsState {
  BudgetsError(this.message);
  final String message;
}
