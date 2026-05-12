import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/insight_model.dart';

class InsightsRepository {
  InsightsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<InsightModel>> getInsights({
    String? period,
    bool? unread,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.insights,
      queryParameters: {
        'period': ?period,
        'unread': ?unread,
        'page': page,
        'limit': limit,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final items = data['items'] as List? ?? [];
    return items
        .map((e) => InsightModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InsightSummaryModel> getSummary() async {
    final response = await _dio.get(ApiEndpoints.insightsSummary);
    return InsightSummaryModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<InsightModel> markRead(String id) async {
    final response = await _dio.patch(ApiEndpoints.insightRead(id));
    return InsightModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<InsightModel> dismiss(String id) async {
    final response = await _dio.patch(ApiEndpoints.insightDismiss(id));
    return InsightModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<InsightGenerateResultModel> generate() async {
    final response = await _dio.post(ApiEndpoints.insightsGenerate);
    return InsightGenerateResultModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
