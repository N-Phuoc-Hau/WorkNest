import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/analytics_models.dart';
import 'api_service.dart';

class AnalyticsService {
  final ApiService _apiService;

  AnalyticsService(this._apiService);

  Future<DetailedAnalytics> getDetailedAnalytics() async {
    try {
      print('📊 AnalyticsService: *** Getting Detailed Analytics ***');
      print('📊 AnalyticsService: Endpoint: /analytics/detailed');
      
      final response = await _apiService.get('/api/analytics/detailed');
      
      print('📊 AnalyticsService: Response received');
      print('📊 AnalyticsService: Success: ${response['success']}');
      
      if (response['success'] == true) {
        print('📊 AnalyticsService: Parsing DetailedAnalytics from JSON...');
        final analytics = DetailedAnalytics.fromJson(response['data']);
        print('📊 AnalyticsService: ✅ DetailedAnalytics parsed successfully');
        return analytics;
      } else {
        print('📊 AnalyticsService: ❌ API Error: ${response['message']}');
        throw Exception(response['message'] ?? 'Lỗi khi lấy dữ liệu phân tích');
      }
    } catch (e) {
      print('📊 AnalyticsService: ❌ Exception in getDetailedAnalytics: $e');
      print('📊 AnalyticsService: Exception type: ${e.runtimeType}');
      throw Exception('Lỗi khi lấy dữ liệu phân tích: $e');
    }
  }

  Future<JobDetailedPerformance> getJobPerformance(int jobId) async {
    try {
      print('📊 AnalyticsService: *** Getting Job Performance ***');
      print('📊 AnalyticsService: JobId: $jobId');
      print('📊 AnalyticsService: Endpoint: /analytics/job-performance/$jobId');
      
      final response = await _apiService.get('/api/analytics/job-performance/$jobId');
      
      print('📊 AnalyticsService: Job performance response received');
      print('📊 AnalyticsService: Success: ${response['success']}');
      
      if (response['success'] == true) {
        print('📊 AnalyticsService: Parsing JobDetailedPerformance from JSON...');
        final jobPerformance = JobDetailedPerformance.fromJson(response['data']);
        print('📊 AnalyticsService: ✅ JobDetailedPerformance parsed successfully');
        return jobPerformance;
      } else {
        print('📊 AnalyticsService: ❌ API Error: ${response['message']}');
        throw Exception(response['message'] ?? 'Lỗi khi lấy hiệu suất công việc');
      }
    } catch (e) {
      print('📊 AnalyticsService: ❌ Exception in getJobPerformance: $e');
      print('📊 AnalyticsService: Exception type: ${e.runtimeType}');
      throw Exception('Lỗi khi lấy hiệu suất công việc: $e');
    }
  }

  Future<List<ChartData>> getJobViewsChart({int days = 30}) async {
    try {
      print('📊 AnalyticsService: *** Getting Job Views Chart ***');
      print('📊 AnalyticsService: Days: $days');
      print('📊 AnalyticsService: Endpoint: /analytics/charts/job-views?days=$days');
      
      final response = await _apiService.get('/api/analytics/charts/job-views?days=$days');
      
      print('📊 AnalyticsService: Job views chart response received');
      print('📊 AnalyticsService: Success: ${response['success']}');
      
      if (response['success'] == true) {
        print('📊 AnalyticsService: Parsing ChartData list from JSON...');
        final chartData = (response['data'] as List<dynamic>)
            .map((e) => ChartData.fromJson(e))
            .toList();
        print('📊 AnalyticsService: ✅ ${chartData.length} ChartData items parsed successfully');
        return chartData;
      } else {
        print('📊 AnalyticsService: ❌ API Error: ${response['message']}');
        throw Exception(response['message'] ?? 'Lỗi khi lấy dữ liệu biểu đồ');
      }
    } catch (e) {
      print('📊 AnalyticsService: ❌ Exception in getJobViewsChart: $e');
      print('📊 AnalyticsService: Exception type: ${e.runtimeType}');
      throw Exception('Lỗi khi lấy dữ liệu biểu đồ: $e');
    }
  }

