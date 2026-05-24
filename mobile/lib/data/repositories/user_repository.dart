import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<UserModel> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateMe(Map<String, dynamic> data) async {
    final response = await _dio.patch(ApiEndpoints.me, data: data);
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(ApiEndpoints.mePassword, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<UserModel> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(ApiEndpoints.meAvatar, data: formData);
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAvatar() async {
    await _dio.delete(ApiEndpoints.meAvatar);
  }

  Future<void> resetData() async {
    await _dio.post(ApiEndpoints.meReset);
  }
}
