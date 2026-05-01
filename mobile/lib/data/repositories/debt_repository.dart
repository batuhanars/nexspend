import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/debt_model.dart';

class DebtRepository {
  DebtRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<DebtModel>> getAll({String? type, String? status}) async {
    final response = await _dio.get(
      ApiEndpoints.debts,
      queryParameters: {
        if (type != null) 'type': type,
        if (status != null) 'status': status,
      },
    );
    final list = response.data['data'] as List;
    return list.map((d) => DebtModel.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<DebtSummaryModel> getSummary() async {
    final response = await _dio.get(ApiEndpoints.debtsSummary);
    return DebtSummaryModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<DebtModel> create(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiEndpoints.debts, data: data);
    return DebtModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<DebtModel> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch(ApiEndpoints.debtById(id), data: data);
    return DebtModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(ApiEndpoints.debtById(id));
  }

  Future<void> recordPayment(String id, Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.debtPayments(id), data: data);
  }

  Future<List<DebtInstallmentModel>> getInstallments(String id) async {
    final response = await _dio.get(ApiEndpoints.debtInstallments(id));
    final list = response.data['data'] as List;
    return list
        .map((i) => DebtInstallmentModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }
}