  Future<List<ChartData>> getApplicationsChart({int months = 12}) async {
    try {
      final response = await _apiService.get('/api/analytics/charts/applications?months=$months');
      
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
      final response = await _apiService.get('/api/analytics/charts/followers?months=$months');
      
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
      print('📊 AnalyticsService: *** Getting Analytics Summary ***');
      print('📊 AnalyticsService: Endpoint: /api/analytics/summary');
      
      final response = await _apiService.get('/api/analytics/summary');
      
      print('📊 AnalyticsService: Summary response received');
      print('📊 AnalyticsService: Success: ${response['success']}');
      print('📊 AnalyticsService: Response data keys: ${response['data']?.keys?.toList()}');
      
      if (response['success'] == true) {
        print('📊 AnalyticsService: Parsing AnalyticsSummary from JSON...');
        final summary = AnalyticsSummary.fromJson(response['data']);
        print('📊 AnalyticsService: ✅ AnalyticsSummary parsed successfully');
        return summary;
      } else {
        print('📊 AnalyticsService: ❌ API Error: ${response['message']}');
        throw Exception(response['message'] ?? 'Lỗi khi lấy tóm tắt phân tích');
      }
    } catch (e) {
      print('📊 AnalyticsService: ❌ Exception in getAnalyticsSummary: $e');
      print('📊 AnalyticsService: Exception type: ${e.runtimeType}');
      if (e is Error) {
        print('📊 AnalyticsService: Stack trace: ${e.stackTrace}');
      }
      throw Exception('Lỗi khi lấy tóm tắt phân tích: $e');
    }
  }

  Future<SummaryAnalytics> getSummaryAnalytics() async {
    try {
      print('📊 AnalyticsService: *** Getting Summary Analytics ***');
      print('📊 AnalyticsService: Endpoint: /api/analytics/summary');
      
      final response = await _apiService.get('/api/analytics/summary');
      
      print('📊 AnalyticsService: Summary analytics response received');
      print('📊 AnalyticsService: Success: ${response['success']}');
      print('📊 AnalyticsService: Response data keys: ${response['data']?.keys?.toList()}');
      
      if (response['success'] == true) {
        print('📊 AnalyticsService: Parsing SummaryAnalytics from JSON...');
        final summary = SummaryAnalytics.fromJson(response['data']);
        print('📊 AnalyticsService: ✅ SummaryAnalytics parsed successfully');
        print('📊 AnalyticsService: Company: ${summary.companyInfo.companyName}');
        print('📊 AnalyticsService: Total Jobs: ${summary.jobStats.totalJobsPosted}');
        print('📊 AnalyticsService: Total Applications: ${summary.applicationStats.totalApplicationsReceived}');
        return summary;
      } else {
        print('📊 AnalyticsService: ❌ API Error: ${response['message']}');
        throw Exception(response['message'] ?? 'Lỗi khi lấy tóm tắt phân tích');
      }
    } catch (e) {
      print('📊 AnalyticsService: ❌ Exception in getSummaryAnalytics: $e');
      print('📊 AnalyticsService: Exception type: ${e.runtimeType}');
      if (e is Error) {
        print('📊 AnalyticsService: Stack trace: ${e.stackTrace}');
      }
      throw Exception('Lỗi khi lấy tóm tắt phân tích: $e');
    }
  }

  Future<void> exportToExcel() async {
    try {
      print('📊 AnalyticsService: *** Exporting to Excel ***');
      
      final dio = Dio();
      final baseUrl = _apiService.baseUrl;
      final token = await _apiService.getAuthToken();
      
      print('📊 AnalyticsService: Base URL: $baseUrl');
      print('📊 AnalyticsService: Token available: ${token != null}');
      
      if (token == null) {
        print('📊 AnalyticsService: ❌ No auth token found');
        throw Exception('Không tìm thấy token xác thực');
      }

      print('📊 AnalyticsService: Making request to: $baseUrl/api/analytics/export/excel');
      final response = await dio.get(
        '$baseUrl/api/analytics/export/excel',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.bytes,
        ),
      );

      print('📊 AnalyticsService: Export response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('📊 AnalyticsService: ✅ Excel file received, saving...');
        await _saveExcelFile(response.data);
        print('📊 AnalyticsService: ✅ Excel file saved successfully');
      } else {
        print('📊 AnalyticsService: ❌ Export failed with status: ${response.statusCode}');
        throw Exception('Lỗi khi tải file Excel');
      }
    } catch (e) {
      print('📊 AnalyticsService: ❌ Exception in exportToExcel: $e');
      print('📊 AnalyticsService: Exception type: ${e.runtimeType}');
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
      print('📊 AnalyticsService: *** Tracking Event ***');
      print('📊 AnalyticsService: Type: $type');
      print('📊 AnalyticsService: Action: $action');
      print('📊 AnalyticsService: TargetId: $targetId');
      print('📊 AnalyticsService: Metadata: $metadata');
      
      await _apiService.post('/analytics/track-event', data: {
        'type': type,
        'action': action,
        'targetId': targetId,
        'metadata': metadata,
      });
      
      print('📊 AnalyticsService: ✅ Event tracked successfully');
    } catch (e) {
      // Log error but don't throw to avoid disrupting user experience
      print('📊 AnalyticsService: ❌ Error tracking event: $e');
      print('📊 AnalyticsService: Exception type: ${e.runtimeType}');
    }
  }
}
