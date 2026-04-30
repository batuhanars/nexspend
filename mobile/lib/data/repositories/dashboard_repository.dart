import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  DashboardRepository({required ApiClient apiClient})
      : _dio = apiClient.dio;

  final Dio _dio;

  Future<DashboardModel> getDashboard() async {
    final response = await _dio.get(ApiEndpoints.dashboard);
    return DashboardModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
