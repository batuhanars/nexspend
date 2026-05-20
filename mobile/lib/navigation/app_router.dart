import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection.dart';
import '../core/services/local_auth_service.dart';
import '../core/storage/secure_storage.dart';
import '../data/repositories/auth_repository.dart';
import '../presentation/auth/bloc/auth_bloc.dart';
import '../presentation/auth/pages/login_page.dart';
import '../presentation/auth/pages/register_page.dart';
import '../presentation/auth/pages/forgot_password_page.dart';
import '../presentation/auth/pages/reset_password_page.dart';
import '../presentation/auth/pages/verify_reset_code_page.dart';
import '../presentation/dashboard/pages/dashboard_page.dart';
import '../presentation/transactions/pages/transactions_page.dart';
import '../presentation/transactions/pages/add_transaction_page.dart';
import '../presentation/transactions/pages/transaction_detail_page.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/inflation_repository.dart';
import '../presentation/budgets/bloc/budgets_bloc.dart';
import '../presentation/budgets/bloc/budgets_event.dart';
import '../presentation/budgets/bloc/add_budget_bloc.dart';
import '../presentation/inflation/bloc/inflation_bloc.dart';
import '../presentation/budgets/bloc/add_budget_event.dart';
import '../presentation/budgets/pages/budgets_page.dart';
import '../presentation/budgets/pages/add_budget_page.dart';
import '../presentation/budgets/pages/budget_detail_page.dart';
import '../data/models/budget_model.dart' show BudgetModel;
import '../presentation/family/pages/shared_budget_detail_page.dart';
import '../data/models/debt_model.dart' show DebtModel;
import '../data/models/subscription_model.dart' show SubscriptionModel;
import '../presentation/debts/bloc/debt_detail_bloc.dart';
import '../presentation/debts/bloc/debts_bloc.dart';
import '../presentation/debts/pages/debt_detail_page.dart';
import '../presentation/debts/pages/debts_page.dart';
import '../data/models/family_model.dart' show SharedBudgetModel;
import '../data/repositories/family_repository.dart';
import '../presentation/family/bloc/family_bloc.dart';
import '../presentation/family/bloc/family_event.dart';
import '../presentation/family/pages/contribution_report_page.dart';
import '../presentation/family/pages/family_group_detail_page.dart';
import '../presentation/family/pages/family_group_page.dart';
import '../presentation/family/pages/invite_page.dart';
import '../presentation/insights/pages/insights_page.dart';
import '../presentation/receipt_scanner/pages/receipt_history_page.dart';
import '../presentation/receipt_scanner/pages/receipt_image_viewer_page.dart';
import '../presentation/subscriptions/bloc/subscriptions_bloc.dart' show SubscriptionsBloc, SubscriptionsLoadRequested;
import '../presentation/subscriptions/pages/subscription_detail_page.dart';
import '../presentation/subscriptions/bloc/subscriptions_bloc.dart';
import '../presentation/subscriptions/pages/subscriptions_page.dart';
import '../presentation/reports/pages/reports_page.dart';
import '../presentation/receipt_scanner/pages/receipt_scanner_page.dart';
import '../data/models/account_model.dart' show AccountModel, AccountType;
import '../data/models/transaction_model.dart' show TransactionModel;
import '../data/repositories/account_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/debt_repository.dart';
import '../data/repositories/statement_repository.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/tag_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../presentation/accounts/bloc/account_bloc.dart';
import '../presentation/accounts/bloc/account_detail_bloc.dart';
import '../presentation/accounts/bloc/statements_bloc.dart';
import '../presentation/accounts/pages/account_detail_page.dart';
import '../presentation/accounts/pages/add_account_page.dart';
import '../presentation/accounts/pages/accounts_list_page.dart';
import '../presentation/accounts/pages/archived_accounts_page.dart';
import '../presentation/accounts/pages/edit_account_page.dart';
import '../presentation/transactions/bloc/add_transaction_bloc.dart';
import '../presentation/transactions/bloc/transactions_bloc.dart';
import '../presentation/legal/pages/privacy_policy_page.dart';
import '../presentation/legal/pages/terms_of_service_page.dart';
import '../presentation/onboarding/pages/onboarding_page.dart';
import '../presentation/settings/pages/settings_page.dart';
import '../presentation/settings/pages/edit_profile_page.dart';
import '../presentation/shared/bottom_nav_bar.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.login,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, _) => const OnboardingPage(),
      ),

      // Auth Routes — share one AuthBloc instance across the auth flow
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, _) => BlocProvider(
          create: (_) => AuthBloc(
            authRepository: getIt<AuthRepository>(),
            localAuthService: getIt<LocalAuthService>(),
          ),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, _) => BlocProvider(
          create: (_) => AuthBloc(
            authRepository: getIt<AuthRepository>(),
            localAuthService: getIt<LocalAuthService>(),
          ),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgot-password',
        builder: (context, _) => BlocProvider(
          create: (_) => AuthBloc(
            authRepository: getIt<AuthRepository>(),
            localAuthService: getIt<LocalAuthService>(),
          ),
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.verifyResetCode,
        name: 'verify-reset-code',
        builder: (context, _) => BlocProvider(
          create: (_) => AuthBloc(
            authRepository: getIt<AuthRepository>(),
            localAuthService: getIt<LocalAuthService>(),
          ),
          child: const VerifyResetCodePage(),
        ),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        name: 'reset-password',
        builder: (_, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          // Token zorunlu — kullanıcı bu sayfaya kod doğruladıktan sonra
          // VerifyResetCodePage üzerinden yönlendirilir.
          return BlocProvider(
            create: (_) => AuthBloc(
              authRepository: getIt<AuthRepository>(),
              localAuthService: getIt<LocalAuthService>(),
            ),
            child: ResetPasswordPage(token: token),
          );
        },
      ),

      // Shell Route — BottomNavBar
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            builder: (context, _) => const DashboardPage(),
          ),
          GoRoute(
            path: RouteNames.transactions,
            name: 'transactions',
            builder: (context, _) => BlocProvider(
              create: (_) => TransactionsBloc(
                transactionRepository: getIt<TransactionRepository>(),
              ),
              child: const TransactionsPage(),
            ),
          ),
          GoRoute(
            path: RouteNames.budgets,
            name: 'budgets',
            builder: (context, _) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => BudgetsBloc(
                    budgetRepository: getIt<BudgetRepository>(),
                  )..add(const BudgetsLoadRequested()),
                ),
                BlocProvider(
                  create: (_) => InflationBloc(
                    inflationRepository: getIt<InflationRepository>(),
                  ),
                ),
              ],
              child: const BudgetsPage(),
            ),
          ),
          GoRoute(
            path: RouteNames.subscriptions,
            name: 'subscriptions',
            builder: (context, _) => BlocProvider(
              create: (_) => SubscriptionsBloc(
                subscriptionRepository: getIt<SubscriptionRepository>(),
              )..add(const SubscriptionsLoadRequested()),
              child: const SubscriptionsPage(),
            ),
          ),
        ],
      ),

      // Full-screen Modals (root navigator)
      GoRoute(
        path: RouteNames.debts,
        name: 'debts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => BlocProvider(
          create: (_) => DebtsBloc(
            debtRepository: getIt<DebtRepository>(),
          )..add(const DebtsLoadRequested()),
          child: const DebtsPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.addTransaction,
        name: 'add-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, String?>?;
          return BlocProvider(
            create: (_) => AddTransactionBloc(
              transactionRepository: getIt<TransactionRepository>(),
              categoryRepository: getIt<CategoryRepository>(),
              accountRepository: getIt<AccountRepository>(),
              tagRepository: getIt<TagRepository>(),
            ),
            child: AddTransactionPage(
              initialAccountId: extra?['accountId'],
              initialType: extra?['type'],
              initialCategoryId: extra?['categoryId'],
              initialSharedBudgetId: extra?['sharedBudgetId'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/transactions/:id',
        name: 'transaction-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final transaction = extra['transaction'] as TransactionModel;
          final bloc = extra['bloc'] as TransactionsBloc;
          return BlocProvider.value(
            value: bloc,
            child: TransactionDetailPage(transaction: transaction),
          );
        },
      ),
      GoRoute(
        path: RouteNames.addBudget,
        name: 'add-budget',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => BlocProvider(
          create: (_) => AddBudgetBloc(
            budgetRepository: getIt<BudgetRepository>(),
            categoryRepository: getIt<CategoryRepository>(),
          )..add(const AddBudgetInitialized()),
          child: const AddBudgetPage(),
        ),
      ),
      GoRoute(
        path: '/budgets/:id',
        name: 'budget-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final budget = extra['budget'] as BudgetModel;
          final bloc = extra['bloc'] as BudgetsBloc;
          return BlocProvider.value(
            value: bloc,
            child: BudgetDetailPage(budget: budget),
          );
        },
      ),
      GoRoute(
        path: '/family/:groupId/budgets/:budgetId',
        name: 'shared-budget-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final extra = state.extra as Map<String, dynamic>;
          final budget = extra['budget'] as SharedBudgetModel;
          final bloc = extra['bloc'] as FamilyBloc;
          return BlocProvider.value(
            value: bloc,
            child: SharedBudgetDetailPage(
              groupId: groupId,
              budget: budget,
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.reports,
        name: 'reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => const ReportsPage(),
      ),
      GoRoute(
        path: RouteNames.receiptScanner,
        name: 'receipt-scanner',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, String?>?;
          return ReceiptScannerPage(
            initialCategoryId: extra?['categoryId'],
            initialSharedBudgetId: extra?['sharedBudgetId'],
          );
        },
      ),
      GoRoute(
        path: RouteNames.accounts,
        name: 'accounts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => BlocProvider(
          create: (_) => AccountBloc(
            accountRepository: getIt<AccountRepository>(),
          ),
          child: const AccountsListPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.addAccount,
        name: 'add-account',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BlocProvider(
            create: (_) => AccountBloc(
              accountRepository: getIt<AccountRepository>(),
            ),
            child: AddAccountPage(
              initialType: extra?['type'] as AccountType?,
              initialBankName: extra?['bankName'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/accounts/:id',
        name: 'account-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final account = state.extra as AccountModel?;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => AccountDetailBloc(
                  accountRepository: getIt<AccountRepository>(),
                ),
              ),
              BlocProvider(
                create: (_) => AccountBloc(
                  accountRepository: getIt<AccountRepository>(),
                ),
              ),
              // Kredi kartı için ekstre verisi; diğer hesap tiplerinde
              // bloc tetiklenmeden idle kalır (LoadRequested gönderilmez).
              BlocProvider(
                create: (_) => StatementsBloc(
                  statementRepository: getIt<StatementRepository>(),
                  accountRepository: getIt<AccountRepository>(),
                  accountId: id,
                ),
              ),
            ],
            child: AccountDetailPage(
              accountId: id,
              initialAccount: account,
            ),
          );
        },
      ),
      GoRoute(
        path: '/accounts/:id/edit',
        name: 'edit-account',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final account = state.extra as AccountModel;
          return BlocProvider(
            create: (_) => AccountBloc(
              accountRepository: getIt<AccountRepository>(),
            ),
            child: EditAccountPage(account: account),
          );
        },
      ),
      GoRoute(
        path: RouteNames.archivedAccounts,
        name: 'archived-accounts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => BlocProvider(
          create: (_) => AccountBloc(
            accountRepository: getIt<AccountRepository>(),
          ),
          child: const ArchivedAccountsPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => const SettingsPage(),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        name: 'edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/debts/:id',
        name: 'debt-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final debt = state.extra as DebtModel;
          return BlocProvider(
            create: (_) => DebtDetailBloc(
              debtRepository: getIt<DebtRepository>(),
            ),
            child: DebtDetailPage(debt: debt),
          );
        },
      ),
      GoRoute(
        path: '/subscriptions/:id',
        name: 'subscription-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final subscription = state.extra as SubscriptionModel;
          return BlocProvider(
            create: (_) => SubscriptionsBloc(
              subscriptionRepository: getIt<SubscriptionRepository>(),
            )..add(const SubscriptionsLoadRequested()),
            child: SubscriptionDetailPage(subscription: subscription),
          );
        },
      ),
      GoRoute(
        path: RouteNames.insights,
        name: 'insights',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => const InsightsPage(),
      ),

      // Ortak Bütçe (Gruplar) routes
      GoRoute(
        path: RouteNames.family,
        name: 'family',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => BlocProvider(
          create: (_) => FamilyBloc(
            familyRepository: getIt<FamilyRepository>(),
          )..add(const FamilyGroupsLoadRequested()),
          child: const FamilyGroupPage(),
        ),
      ),
      // Deep link: wallet://invite/<token> → GoRouter routes /invite/:token
      GoRoute(
        path: '/invite/:token',
        name: 'family-invite',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return BlocProvider(
            create: (_) =>
                FamilyBloc(familyRepository: getIt<FamilyRepository>()),
            child: InvitePage(token: token),
          );
        },
      ),
      GoRoute(
        path: '/family/:id',
        name: 'family-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) =>
                FamilyBloc(familyRepository: getIt<FamilyRepository>()),
            child: FamilyGroupDetailPage(groupId: id),
          );
        },
      ),
      GoRoute(
        path: '/family/:id/contributions',
        name: 'family-contributions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final period = state.uri.queryParameters['period'];
          return BlocProvider(
            create: (_) =>
                FamilyBloc(familyRepository: getIt<FamilyRepository>()),
            child: ContributionReportPage(
              groupId: id,
              initialPeriod: period,
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.privacyPolicy,
        name: 'privacy-policy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: RouteNames.termsOfService,
        name: 'terms-of-service',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: RouteNames.receiptHistory,
        name: 'receipt-history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) => const ReceiptHistoryPage(),
      ),
      GoRoute(
        path: '/receipts/:id/image',
        name: 'receipt-image',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ReceiptImageViewerPage(
          receiptId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
}

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final storage = getIt<SecureStorage>();

  final isPublicPage = state.matchedLocation == RouteNames.privacyPolicy ||
      state.matchedLocation == RouteNames.termsOfService;
  final isOnboarding = state.matchedLocation == RouteNames.onboarding;

  // Onboarding henüz tamamlanmadıysa — auth/public sayfalar dahil her yerden yönlendir
  final onboardingDone = await storage.isOnboardingComplete();
  if (!onboardingDone && !isOnboarding && !isPublicPage) {
    return RouteNames.onboarding;
  }

  final isLoggedIn = await storage.hasTokens();
  final isOnAuthPage = state.matchedLocation == RouteNames.login ||
      state.matchedLocation == RouteNames.register ||
      state.matchedLocation == RouteNames.verifyResetCode ||
      state.matchedLocation == RouteNames.forgotPassword ||
      state.matchedLocation == RouteNames.resetPassword;

  if (!isLoggedIn && !isOnAuthPage && !isPublicPage && !isOnboarding) {
    return RouteNames.login;
  }

  if (isLoggedIn && isOnAuthPage) {
    // Biometric açıksa login sayfasında kal — LoginPage tetikleyecek
    final biometricEnabled = await storage.getBiometricEnabled();
    if (biometricEnabled && state.matchedLocation == RouteNames.login) {
      return null;
    }
    return RouteNames.home;
  }

  return null;
}
