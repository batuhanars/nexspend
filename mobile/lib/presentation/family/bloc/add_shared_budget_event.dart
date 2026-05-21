sealed class AddSharedBudgetEvent {
  const AddSharedBudgetEvent();
}

class AddSharedBudgetInitialized extends AddSharedBudgetEvent {
  const AddSharedBudgetInitialized();
}

class AddSharedBudgetSubmitted extends AddSharedBudgetEvent {
  const AddSharedBudgetSubmitted(this.data);
  final Map<String, dynamic> data;
}
