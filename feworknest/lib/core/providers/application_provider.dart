import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/application_model.dart';
import '../services/application_service.dart';
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
      print('DEBUG ApplicationProvider: Submitting application for job $jobId');
      
      // Check authentication status
      final accessToken = await TokenStorage.getAccessToken();
      print('DEBUG ApplicationProvider: Access token available: ${accessToken != null}');
      if (accessToken != null) {
        print('DEBUG ApplicationProvider: Token length: ${accessToken.length}');
      }
      
      final newApplication = await _applicationService.submitApplication(
        jobId: jobId,
        coverLetter: coverLetter,
        cvFile: cvFile,
        cvXFile: cvXFile,
      );
      
      print('DEBUG ApplicationProvider: Application submitted successfully');
      
      state = state.copyWith(
        myApplications: [newApplication, ...state.myApplications],
        isLoading: false,
      );
      return true;
    } catch (e) {
      print('DEBUG ApplicationProvider: Error submitting application: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
}

// Providers
final applicationServiceProvider = Provider<ApplicationService>((ref) => ApplicationService());

final applicationProvider = StateNotifierProvider<ApplicationNotifier, ApplicationsState>((ref) {
  return ApplicationNotifier(ref.watch(applicationServiceProvider));
});
