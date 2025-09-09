import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/analytics_models.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';

// Analytics State
class AnalyticsState {
  final bool isLoading;
  final DetailedAnalytics? analytics;
  final SummaryAnalytics? summary;
  final String? error;

  const AnalyticsState({
    this.isLoading = false,
    this.analytics,
    this.summary,
    this.error,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    DetailedAnalytics? analytics,
    SummaryAnalytics? summary,
    String? error,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      analytics: analytics ?? this.analytics,
      summary: summary ?? this.summary,
      error: error,
    );
  }
}

// Analytics Notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsService _analyticsService;

  AnalyticsNotifier(this._analyticsService) : super(const AnalyticsState()) {
    print('🔥 AnalyticsNotifier: Constructor called');
  }

  Future<void> loadDetailedAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('🔥 Analytics Provider: Calling analytics service for detailed data');
      final analytics = await _analyticsService.getDetailedAnalytics();
      print('🔥 Analytics Provider: Detailed analytics loaded successfully');
      state = state.copyWith(
        isLoading: false,
        analytics: analytics,
      );
    } catch (e) {
      print('🔥 Analytics Provider: Exception occurred: $e');
      print('🔥 Analytics Provider: Exception type: ${e.runtimeType}');
      if (e is Error) {
        print('🔥 Analytics Provider: Stack trace: ${e.stackTrace}');
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<void> loadSummaryAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('🔥 Analytics Provider: Loading summary analytics for home screen');
      final summary = await _analyticsService.getSummaryAnalytics();
      print('🔥 Analytics Provider: Summary data loaded successfully');
      state = state.copyWith(
        isLoading: false,
        summary: summary,
      );
    } catch (e) {
      print('🔥 Analytics Provider: Summary exception: $e');
      print('🔥 Analytics Provider: Summary exception type: ${e.runtimeType}');
      if (e is Error) {
        print('🔥 Analytics Provider: Summary stack trace: ${e.stackTrace}');
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<bool> exportToExcel() async {
    try {
      await _analyticsService.exportToExcel();
      return true;
    } catch (e) {
      throw Exception('Không thể xuất Excel: $e');
    }
  }

  Future<List<ChartData>> getJobViewsChart({int days = 30}) async {
    try {
      return await _analyticsService.getJobViewsChart(days: days);
    } catch (e) {
      throw Exception('Lỗi khi tải biểu đồ lượt xem: $e');
    }
  }

  Future<List<ChartData>> getApplicationsChart({int months = 12}) async {
    try {
      return await _analyticsService.getApplicationsChart(months: months);
    } catch (e) {
      throw Exception('Lỗi khi tải biểu đồ ứng tuyển: $e');
    }
  }

  Future<List<ChartData>> getFollowersChart({int months = 6}) async {
    try {
      return await _analyticsService.getFollowersChart(months: months);
    } catch (e) {
      throw Exception('Lỗi khi tải biểu đồ người theo dõi: $e');
    }
  }

  Future<JobDetailedPerformance> getJobPerformance(int jobId) async {
    try {
      return await _analyticsService.getJobPerformance(jobId);
    } catch (e) {
      throw Exception('Lỗi khi tải hiệu suất công việc: $e');
    }
  }
}

// Analytics Service Provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return AnalyticsService(apiService);
});

// Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  print('🔥 Analytics Provider: Creating provider instance');
  final analyticsService = ref.read(analyticsServiceProvider);
  return AnalyticsNotifier(analyticsService);
});

// Additional helper providers for individual chart data
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

final jobPerformanceProvider = FutureProvider.family<JobDetailedPerformance, int>((ref, jobId) async {
  final notifier = ref.read(analyticsProvider.notifier);
  return await notifier.getJobPerformance(jobId);
});

final excelExportProvider = FutureProvider<bool>((ref) async {
  final notifier = ref.read(analyticsProvider.notifier);
  return await notifier.exportToExcel();
});
