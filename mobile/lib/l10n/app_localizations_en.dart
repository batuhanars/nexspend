// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Digital Wallet';

  @override
  String get hello => 'Hello';

  @override
  String helloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get myAccounts => 'My Accounts';

  @override
  String get archivedAccounts => 'Archived Accounts';

  @override
  String get preferences => 'Preferences';

  @override
  String get notifications => 'Notifications';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get currency => 'Currency';

  @override
  String get language => 'Language';

  @override
  String get tools => 'Tools';

  @override
  String get receiptHistory => 'Receipt History';

  @override
  String get security => 'Security';

  @override
  String get changePassword => 'Change Password';

  @override
  String get session => 'Session';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmContent => 'Are you sure you want to logout?';

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get currencyTRY => 'Turkish Lira';

  @override
  String get currencyUSD => 'US Dollar';

  @override
  String get currencyEUR => 'Euro';

  @override
  String get currencyGBP => 'British Pound';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get add => 'Add';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get dashboard => 'Home';

  @override
  String get transactions => 'Transactions';

  @override
  String get budgets => 'Budgets';

  @override
  String get debts => 'Debts';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get transfer => 'Transfer';

  @override
  String get noDataFound => 'No data found';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get networkError => 'Please check your internet connection.';

  @override
  String get tryAgain => 'Try Again';
}
