import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  BudgetRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<BudgetModel>> getAll({bool includeArchived = false}) async {
    final response = await _dio.get(
      ApiEndpoints.budgets,
      queryParameters:
          includeArchived ? {'includeArchived': 'true'} : null,
    );
    final list = response.data['data'] as List;
    return list
        .map((b) => BudgetModel.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  Future<BudgetOverviewModel> getOverview() async {
    final response = await _dio.get(ApiEndpoints.budgetsOverview);
    return BudgetOverviewModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<BudgetModel> create(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiEndpoints.budgets, data: data);
    return BudgetModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BudgetModel> update(String id, Map<String, dynamic> data) async {
    final response =
        await _dio.patch(ApiEndpoints.budgetById(id), data: data);
    return BudgetModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(ApiEndpoints.budgetById(id));
  }

  Future<BudgetModel> getById(String id) async {
    final response = await _dio.get(ApiEndpoints.budgetById(id));
    return BudgetModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<BudgetHistoryEntry>> getHistory(String budgetId) async {
    final response = await _dio.get(ApiEndpoints.budgetHistory(budgetId));
    final list = response.data['data'] as List;
    return list
        .map((e) => BudgetHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
