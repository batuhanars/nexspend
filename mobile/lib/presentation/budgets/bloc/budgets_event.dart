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
