import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/analytics_models.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';

// Analytics State
class AnalyticsState {
  final bool isLoading;
  final DetailedAnalytics? analytics;
  final String? error;

  const AnalyticsState({
    this.isLoading = false,
    this.analytics,
    this.error,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    DetailedAnalytics? analytics,
    String? error,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      analytics: analytics ?? this.analytics,
      error: error,
    );
  }
}

// Analytics Notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final ApiService _apiService;

  AnalyticsNotifier(this._apiService) : super(const AnalyticsState());

  Future<void> loadDetailedAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.get('/analytics/detailed');
      
      if (response['success'] == true) {
        final analytics = DetailedAnalytics.fromJson(response['data']);
        state = state.copyWith(
          isLoading: false,
          analytics: analytics,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Không thể tải dữ liệu phân tích',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<bool> exportToExcel() async {
    try {
      final response = await _apiService.downloadFile('/analytics/export/excel');
      return response != null;
    } catch (e) {
      throw Exception('Không thể xuất Excel: $e');
    }
  }

  Future<List<ChartData>> getJobViewsChart({int days = 30}) async {
    try {
      final response = await _apiService.get('/analytics/charts/job-views?days=$days');
      
      if (response['success'] == true) {
        return (response['data'] as List)
            .map((item) => ChartData.fromJson(item))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Không thể tải dữ liệu biểu đồ');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải biểu đồ lượt xem: $e');
    }
  }

  Future<List<ChartData>> getApplicationsChart({int months = 12}) async {
    try {
      final response = await _apiService.get('/analytics/charts/applications?months=$months');
      
      if (response['success'] == true) {
        return (response['data'] as List)
            .map((item) => ChartData.fromJson(item))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Không thể tải dữ liệu biểu đồ');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải biểu đồ ứng tuyển: $e');
    }
  }

  Future<List<ChartData>> getFollowersChart({int months = 6}) async {
    try {
      final response = await _apiService.get('/analytics/charts/followers?months=$months');
      
      if (response['success'] == true) {
        return (response['data'] as List)
            .map((item) => ChartData.fromJson(item))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Không thể tải dữ liệu biểu đồ');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải biểu đồ người theo dõi: $e');
    }
  }

  Future<JobDetailedPerformance?> getJobPerformance(int jobId) async {
    try {
      final response = await _apiService.get('/analytics/job-performance/$jobId');
      
      if (response['success'] == true) {
        return JobDetailedPerformance.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Không thể tải dữ liệu hiệu suất công việc');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải hiệu suất công việc: $e');
    }
  }

  Future<AnalyticsSummary> getAnalyticsSummary() async {
    try {
      final response = await _apiService.get('/analytics/summary');
      
      if (response['success'] == true) {
        return AnalyticsSummary.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Không thể tải tóm tắt phân tích');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải tóm tắt phân tích: $e');
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
      // Không throw error cho tracking events để không làm gián đoạn UX
      print('Warning: Could not track event - $e');
    }
  }
}

// Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AnalyticsNotifier(apiService);
});

// Additional providers for specific charts
final jobViewsChartProvider = FutureProvider.family<List<ChartData>, int>((ref, days) async {
  final notifier = ref.read(analyticsProvider.notifier);
  return await notifier.getJobViewsChart(days: days);
});

final applicationsChartProvider = FutureProvider.family<List<ChartData>, int>((ref, months) async {
  final notifier = ref.read(analyticsProvider.notifier);
  return await notifier.getApplicationsChart(months: months);
});

final followersChartProvider = FutureProvider.family<List<ChartData>, int>((ref, months) async {
  final notifier = ref.read(analyticsProvider.notifier);
  return await notifier.getFollowersChart(months: months);
});

final jobPerformanceProvider = FutureProvider.family<JobDetailedPerformance?, int>((ref, jobId) async {
  final notifier = ref.read(analyticsProvider.notifier);
  return await notifier.getJobPerformance(jobId);
});

final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>((ref) async {
  final notifier = ref.read(analyticsProvider.notifier);
  return await notifier.getAnalyticsSummary();
});

// AnalyticsService provider  
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AnalyticsService(apiService);
});
