import '../../../data/models/category_model.dart';
import '../../../data/models/family_model.dart';

sealed class AddSharedBudgetState {}

class AddSharedBudgetInitial extends AddSharedBudgetState {}

class AddSharedBudgetCategoriesLoading extends AddSharedBudgetState {}

class AddSharedBudgetReady extends AddSharedBudgetState {
  AddSharedBudgetReady(this.categories);
  final List<CategoryModel> categories;
}

class AddSharedBudgetSubmitting extends AddSharedBudgetState {
  AddSharedBudgetSubmitting(this.categories);
  final List<CategoryModel> categories;
}

class AddSharedBudgetSuccess extends AddSharedBudgetState {
  AddSharedBudgetSuccess(this.budget);
  final SharedBudgetModel budget;
}

class AddSharedBudgetFailure extends AddSharedBudgetState {
  AddSharedBudgetFailure({required this.message, required this.categories});
  final String message;
  final List<CategoryModel> categories;
}
