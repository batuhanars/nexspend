import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/category_repository.dart';
import 'add_budget_event.dart';
import 'add_budget_state.dart';

class AddBudgetBloc extends Bloc<AddBudgetEvent, AddBudgetState> {
  AddBudgetBloc({
    required BudgetRepository budgetRepository,
    required CategoryRepository categoryRepository,
  })  : _budgetRepo = budgetRepository,
        _categoryRepo = categoryRepository,
        super(AddBudgetInitial()) {
    on<AddBudgetInitialized>(_onInit);
    on<AddBudgetSubmitted>(_onSubmit);
  }

  final BudgetRepository _budgetRepo;
  final CategoryRepository _categoryRepo;

  Future<void> _onInit(
      AddBudgetInitialized event, Emitter<AddBudgetState> emit) async {
    emit(AddBudgetCategoriesLoading());
    try {
      final cats = await _categoryRepo.getCategories();
      final filtered = cats
          .where((c) =>
              c.type == CategoryType.EXPENSE || c.type == CategoryType.BOTH)
          .toList();
      emit(AddBudgetReady(filtered));
    } catch (_) {
      emit(AddBudgetReady(const []));
    }
  }

  Future<void> _onSubmit(
      AddBudgetSubmitted event, Emitter<AddBudgetState> emit) async {
    final cats = switch (state) {
      AddBudgetReady(:final categories) => categories,
      AddBudgetFailure(:final categories) => categories,
      _ => <CategoryModel>[],
    };
    emit(AddBudgetSubmitting(cats));
    try {
      final budget = await _budgetRepo.create(event.data);
      emit(AddBudgetSuccess(budget));
    } catch (e) {
      final msg = e.toString().contains('409') ||
              e.toString().contains('Conflict') ||
              e.toString().contains('aktif')
          ? 'Bu kategori için zaten aktif bir bütçe var'
          : 'Bütçe oluşturulamadı';
      emit(AddBudgetFailure(message: msg, categories: cats));
    }
  }
}
