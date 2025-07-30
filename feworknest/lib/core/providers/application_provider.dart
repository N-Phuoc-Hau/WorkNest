import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../models/application_model.dart';
import '../services/application_service.dart';

class ApplicationNotifier extends StateNotifier<ApplicationsState> {
  final ApplicationService _applicationService;

  ApplicationNotifier(this._applicationService) : super(const ApplicationsState());

  Future<bool> createApplication({
    required CreateApplicationModel createApplication,
    File? cvFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newApplication = await _applicationService.createApplication(
        createApplication: createApplication,
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
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
