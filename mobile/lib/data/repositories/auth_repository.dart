import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient, required SecureStorage storage})
      : _dio = apiClient.dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorage _storage;

  Future<void> login({required String email, required String password}) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data['data'];
    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {'fullName': fullName, 'email': email, 'password': password},
    );
    final data = response.data['data'];
    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.resetPassword,
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<void> googleSignIn() async {
    // Google Sign-In token'ı backend'e gönder
    // google_sign_in paketi ile entegrasyon Sprint 1 sonunda yapılacak
    throw UnimplementedError('Google Sign-In henüz implemente edilmedi');
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } finally {
      await _storage.clearTokens();
    }
  }
}
