class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl =
      'https://wallet-api.up.railway.app'; // Android emulator → localhost

  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String googleAuth = '/api/auth/google';
  static const String googleMobileAuth = '/api/auth/google/mobile';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyResetCode = '/api/auth/verify-reset-code';
  static const String resetPassword = '/api/auth/reset-password';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';

  // Users
  static const String me = '/api/users/me';
  static const String meSettings = '/api/users/me/settings';
  static const String meAvatar = '/api/users/me/avatar';
  static const String mePassword = '/api/users/me/change-password';
  static const String meFcmToken = '/api/users/me/fcm-token';

  // Dashboard
  static const String dashboard = '/api/dashboard';

  // Accounts
  static const String accounts = '/api/accounts';
  static const String accountsSummary = '/api/accounts/summary';
  static String accountById(String id) => '/api/accounts/$id';
  static String accountTransactions(String id) =>
      '/api/accounts/$id/transactions';
  static String accountAnalytics(String id) => '/api/accounts/$id/analytics';
  static String accountStatement(String id) => '/api/accounts/$id/statement';
  static String accountArchive(String id) => '/api/accounts/$id/archive';
  static String accountRestore(String id) => '/api/accounts/$id/restore';
  static String accountSetDefault(String id) => '/api/accounts/$id/set-default';

  // Transactions
  static const String transactions = '/api/transactions';
  static const String transactionsSummary = '/api/transactions/summary';
  static String transactionById(String id) => '/api/transactions/$id';

  // Budgets
  static const String budgets = '/api/budgets';
  static const String budgetsOverview = '/api/budgets/overview';
  static String budgetById(String id) => '/api/budgets/$id';

  // Debts
  static const String debts = '/api/debts';
  static const String debtsSummary = '/api/debts/summary';
  static String debtById(String id) => '/api/debts/$id';
  static String debtPayments(String id) => '/api/debts/$id/payments';
  static String debtInstallments(String id) => '/api/debts/$id/installments';

  // Subscriptions
  static const String subscriptions = '/api/subscriptions';
  static const String subscriptionsSummary = '/api/subscriptions/summary';
  static const String subscriptionsUpcoming = '/api/subscriptions/upcoming';
  static String subscriptionById(String id) => '/api/subscriptions/$id';
  static String subscriptionToggle(String id) =>
      '/api/subscriptions/$id/toggle';

  // Categories
  static const String categories = '/api/categories';
  static String categoryById(String id) => '/api/categories/$id';

  // Recurring Transactions
  static const String recurringTransactions = '/api/recurring-transactions';
  static String recurringTransactionById(String id) =>
      '/api/recurring-transactions/$id';

  // Tags
  static const String tags = '/api/tags';
  static String tagById(String id) => '/api/tags/$id';

  // Reports
  static const String reportsExpenseDistribution =
      '/api/reports/expense-distribution';
  static const String reportsCashFlow = '/api/reports/cash-flow';
  static const String reportsTrends = '/api/reports/trends';

  // Credit Card Statements
  static String accountStatementsList(String accountId) =>
      '/api/accounts/$accountId/statements';
  static String statementById(String id) => '/api/statements/$id';
  static String statementPay(String id) => '/api/statements/$id/pay';

  // Inflation
  static const String inflationCurrent = '/api/inflation/current';
  static const String inflationHistory = '/api/inflation/history';
  static String budgetInflationSuggestion(String id) =>
      '/api/budgets/$id/inflation-suggestion';
  static String budgetApplyInflation(String id) =>
      '/api/budgets/$id/apply-inflation';
  static const String reportsInflationComparison =
      '/api/reports/inflation-comparison';

  // Receipts
  static const String receiptsScan = '/api/receipts/scan';
  static const String receipts = '/api/receipts';
  static String receiptById(String id) => '/api/receipts/$id';
  static String receiptImage(String id) => '/api/receipts/$id/image';
  static String receiptCreateTransaction(String id) =>
      '/api/receipts/$id/confirm';
  static const String receiptsCheckDuplicate = '/api/receipts/check-duplicate';
}
