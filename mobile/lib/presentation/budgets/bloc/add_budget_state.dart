import '../../../data/models/budget_model.dart';
import '../../../data/models/category_model.dart';

sealed class AddBudgetState {}

class AddBudgetInitial extends AddBudgetState {}

class AddBudgetCategoriesLoading extends AddBudgetState {}

class AddBudgetReady extends AddBudgetState {
  AddBudgetReady(this.categories);
  final List<CategoryModel> categories;
}

class AddBudgetSubmitting extends AddBudgetState {
  AddBudgetSubmitting(this.categories);
  final List<CategoryModel> categories;
}

class AddBudgetSuccess extends AddBudgetState {
  AddBudgetSuccess(this.budget);
  final BudgetModel budget;
}

class AddBudgetFailure extends AddBudgetState {
  AddBudgetFailure({required this.message, required this.categories});
  final String message;
  final List<CategoryModel> categories;
}
