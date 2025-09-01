import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/api_service.dart';
import '../models/analytics_models.dart';

class AnalyticsService {
  final ApiService _apiService;

  AnalyticsService(this._apiService);

  Future<DetailedAnalytics> getDetailedAnalytics() async {
    try {
      final response = await _apiService.get('/analytics/detailed');
      
      if (response['success'] == true) {
        return DetailedAnalytics.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi lấy dữ liệu phân tích');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu phân tích: $e');
    }
  }

  Future<JobDetailedPerformance> getJobPerformance(int jobId) async {
    try {
      final response = await _apiService.get('/analytics/job-performance/$jobId');
      
      if (response['success'] == true) {
        return JobDetailedPerformance.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi lấy hiệu suất công việc');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy hiệu suất công việc: $e');
    }
  }

  Future<List<ChartData>> getJobViewsChart({int days = 30}) async {
    try {
      final response = await _apiService.get('/analytics/charts/job-views?days=$days');
      
      if (response['success'] == true) {
        return (response['data'] as List<dynamic>)
            .map((e) => ChartData.fromJson(e))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi lấy dữ liệu biểu đồ');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu biểu đồ: $e');
    }
  }

  Future<List<ChartData>> getApplicationsChart({int months = 12}) async {
    try {
      final response = await _apiService.get('/analytics/charts/applications?months=$months');
      
      if (response['success'] == true) {
        return (response['data'] as List<dynamic>)
            .map((e) => ChartData.fromJson(e))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi lấy dữ liệu biểu đồ');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu biểu đồ: $e');
    }
  }

  Future<List<ChartData>> getFollowersChart({int months = 6}) async {
    try {
      final response = await _apiService.get('/analytics/charts/followers?months=$months');
      
      if (response['success'] == true) {
        return (response['data'] as List<dynamic>)
            .map((e) => ChartData.fromJson(e))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi lấy dữ liệu biểu đồ');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu biểu đồ: $e');
    }
  }

  Future<AnalyticsSummary> getAnalyticsSummary() async {
    try {
      final response = await _apiService.get('/analytics/summary');
      
      if (response['success'] == true) {
        return AnalyticsSummary.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi lấy tóm tắt phân tích');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy tóm tắt phân tích: $e');
    }
  }

  Future<void> exportToExcel() async {
    try {
      final dio = Dio();
      final apiService = _apiService as ApiService;
      final baseUrl = apiService.baseUrl;
      final token = await apiService.getAuthToken();
      
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await dio.get(
        '$baseUrl/analytics/export/excel',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        await _saveExcelFile(response.data);
      } else {
        throw Exception('Lỗi khi tải file Excel');
      }
    } catch (e) {
      throw Exception('Lỗi khi xuất Excel: $e');
    }
  }

  Future<void> _saveExcelFile(List<int> bytes) async {
    try {
      if (kIsWeb) {
        // For web platform
        _downloadFileWeb(bytes);
      } else {
        // For mobile platforms
        await _saveFileToDevice(bytes);
      }
    } catch (e) {
      throw Exception('Lỗi khi lưu file: $e');
    }
  }

  void _downloadFileWeb(List<int> bytes) {
    // Web platform download implementation
    if (kIsWeb) {
      // This would need to be implemented with web-specific code
      throw UnimplementedError('Web download not implemented yet');
    }
  }

  Future<void> _saveFileToDevice(List<int> bytes) async {
    try {
      Directory? directory;
      
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Không thể tìm thấy thư mục lưu file');
      }

      final fileName = 'Analytics_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      // Show success message or notification
      debugPrint('File saved to: ${file.path}');
    } catch (e) {
      throw Exception('Lỗi khi lưu file: $e');
    }
  }

  Future<void> trackEvent({
    required String type,
    required String action,
    String? targetId,
    String? metadata,
  }) async {
    try {
      await _apiService.post('/analytics/track-event', data: {
        'type': type,
        'action': action,
        'targetId': targetId,
        'metadata': metadata,
      });
    } catch (e) {
      // Log error but don't throw to avoid disrupting user experience
      debugPrint('Error tracking event: $e');
    }
  }
}
