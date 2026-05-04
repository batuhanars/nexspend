import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';
import '../../navigation/route_names.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  final SecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) {
          await _storage.clearTokens();
          _navigateToLogin();
          return handler.next(err);
        }

        final response = await _dio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        final newAccessToken = response.data['data']['accessToken'] as String;
        final newRefreshToken = response.data['data']['refreshToken'] as String;
        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Orijinal isteği yeni token ile tekrar gönder
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        await _storage.clearTokens();
        _navigateToLogin();
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  void _navigateToLogin() {
    try {
      GetIt.instance<GoRouter>().go(RouteNames.login);
    } catch (_) {
      // Router henüz kayıtlı değilse sessizce geç
    }
  }
}
