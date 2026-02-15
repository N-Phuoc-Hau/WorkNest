import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/application_model.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import '../utils/token_storage.dart';

class ApplicationNotifier extends StateNotifier<ApplicationsState> {
  final ApplicationService _applicationService;

  ApplicationNotifier(this._applicationService) : super(const ApplicationsState());

  /// Submit job application
  Future<bool> submitApplication({
    required int jobId,
    required String coverLetter,
    File? cvFile,
    XFile? cvXFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('DEBUG ApplicationProvider: Submitting application for job $jobId');
      
      // Đảm bảo có token hợp lệ
      await _ensureValidToken();
      
      final newApplication = await _applicationService.submitApplication(
        jobId: jobId,
        coverLetter: coverLetter,
        cvFile: cvFile,
        cvXFile: cvXFile,
      );
      
      debugPrint('DEBUG ApplicationProvider: Application submitted successfully');
      
      state = state.copyWith(
        myApplications: [newApplication, ...state.myApplications],
        isLoading: false,
      );
      return true;
    } catch (e) {
      debugPrint('DEBUG ApplicationProvider: Error submitting application: $e');
      
      // Kiểm tra nếu lỗi liên quan đến authentication
      if (_isAuthenticationError(e)) {
        await _handleAuthenticationError();
      }
      
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Submit job application with saved CV
  Future<bool> submitApplicationWithSavedCV({
    required int jobId,
    required String coverLetter,
    required String savedCVUrl,
    required String savedCVFileName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('DEBUG ApplicationProvider: Submitting application with saved CV for job $jobId');
      
      // Đảm bảo có token hợp lệ
      await _ensureValidToken();
      
      final newApplication = await _applicationService.submitApplicationWithSavedCV(
        jobId: jobId,
        coverLetter: coverLetter,
        savedCVUrl: savedCVUrl,
        savedCVFileName: savedCVFileName,
      );
      
      debugPrint('DEBUG ApplicationProvider: Application with saved CV submitted successfully');
      
      state = state.copyWith(
        myApplications: [newApplication, ...state.myApplications],
        isLoading: false,
      );
      return true;
    } catch (e) {
      debugPrint('DEBUG ApplicationProvider: Error submitting application with saved CV: $e');
      
      // Kiểm tra nếu lỗi liên quan đến authentication
      if (_isAuthenticationError(e)) {
        await _handleAuthenticationError();
      }
      
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> createApplication({
    required CreateApplicationModel createApplication,
    File? cvFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newApplication = await _applicationService.createApplication(
        jobId: createApplication.jobId,
        coverLetter: createApplication.coverLetter ?? '',
        cvFile: cvFile,
      );
      
      state = state.copyWith(
        myApplications: [newApplication, ...state.myApplications],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> getApplication(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final application = await _applicationService.getApplication(id);
      
      if (application == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Không tìm thấy đơn ứng tuyển',
        );
        return;
      }
      
      // Update the application in the list if it exists
      final updatedMyApplications = state.myApplications.map((app) {
        if (app.id == id) {
          return application;
        }
        return app;
      }).toList();

      state = state.copyWith(
        myApplications: updatedMyApplications,
        selectedApplication: application,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update application (for candidates to edit their application)
  Future<bool> updateApplication(
    int id, {
    String? coverLetter,
    String? cvUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedApplication = await _applicationService.updateApplication(
        id,
        coverLetter: coverLetter,
        cvUrl: cvUrl,
      );
      
      // Update application in the lists
      final updatedMyApplications = state.myApplications.map((app) {
        if (app.id == id) {
          return updatedApplication;
        }
        return app;
      }).toList();

      state = state.copyWith(
        myApplications: updatedMyApplications,
        selectedApplication: updatedApplication,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> getMyApplications({
    int page = 1,
    int pageSize = 10,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      // Kiểm tra và refresh token nếu cần
      await _ensureValidToken();
      
      final result = await _applicationService.getMyApplications(
        page: page,
        pageSize: pageSize,
      );

      final newApplications = result['applications'] as List<ApplicationModel>;
      
      if (loadMore && page > 1) {
        // Append to existing applications for pagination
        state = state.copyWith(
          myApplications: [...state.myApplications, ...newApplications],
          isLoading: false,
        );
      } else {
        // Replace applications for first load
        state = state.copyWith(
          myApplications: newApplications,
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('DEBUG ApplicationProvider: Error in getMyApplications: $e');
      
      // Kiểm tra nếu lỗi liên quan đến authentication
      if (_isAuthenticationError(e)) {
        await _handleAuthenticationError();
      }
      
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  Future<bool> updateApplicationStatus(
    int id,
    UpdateApplicationStatusModel updateStatus,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _applicationService.updateApplicationStatus(id, updateStatus);
      
      // Update application status in the lists
      final statusEnum = _parseStatus(updateStatus.status);
      
      final updatedApplications = state.applications.map((app) {
        if (app.id == id) {
          return app.copyWith(status: statusEnum);
        }
        return app;
      }).toList();

      final updatedMyApplications = state.myApplications.map((app) {
        if (app.id == id) {
          return app.copyWith(status: statusEnum);
        }
        return app;
      }).toList();

      state = state.copyWith(
        applications: updatedApplications,
        myApplications: updatedMyApplications,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> getJobApplications(
    int jobId, {
    int page = 1,
    int pageSize = 10,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await _applicationService.getJobApplications(
        jobId,
        page: page,
        pageSize: pageSize,
      );

      final newApplications = result['applications'] as List<ApplicationModel>;
      
      if (loadMore && page > 1) {
        // Append to existing applications for pagination
        state = state.copyWith(
          applications: [...state.applications, ...newApplications],
          isLoading: false,
        );
      } else {
        // Replace applications for first load
        state = state.copyWith(
          applications: newApplications,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> deleteApplication(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _applicationService.deleteApplication(id);
      
      state = state.copyWith(
        applications: state.applications.where((app) => app.id != id).toList(),
        myApplications: state.myApplications.where((app) => app.id != id).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  ApplicationStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.pending;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  List<ApplicationModel> getApplicationsByStatus(ApplicationStatus status) {
    return state.myApplications.where((app) => app.status == status).toList();
  }

  int getApplicationsCountByStatus(ApplicationStatus status) {
    return getApplicationsByStatus(status).length;
  }

  /// Đảm bảo có token hợp lệ trước khi gọi API
  Future<void> _ensureValidToken() async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
    }

    // Kiểm tra token có hết hạn không
    final isExpired = await TokenStorage.isAccessTokenExpired();
    if (isExpired) {
      debugPrint('DEBUG ApplicationProvider: Access token expired, attempting refresh');
      
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại');
      }

      // Refresh token sẽ được xử lý bởi AuthInterceptor
      // Ở đây chỉ cần kiểm tra refresh token có tồn tại không
      final isRefreshExpired = await TokenStorage.isRefreshTokenExpired();
      if (isRefreshExpired) {
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại');
      }
    }
  }

  /// Kiểm tra xem error có phải lỗi authentication không
  bool _isAuthenticationError(dynamic error) {
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      return message.contains('unauthorized') ||
             message.contains('token') ||
             message.contains('authentication') ||
             message.contains('không tìm thấy người dùng') ||
             message.contains('phiên đăng nhập');
    }
    return false;
  }

  /// Xử lý lỗi authentication
  Future<void> _handleAuthenticationError() async {
    debugPrint('DEBUG ApplicationProvider: Handling authentication error');
    
    // Xóa tokens cũ
    await TokenStorage.clearTokens();
    
    // TODO: Trigger logout in auth provider
    // ref.read(authProvider.notifier).logout();
  }

  /// Lấy error message phù hợp
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      
      if (message.contains('không tìm thấy người dùng')) {
        return 'Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại';
      }
      
      if (message.contains('unauthorized') || message.contains('token')) {
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại';
      }
      
      return message.replaceFirst('Exception: ', '');
    }
    
    return error.toString();
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final applicationServiceProvider = Provider<ApplicationService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApplicationService(authService: authService);
});

final applicationProvider = StateNotifierProvider<ApplicationNotifier, ApplicationsState>((ref) {
  return ApplicationNotifier(ref.watch(applicationServiceProvider));
});
