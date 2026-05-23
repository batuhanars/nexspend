import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  TransactionRepository({required ApiClient apiClient})
      : _dio = apiClient.dio;

  final Dio _dio;

  Future<({List<TransactionModel> data, int total, int totalPages})>
      getTransactions({
    int page = 1,
    int limit = 30,
    String? type,
    String? accountId,
    String? categoryId,
    String? sharedBudgetId,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.transactions,
      queryParameters: {
        'page': page,
        'limit': limit,
        'type': ?type,
        'accountId': ?accountId,
        'categoryId': ?categoryId,
        'sharedBudgetId': ?sharedBudgetId,
        'startDate': ?startDate,
        'endDate': ?endDate,
        'search': ?search,
      },
    );
    final envelope = response.data['data'] as Map<String, dynamic>;
    final list = (envelope['data'] as List)
        .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
        .toList();
    return (
      data: list,
      total: envelope['total'] as int,
      totalPages: envelope['totalPages'] as int,
    );
  }

  Future<({double income, double expense, double net})> getSummary({
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.transactionsSummary,
      queryParameters: {
        'startDate': ?startDate,
        'endDate': ?endDate,
      },
    );
    final d = response.data['data'] as Map<String, dynamic>;
    return (
      income: (d['income'] as num).toDouble(),
      expense: (d['expense'] as num).toDouble(),
      net: (d['net'] as num).toDouble(),
    );
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    final response =
        await _dio.post(ApiEndpoints.transactions, data: data);
    return TransactionModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTransaction(String id) async {
    await _dio.delete(ApiEndpoints.transactionById(id));
  }

  Future<void> createRecurringTransaction(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.recurringTransactions, data: data);
  }
}
