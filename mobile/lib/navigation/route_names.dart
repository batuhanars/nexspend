class RouteNames {
  RouteNames._();

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

  // AppBar erişimli
  static const String reports = '/reports';
  static const String receiptScanner = '/receipt-scanner';
  static const String receiptHistory = '/receipt-history';
  static String receiptImage(String id) => '/receipts/$id/image';
  static const String settings = '/settings';
  static const String editProfile = '/settings/profile';
}
