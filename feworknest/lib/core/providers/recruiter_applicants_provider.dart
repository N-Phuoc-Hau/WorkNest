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
      error: error ?? this.error,
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
    int jobId, {
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
      final result = await _applicationService.getJobApplications(
        jobId,
        page: page,
        pageSize: pageSize,
      );

      final newApplicants = result['applications'] as List<ApplicationModel>;
      final totalCount = result['totalCount'] as int;
      final totalPages = result['totalPages'] as int;

      if (loadMore && page > 1) {
        // Append to existing applicants for pagination
        state = state.copyWith(
          applicants: [...state.applicants, ...newApplicants],
          currentPage: page,
          totalPages: totalPages,
          totalCount: totalCount,
          isLoading: false,
          searchQuery: search,
          statusFilter: status,
        );
      } else {
        // Replace applicants for first load
        state = state.copyWith(
          applicants: newApplicants,
          currentPage: page,
          totalPages: totalPages,
          totalCount: totalCount,
          isLoading: false,
          searchQuery: search,
          statusFilter: status,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
    int jobId, {
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

  Future<void> loadMoreApplicants(int jobId) async {
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
}

// Providers
final recruiterApplicantsServiceProvider = Provider<ApplicationService>((ref) => ApplicationService());

final recruiterApplicantsProvider = StateNotifierProvider<RecruiterApplicantsNotifier, RecruiterApplicantsState>((ref) {
  return RecruiterApplicantsNotifier(ref.watch(recruiterApplicantsServiceProvider));
}); 