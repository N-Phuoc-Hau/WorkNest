import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';

// Dashboard State
class DashboardState {
  final Map<String, dynamic>? dashboardData;
  final bool isLoading;
  final String? error;
  final String userRole;

  const DashboardState({
    this.dashboardData,
    this.isLoading = false,
    this.error,
    this.userRole = 'candidate',
  });

  DashboardState copyWith({
    Map<String, dynamic>? dashboardData,
    bool? isLoading,
    String? error,
    String? userRole,
  }) {
    return DashboardState(
      dashboardData: dashboardData ?? this.dashboardData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userRole: userRole ?? this.userRole,
    );
  }
}

// Dashboard Notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardService _dashboardService;

  DashboardNotifier(this._dashboardService) : super(const DashboardState());

  // Load dashboard based on user role
  Future<void> loadDashboard(String userRole) async {
    state = state.copyWith(isLoading: true, error: null, userRole: userRole);

    try {
      Map<String, dynamic> result;
      
      switch (userRole) {
        case 'admin':
          result = await _dashboardService.getAdminDashboard();
          break;
        case 'recruiter':
          result = await _dashboardService.getRecruiterDashboard();
          break;
        case 'candidate':
        default:
          result = await _dashboardService.getCandidateDashboard();
          break;
      }

      if (result['success'] == true) {
        state = state.copyWith(
          dashboardData: result['data'],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result['message'],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Có lỗi xảy ra: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // Track analytics event
  Future<void> trackEvent({
    required String type,
    required String action,
    String? targetId,
    String? metadata,
  }) async {
    try {
      await _dashboardService.trackEvent(
        type: type,
        action: action,
        targetId: targetId,
        metadata: metadata,
      );
    } catch (e) {
      // Silently handle tracking errors
      print('Error tracking event: $e');
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh dashboard
  Future<void> refresh() async {
    await loadDashboard(state.userRole);
  }
}

// Providers
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return DashboardNotifier(dashboardService);
}); 