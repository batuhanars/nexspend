import 'account_model.dart';
import 'transaction_model.dart';

class DashboardModel {
  const DashboardModel({
    required this.totalAssets,
    required this.creditCardDebt,
    required this.netAssets,
    required this.monthlyChange,
    required this.monthlyChangePercent,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.accounts,
    required this.recentTransactions,
    this.userFirstName,
  });

  final double totalAssets;
  final double creditCardDebt;
  final double netAssets;
  final double monthlyChange;
  final double monthlyChangePercent;
  final double monthlyIncome;
  final double monthlyExpense;
  final List<AccountModel> accounts;
  final List<TransactionModel> recentTransactions;
  final String? userFirstName;

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        totalAssets: (json['totalAssets'] as num).toDouble(),
        creditCardDebt: (json['creditCardDebt'] as num? ?? 0).toDouble(),
        netAssets: (json['netAssets'] as num).toDouble(),
        monthlyChange: (json['monthlyChange'] as num? ?? 0).toDouble(),
        monthlyChangePercent:
            (json['monthlyChangePercent'] as num? ?? 0).toDouble(),
        monthlyIncome: (json['monthlyIncome'] as num? ?? 0).toDouble(),
        monthlyExpense: (json['monthlyExpense'] as num? ?? 0).toDouble(),
        accounts: (json['accounts'] as List? ?? [])
            .map((a) => AccountModel.fromJson(a as Map<String, dynamic>))
            .toList(),
        recentTransactions: (json['recentTransactions'] as List? ?? [])
            .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
            .toList(),
        userFirstName: json['userFirstName'] as String?,
      );
}
