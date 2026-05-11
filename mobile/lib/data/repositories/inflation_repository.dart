import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/budget_model.dart';
import '../models/inflation_model.dart';

class InflationRepository {
  InflationRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<InflationRateModel>> getCurrent() async {
    final response = await _dio.get(ApiEndpoints.inflationCurrent);
    final list = response.data['data'] as List? ?? [];
    return list
        .map((e) => InflationRateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, List<InflationRateModel>>> getHistory(
      {int months = 6}) async {
    final response = await _dio.get(
      ApiEndpoints.inflationHistory,
      queryParameters: {'months': months},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return data.map(
      (key, value) => MapEntry(
        key,
        (value as List)
            .map((e) =>
                InflationRateModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  // Returns null on 204 (no meaningful suggestion) or 422 (no category mapping).
  Future<InflationSuggestionModel?> getSuggestion(String budgetId) async {
    try {
      final response =
          await _dio.get(ApiEndpoints.budgetInflationSuggestion(budgetId));
      if (response.statusCode == 204 || response.data == null) return null;
      return InflationSuggestionModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) return null;
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<BudgetModel> applyInflation(
      String budgetId, double newAmount) async {
    final response = await _dio.post(
      ApiEndpoints.budgetApplyInflation(budgetId),
      data: {'newAmount': newAmount},
    );
    return BudgetModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<InflationComparisonModel> getComparison({String? period}) async {
    final response = await _dio.get(
      ApiEndpoints.reportsInflationComparison,
      queryParameters: {
        'period': ?period,
      },
    );
    return InflationComparisonModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
