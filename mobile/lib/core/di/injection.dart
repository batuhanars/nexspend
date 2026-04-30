import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Storage
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );

  getIt.registerLazySingleton<SecureStorage>(
    () => SecureStorage(getIt<FlutterSecureStorage>()),
  );

  // Network
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<SecureStorage>()),
  );
}
