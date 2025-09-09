import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/application_model.dart';
import '../services/application_service.dart';

class RecruiterApplicantsState {
  final List<ApplicationModel> applicants;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final String? searchQuery;
  final String? statusFilter;

  const RecruiterApplicantsState({
    this.applicants = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 0,
    this.totalCount = 0,
    this.searchQuery,
    this.statusFilter,
  });

  RecruiterApplicantsState copyWith({
    List<ApplicationModel>? applicants,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    String? searchQuery,
    String? statusFilter,
  }) {
    return RecruiterApplicantsState(
      applicants: applicants ?? this.applicants,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Don't use ?? this.error because null is a valid value
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class RecruiterApplicantsNotifier extends StateNotifier<RecruiterApplicantsState> {
  final ApplicationService _applicationService;

  RecruiterApplicantsNotifier(this._applicationService) : super(const RecruiterApplicantsState());

  Future<void> loadJobApplicants(
    int? jobId, {
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      print('DEBUG RecruiterApplicantsProvider: Loading job applicants with params:');
      print('  - jobId: $jobId');
      print('  - page: $page');
      print('  - pageSize: $pageSize');
      print('  - status: $status');
      print('  - loadMore: $loadMore');

      final result = await _applicationService.getMyJobApplications(
        page: page,
        pageSize: pageSize,
        status: status,
        jobId: jobId,
      );

      print('DEBUG RecruiterApplicantsProvider: API call successful');
      print('  - Result keys: ${result.keys.toList()}');

      final newApplicants = result['applications'] as List<ApplicationModel>;
      final totalCount = result['totalCount'] as int;
      final totalPages = result['totalPages'] as int;

      print('DEBUG RecruiterApplicantsProvider: Parsed data:');
      print('  - newApplicants count: ${newApplicants.length}');
      print('  - totalCount: $totalCount');
      print('  - totalPages: $totalPages');

      if (loadMore && page > 1) {
        // Append to existing applicants for pagination
        print('DEBUG RecruiterApplicantsProvider: Setting state with loadMore=true');
        state = state.copyWith(
          applicants: [...state.applicants, ...newApplicants],
          currentPage: page,
          totalPages: totalPages,
          totalCount: totalCount,
          isLoading: false,
          error: null, // Clear error on success
          searchQuery: search,
          statusFilter: status,
        );
        print('DEBUG RecruiterApplicantsProvider: State updated successfully with ${state.applicants.length} total applicants');
      } else {
        // Replace applicants for first load
        print('DEBUG RecruiterApplicantsProvider: Setting state with loadMore=false');
        state = state.copyWith(
          applicants: newApplicants,
          currentPage: page,
          totalPages: totalPages,
          totalCount: totalCount,
          isLoading: false,
          error: null, // Clear error on success
          searchQuery: search,
          statusFilter: status,
        );
        print('DEBUG RecruiterApplicantsProvider: State updated successfully with ${state.applicants.length} applicants');
        print('DEBUG RecruiterApplicantsProvider: Final state - error: ${state.error}, isLoading: ${state.isLoading}');
      }
    } catch (e) {
      print('DEBUG RecruiterApplicantsProvider: Error loading job applicants: $e');
      print('DEBUG RecruiterApplicantsProvider: Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('DEBUG RecruiterApplicantsProvider: Exception details: ${e.toString()}');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi tải danh sách ứng viên: $e',
      );
    }
  }

  Future<bool> updateApplicantStatus(
    int applicationId,
    UpdateApplicationStatusModel updateStatus,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _applicationService.updateApplicationStatus(applicationId, updateStatus);
      
      // Update application status in the list
      final statusEnum = _parseStatus(updateStatus.status);
      
      final updatedApplicants = state.applicants.map((app) {
        if (app.id == applicationId) {
          return app.copyWith(status: statusEnum);
        }
        return app;
      }).toList();

      state = state.copyWith(
        applicants: updatedApplicants,
        isLoading: false,
        error: null, // Clear error on success
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

  Future<bool> deleteApplication(int applicationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _applicationService.deleteApplication(applicationId);
      
      state = state.copyWith(
        applicants: state.applicants.where((app) => app.id != applicationId).toList(),
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

  Future<void> searchApplicants(
    int? jobId, {
    String? search,
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    await loadJobApplicants(
      jobId,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
    );
  }

  Future<void> loadMoreApplicants(int? jobId) async {
    if (state.currentPage < state.totalPages) {
      await loadJobApplicants(
        jobId,
        page: state.currentPage + 1,
        pageSize: 10,
        search: state.searchQuery,
        status: state.statusFilter,
        loadMore: true,
      );
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

  void clearFilters() {
    state = state.copyWith(
      searchQuery: null,
      statusFilter: null,
    );
  }

  List<ApplicationModel> getApplicantsByStatus(ApplicationStatus status) {
    return state.applicants.where((app) => app.status == status).toList();
  }

  int getApplicantsCountByStatus(ApplicationStatus status) {
    return getApplicantsByStatus(status).length;
  }

  List<ApplicationModel> getFilteredApplicants() {
    List<ApplicationModel> filtered = state.applicants;

    // Filter by status if specified
    if (state.statusFilter != null && state.statusFilter!.isNotEmpty) {
      final status = _parseStatus(state.statusFilter!);
      filtered = filtered.where((app) => app.status == status).toList();
    }

    // Filter by search query if specified
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      final query = state.searchQuery!.toLowerCase();
      filtered = filtered.where((app) {
        return app.applicantName.toLowerCase().contains(query) ||
               app.jobTitle.toLowerCase().contains(query) ||
               app.applicantEmail.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  // Get application by ID
  Future<ApplicationModel?> getApplicationById(String applicationId) async {
    try {
      // First check if we have it in current state
      // final existingApp = state.applicants
      //     .where((app) => app.id.toString() == applicationId)
      //     .firstOrNull;
      
      // if (existingApp != null) {
      //   print('DEBUG Provider: Found in state - Name: "${existingApp.applicantName}", Email: "${existingApp.applicantEmail}"');
      //   return existingApp;
      // }

      // print('DEBUG Provider: Not found in state, fetching from API');
      // If not found in current state, fetch from API
      final application = await _applicationService.getApplication(int.parse(applicationId));
      if (application != null) {
        print('DEBUG Provider: Loaded from API - Name: "${application.applicantName}", Email: "${application.applicantEmail}"');
      }
      return application;
    } catch (e) {
      print('Error getting application by ID: $e');
      return null;
    }
  }
}

// Providers
final recruiterApplicantsServiceProvider = Provider<ApplicationService>((ref) => ApplicationService());

final recruiterApplicantsProvider = StateNotifierProvider<RecruiterApplicantsNotifier, RecruiterApplicantsState>((ref) {
  return RecruiterApplicantsNotifier(ref.watch(recruiterApplicantsServiceProvider));
}); 