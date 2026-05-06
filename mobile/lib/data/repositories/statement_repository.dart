import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/statement_model.dart';

class StatementRepository {
  StatementRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<AccountStatementsResponse> getForAccount(String accountId) async {
    final response =
        await _dio.get(ApiEndpoints.accountStatementsList(accountId));
    return AccountStatementsResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<StatementModel> getOne(String id) async {
    final response = await _dio.get(ApiEndpoints.statementById(id));
    return StatementModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<StatementModel> pay(
    String id, {
    required double amount,
    required String fromAccountId,
    DateTime? transactionDate,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.statementPay(id),
      data: {
        'amount': amount,
        'fromAccountId': fromAccountId,
        if (transactionDate != null)
          'transactionDate': transactionDate.toIso8601String(),
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return StatementModel.fromJson(
      data['statement'] as Map<String, dynamic>,
    );
  }
}
