sealed class AddBudgetEvent {
  const AddBudgetEvent();
}

class AddBudgetInitialized extends AddBudgetEvent {
  const AddBudgetInitialized();
}

class AddBudgetSubmitted extends AddBudgetEvent {
  AddBudgetSubmitted(this.data);
  final Map<String, dynamic> data;
}
