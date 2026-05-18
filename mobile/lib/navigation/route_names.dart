class RouteNames {
  RouteNames._();

  // Onboarding
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyResetCode = '/verify-reset-code';
  static const String resetPassword = '/reset-password';

  // Shell (BottomNavBar)
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static String transactionDetail(String id) => '/transactions/$id';
  static const String budgets = '/budgets';
  static const String addBudget = '/budgets/add';
  static String budgetDetail(String id) => '/budgets/$id';
  static const String debts = '/debts';
  static String debtDetail(String id) => '/debts/$id';
  static const String subscriptions = '/subscriptions';
  static String subscriptionDetail(String id) => '/subscriptions/$id';

  // Hesaplar
  static const String accounts = '/accounts';
  static const String addAccount = '/accounts/add';
  static String accountDetail(String id) => '/accounts/$id';
  static String editAccount(String id) => '/accounts/$id/edit';

  // Arşiv
  static const String archivedAccounts = '/settings/archived-accounts';

  // Insights (Home carousel'dan push)
  static const String insights = '/insights';

  // Ortak Bütçe (Gruplar)
  static const String family = '/family';
  static String familyGroupDetail(String id) => '/family/$id';
  static String sharedBudgetDetail(String groupId, String budgetId) =>
      '/family/$groupId/budgets/$budgetId';
  static String familyContributions(String id) => '/family/$id/contributions';
  static String familyInvite(String token) => '/invite/$token';

  // AppBar erişimli
  static const String reports = '/reports';
  static const String receiptScanner = '/receipt-scanner';
  static const String receiptHistory = '/receipt-history';
  static String receiptImage(String id) => '/receipts/$id/image';
  static const String settings = '/settings';
  static const String editProfile = '/settings/profile';

  // Yasal
  static const String privacyPolicy = '/legal/privacy-policy';
  static const String termsOfService = '/legal/terms-of-service';
}
