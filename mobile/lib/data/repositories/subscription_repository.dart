import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  SubscriptionRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<SubscriptionModel>> getAll({bool? activeOnly}) async {
    final response = await _dio.get(
      ApiEndpoints.subscriptions,
      queryParameters: activeOnly != null ? {'isActive': activeOnly} : null,
    );
    final list = response.data['data'] as List;
    return list
        .map((s) => SubscriptionModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionSummaryModel> getSummary() async {
    final response = await _dio.get(ApiEndpoints.subscriptionsSummary);
    return SubscriptionSummaryModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<List<SubscriptionModel>> getUpcoming() async {
    final response = await _dio.get(ApiEndpoints.subscriptionsUpcoming);
    final list = response.data['data'] as List;
    return list
        .map((s) => SubscriptionModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionModel> create(Map<String, dynamic> data) async {
    final response =
        await _dio.post(ApiEndpoints.subscriptions, data: data);
    return SubscriptionModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<SubscriptionModel> update(String id, Map<String, dynamic> data) async {
    final response =
        await _dio.patch(ApiEndpoints.subscriptionById(id), data: data);
    return SubscriptionModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(ApiEndpoints.subscriptionById(id));
  }

  Future<void> toggle(String id) async {
    await _dio.patch(ApiEndpoints.subscriptionToggle(id));
  }
}
