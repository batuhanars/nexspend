import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/tag_model.dart';

class TagRepository {
  TagRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<TagModel>> getAll() async {
    final response = await _dio.get(ApiEndpoints.tags);
    final list = response.data['data'] as List;
    return list
        .map((t) => TagModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<TagModel> create(String name) async {
    final response =
        await _dio.post(ApiEndpoints.tags, data: {'name': name});
    return TagModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(ApiEndpoints.tagById(id));
  }
}
