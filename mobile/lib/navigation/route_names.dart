class RouteNames {
  RouteNames._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Shell (BottomNavBar)
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String budgets = '/budgets';
  static const String addBudget = '/budgets/add';
  static const String debts = '/debts';
  static const String subscriptions = '/subscriptions';

  // Hesaplar
  static const String addAccount = '/accounts/add';
  static String accountDetail(String id) => '/accounts/$id';
  static String editAccount(String id) => '/accounts/$id/edit';

  // AppBar erişimli
  static const String reports = '/reports';
  static const String receiptScanner = '/receipt-scanner';
  static const String settings = '/settings';
  static const String editProfile = '/settings/profile';
}
