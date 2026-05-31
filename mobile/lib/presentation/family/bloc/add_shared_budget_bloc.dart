import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/family_repository.dart';
import 'add_shared_budget_event.dart';
import 'add_shared_budget_state.dart';

class AddSharedBudgetBloc
    extends Bloc<AddSharedBudgetEvent, AddSharedBudgetState> {
  AddSharedBudgetBloc({
    required FamilyRepository familyRepository,
    required CategoryRepository categoryRepository,
  })  : _familyRepo = familyRepository,
        _categoryRepo = categoryRepository,
        super(AddSharedBudgetInitial()) {
    on<AddSharedBudgetInitialized>(_onInit);
    on<AddSharedBudgetSubmitted>(_onSubmit);
  }

  final FamilyRepository _familyRepo;
  final CategoryRepository _categoryRepo;

  Future<void> _onInit(
      AddSharedBudgetInitialized event,
      Emitter<AddSharedBudgetState> emit) async {
    emit(AddSharedBudgetCategoriesLoading());
    try {
      final cats = await _categoryRepo.getCategories();
      final filtered = cats
          .where((c) =>
              c.type == CategoryType.EXPENSE || c.type == CategoryType.BOTH)
          .toList();
      emit(AddSharedBudgetReady(filtered));
    } catch (_) {
      emit(AddSharedBudgetReady(const []));
    }
  }

  Future<void> _onSubmit(
      AddSharedBudgetSubmitted event,
      Emitter<AddSharedBudgetState> emit) async {
    final cats = switch (state) {
      AddSharedBudgetReady(:final categories) => categories,
      AddSharedBudgetFailure(:final categories) => categories,
      _ => <CategoryModel>[],
    };
    emit(AddSharedBudgetSubmitting(cats));
    try {
      final data = event.data;
      final budget = await _familyRepo.createSharedBudget(
        groupId: data['groupId'] as String,
        categoryId: data['categoryId'] as String,
        name: data['name'] as String,
        amount: data['amount'] as double,
        startDate: data['startDate'] as String,
        period: data['period'] as String,
        endDate: data['endDate'] as String?,
      );
      emit(AddSharedBudgetSuccess(budget));
    } catch (_) {
      emit(AddSharedBudgetFailure(
        message: 'Ortak bütçe oluşturulamadı',
        categories: cats,
      ));
    }
  }
}
