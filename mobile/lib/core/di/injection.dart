import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../services/app_events.dart';
import '../services/local_auth_service.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/statement_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/inflation_repository.dart';
import '../../data/repositories/receipt_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../network/api_client.dart';
import '../services/notification_service.dart';
import '../storage/secure_storage.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Storage
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );

  getIt.registerLazySingleton<SecureStorage>(
    () => SecureStorage(getIt<FlutterSecureStorage>()),
  );

  // Services
  getIt.registerLazySingleton<AppEvents>(() => AppEvents());
  getIt.registerLazySingleton<LocalAuthService>(() => LocalAuthService());

  // Network
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<SecureStorage>()),
  );

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(getIt<ApiClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiClient: getIt<ApiClient>(),
      storage: getIt<SecureStorage>(),
    ),
  );

  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<AccountRepository>(
    () => AccountRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<BudgetRepository>(
    () => BudgetRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<TagRepository>(
    () => TagRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<DebtRepository>(
    () => DebtRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ReportRepository>(
    () => ReportRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<InflationRepository>(
    () => InflationRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<StatementRepository>(
    () => StatementRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<InflationRepository>(
    () => InflationRepository(apiClient: getIt<ApiClient>()),
  );
}
