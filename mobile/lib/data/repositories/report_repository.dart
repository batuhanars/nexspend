import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/report_model.dart';

class ReportRepository {
  ReportRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<ExpenseDistributionItem>> getExpenseDistribution({
    String? startDate,
    String? endDate,
    String? period,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.reportsExpenseDistribution,
      queryParameters: {
        'period': ?period,
        'startDate': ?startDate,
        'endDate': ?endDate,
      },
    );
    final list = response.data['data'] as List;
    return list
        .map((e) => ExpenseDistributionItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CashFlowItem>> getCashFlow({
    String? startDate,
    String? endDate,
    String? period,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.reportsCashFlow,
      queryParameters: {
        'period': ?period,
        'startDate': ?startDate,
        'endDate': ?endDate,
      },
    );
    final list = response.data['data'] as List;
    return list
        .map((e) => CashFlowItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrendItem>> getTrends({
    String? period,
  }) async {
    // GEÇİCİ: backend /reports/trends kategori-bazlı trend listesi değil, toplam
    // özet + top kategoriler içeren tek bir NESNE döndürüyor (sözleşme uyuşmazlığı).
    // Per-kategori trend backend'e eklenene dek (Option A) bu bölümü gizli tutmak
    // için boş liste dönüyoruz; aksi halde `as List?` cast'i TypeError fırlatıp tüm
    // rapor ekranını "yüklenemedi" durumuna düşürüyordu.
    return const <TrendItem>[];
  }
}
