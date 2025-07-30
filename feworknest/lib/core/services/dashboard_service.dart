import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class DashboardService {
  late final Dio _dio;

  DashboardService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  // Get admin dashboard
  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await _dio.get(ApiConstants.adminDashboard);
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể tải dashboard',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Get recruiter dashboard
  Future<Map<String, dynamic>> getRecruiterDashboard() async {
    try {
      final response = await _dio.get(ApiConstants.recruiterDashboard);
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể tải dashboard',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Get candidate dashboard
  Future<Map<String, dynamic>> getCandidateDashboard() async {
    try {
      final response = await _dio.get(ApiConstants.candidateDashboard);
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể tải dashboard',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Track analytics event
  Future<Map<String, dynamic>> trackEvent({
    required String type,
    required String action,
    String? targetId,
    String? metadata,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.trackEvent,
        data: {
          'type': type,
          'action': action,
          'targetId': targetId,
          'metadata': metadata,
        },
      );

      return {
        'success': true,
        'message': response.data['message'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể track event',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }
} 