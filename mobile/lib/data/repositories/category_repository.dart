import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/category_model.dart';

class CategoryRepository {
  CategoryRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get(ApiEndpoints.categories);
    final list = response.data['data'] as List;
    return list
        .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}
