import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/account_model.dart';

class AccountRepository {
  AccountRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<AccountModel>> getAccounts({bool includeArchived = false}) async {
    final response = await _dio.get(
      ApiEndpoints.accounts,
      queryParameters: includeArchived ? {'includeArchived': true} : null,
    );
    final list = response.data['data'] as List;
    return list
        .map((a) => AccountModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<AccountModel> getAccount(String id) async {
    final response = await _dio.get(ApiEndpoints.accountById(id));
    return AccountModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<AccountModel> createAccount(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiEndpoints.accounts, data: data);
    return AccountModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<AccountModel> updateAccount(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch(ApiEndpoints.accountById(id), data: data);
    return AccountModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteAccount(String id) async {
    await _dio.delete(ApiEndpoints.accountById(id));
  }

  Future<void> archiveAccount(String id) async {
    await _dio.patch(ApiEndpoints.accountArchive(id));
  }

  Future<void> restoreAccount(String id) async {
    await _dio.patch(ApiEndpoints.accountRestore(id));
  }

  Future<void> setDefaultAccount(String id) async {
    await _dio.patch(ApiEndpoints.accountSetDefault(id));
  }
}
