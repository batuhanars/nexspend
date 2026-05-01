sealed class BudgetsEvent {
  const BudgetsEvent();
}

class BudgetsLoadRequested extends BudgetsEvent {
  const BudgetsLoadRequested();
}

class BudgetsRefreshRequested extends BudgetsEvent {
  const BudgetsRefreshRequested();
}

class BudgetDeleteRequested extends BudgetsEvent {
  BudgetDeleteRequested(this.id);
  final String id;
}

class BudgetUpdateRequested extends BudgetsEvent {
  BudgetUpdateRequested({required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;
}
