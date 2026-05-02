import 'package:dio/dio.dart';
import '../models/receipt_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class ReceiptRepository {
  const ReceiptRepository({required ApiClient apiClient})
      : _client = apiClient;

  final ApiClient _client;

  Future<ReceiptParseResult> scan(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'receipt.jpg'),
    });
    final response = await _client.dio.post(
      ApiEndpoints.receiptsScan,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return ReceiptParseResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> confirmAndCreateTransaction(
    String receiptId,
    Map<String, dynamic> data,
  ) async {
    await _client.dio.post(
      ApiEndpoints.receiptCreateTransaction(receiptId),
      data: data,
    );
  }

  Future<ReceiptParseResult> updateReceipt(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.patch(
      ApiEndpoints.receiptById(id),
      data: data,
    );
    return ReceiptParseResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<ReceiptHistoryModel>> getHistory() async {
    final response = await _client.dio.get(ApiEndpoints.receipts);
    final list = response.data['data'] as List? ?? [];
    return list
        .map((e) => ReceiptHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(String id) async {
    await _client.dio.delete(ApiEndpoints.receiptById(id));
  }
}
