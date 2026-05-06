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
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
      _pending = [];

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
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Refresh zaten sürüyorsa bu isteği kuyruğa al; handler'ı askıda bırak.
    if (_isRefreshing) {
      _pending.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        await _storage.clearTokens();
        _flushPending(null, err);
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

      // Kuyruktaki istekleri yeni token ile tekrar gönder.
      _flushPending(newAccessToken, null);

      // Orijinal isteği yeni token ile tekrar gönder.
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(err.requestOptions);
      return handler.resolve(retryResponse);
    } catch (_) {
      await _storage.clearTokens();
      _flushPending(null, err);
      _navigateToLogin();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  // newToken != null → kuyruktaki istekleri başarıyla tekrar gönder.
  // newToken == null → kuyruktaki istekleri hata ile sonlandır.
  void _flushPending(String? newToken, DioException? err) {
    final items = List.of(_pending);
    _pending.clear();
    for (final item in items) {
      if (newToken != null) {
        item.options.headers['Authorization'] = 'Bearer $newToken';
        _dio.fetch(item.options).then(
          item.handler.resolve,
          onError: (e) => item.handler.next(
            e is DioException ? e : DioException(requestOptions: item.options),
          ),
        );
      } else {
        item.handler.next(err!);
      }
    }
  }

  void _navigateToLogin() {
    try {
      GetIt.instance<GoRouter>().go(RouteNames.login);
    } catch (_) {}
  }
}
