import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';
import 'api_interceptors.dart';

class ApiClient {
  ApiClient(SecureStorage storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(storage, _dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => _log(obj.toString()),
      ),
    ]);
  }

  late final Dio _dio;

  Dio get dio => _dio;

  void _log(String message) {
    assert(() {
      // ignore: avoid_print
      print('[ApiClient] $message');
      return true;
    }());
  }
}
