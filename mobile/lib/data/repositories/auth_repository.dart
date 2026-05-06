import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient, required SecureStorage storage})
      : _dio = apiClient.dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorage _storage;
  final _googleSignIn = GoogleSignIn(
    serverClientId: '31697958728-08g4o12cre3s1hle79v1gabugvviuvba.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

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

  Future<void> verifyResetCode({required String token}) async {
    await _dio.post(ApiEndpoints.verifyResetCode, data: {'token': token});
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
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Google Sign-In iptal edildi');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw Exception('Google ID token alınamadı');

    final response = await _dio.post(
      ApiEndpoints.googleMobileAuth,
      data: {'idToken': idToken},
    );
    final data = response.data['data'];
    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } finally {
      await _storage.clearTokens();
    }
  }
}
