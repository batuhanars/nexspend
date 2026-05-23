import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/category_model.dart';
import 'package:wallet_app/data/models/family_model.dart';
import 'package:wallet_app/data/repositories/category_repository.dart';
import 'package:wallet_app/data/repositories/family_repository.dart';
import 'package:wallet_app/presentation/family/bloc/add_shared_budget_bloc.dart';
import 'package:wallet_app/presentation/family/bloc/add_shared_budget_event.dart';
import 'package:wallet_app/presentation/family/bloc/add_shared_budget_state.dart';

class MockFamilyRepository extends Mock implements FamilyRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

final _category = CategoryModel(
  id: 'cat-1',
  name: 'Market',
  type: CategoryType.EXPENSE,
  icon: 'shopping_cart',
  color: '#FF5733',
);

final _budget = SharedBudgetModel(
  id: 'sb-1',
  groupId: 'g-1',
  name: 'Test Ortak',
  amount: 2000,
  spent: 500,
  remainingPercent: 0.75,
  categoryId: 'cat-1',
  categoryName: 'Market',
  period: 'MONTHLY',
  isActive: true,
  startDate: '2026-05-01',
  endDate: DateTime(2026, 5, 31),
);

void main() {
  late MockFamilyRepository familyRepo;
  late MockCategoryRepository categoryRepo;

  setUp(() {
    familyRepo = MockFamilyRepository();
    categoryRepo = MockCategoryRepository();

    when(() => categoryRepo.getCategories())
        .thenAnswer((_) async => [_category]);
  });

  AddSharedBudgetBloc buildBloc() => AddSharedBudgetBloc(
        familyRepository: familyRepo,
        categoryRepository: categoryRepo,
      );

  blocTest<AddSharedBudgetBloc, AddSharedBudgetState>(
    'AddSharedBudgetInitialized başarılı → CategoriesLoading → Ready (kategoriler yüklendi)',
    build: buildBloc,
    act: (bloc) => bloc.add(const AddSharedBudgetInitialized()),
    expect: () => [
      isA<AddSharedBudgetCategoriesLoading>(),
      isA<AddSharedBudgetReady>().having(
          (s) => s.categories, 'categories', [_category]),
    ],
  );

  blocTest<AddSharedBudgetBloc, AddSharedBudgetState>(
    'AddSharedBudgetSubmitted başarılı → Submitting → Success',
    build: buildBloc,
    seed: () => AddSharedBudgetReady([_category]),
    setUp: () {
      when(() => familyRepo.createSharedBudget(
            groupId: any(named: 'groupId'),
            categoryId: any(named: 'categoryId'),
            name: any(named: 'name'),
            amount: any(named: 'amount'),
            startDate: any(named: 'startDate'),
            period: any(named: 'period'),
          )).thenAnswer((_) async => _budget);
    },
    act: (bloc) => bloc.add(AddSharedBudgetSubmitted({
          'groupId': 'g-1',
          'categoryId': 'cat-1',
          'name': 'Test Ortak',
          'amount': 2000.0,
          'startDate': '2026-05-01T00:00:00.000',
          'period': 'MONTHLY',
        })),
    expect: () => [
      isA<AddSharedBudgetSubmitting>(),
      isA<AddSharedBudgetSuccess>().having((s) => s.budget, 'budget', _budget),
    ],
  );

  blocTest<AddSharedBudgetBloc, AddSharedBudgetState>(
    'AddSharedBudgetSubmitted API hatası → Submitting → Failure',
    build: buildBloc,
    seed: () => AddSharedBudgetReady([_category]),
    setUp: () {
      when(() => familyRepo.createSharedBudget(
            groupId: any(named: 'groupId'),
            categoryId: any(named: 'categoryId'),
            name: any(named: 'name'),
            amount: any(named: 'amount'),
            startDate: any(named: 'startDate'),
            period: any(named: 'period'),
          )).thenThrow(Exception('Network error'));
    },
    act: (bloc) => bloc.add(AddSharedBudgetSubmitted({
          'groupId': 'g-1',
          'categoryId': 'cat-1',
          'name': 'Test Ortak',
          'amount': 2000.0,
          'startDate': '2026-05-01T00:00:00.000',
          'period': 'MONTHLY',
        })),
    expect: () => [
      isA<AddSharedBudgetSubmitting>(),
      isA<AddSharedBudgetFailure>(),
    ],
  );
}
