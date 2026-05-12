import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/family_model.dart';

class FamilyRepository {
  FamilyRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<FamilyGroupModel>> getGroups() async {
    final response = await _dio.get(ApiEndpoints.familyGroups);
    final list = response.data['data'] as List? ?? [];
    return list
        .map((e) => FamilyGroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FamilyGroupModel> createGroup({
    required String name,
    String? icon,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.familyGroups,
      data: {'name': name, 'icon': ?icon},
    );
    return FamilyGroupModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<FamilyGroupModel> getGroupDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.familyGroupById(id));
    return FamilyGroupModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<FamilyInviteModel> sendInvite({
    required String groupId,
    required String email,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.familyGroupInvite(groupId),
      data: {'email': email},
    );
    return FamilyInviteModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<FamilyGroupModel> acceptInvite(String token) async {
    final response =
        await _dio.post(ApiEndpoints.familyInviteAccept(token));
    return FamilyGroupModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> rejectInvite(String token) async {
    await _dio.post(ApiEndpoints.familyInviteReject(token));
  }

  Future<SharedBudgetModel> createSharedBudget({
    required String groupId,
    required String categoryId,
    required String name,
    required double amount,
    required String startDate,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.familyGroupBudgets(groupId),
      data: {
        'categoryId': categoryId,
        'name': name,
        'amount': amount,
        'startDate': startDate,
      },
    );
    return SharedBudgetModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<List<SharedBudgetModel>> getSharedBudgets(String groupId) async {
    final response =
        await _dio.get(ApiEndpoints.familyGroupBudgets(groupId));
    final list = response.data['data'] as List? ?? [];
    return list
        .map((e) => SharedBudgetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContributionReportModel> getContributions({
    required String groupId,
    String? period,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.familyGroupContributions(groupId),
      queryParameters: {'period': ?period},
    );
    return ContributionReportModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    await _dio.delete(ApiEndpoints.familyGroupMember(groupId, userId));
  }

  Future<void> deleteGroup(String groupId) async {
    await _dio.delete(ApiEndpoints.familyGroupById(groupId));
  }

  Future<void> deleteSharedBudget({
    required String groupId,
    required String budgetId,
  }) async {
    await _dio.delete(ApiEndpoints.familyGroupBudgetById(groupId, budgetId));
  }
}
