import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job_model.dart';
import '../../../core/services/job_service.dart';

// Job State
class JobState {
  final List<JobModel> jobs;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final int totalCount;

  JobState({
    this.jobs = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
    this.totalCount = 0,
  });

  JobState copyWith({
    List<JobModel>? jobs,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
  }) {
    return JobState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// Job Provider
class JobNotifier extends StateNotifier<JobState> {
  final JobService _jobService;
  Map<String, dynamic> _currentFilters = {};

  JobNotifier(this._jobService) : super(JobState());

  Future<void> loadJobs({
    Map<String, dynamic>? filters,
    bool refresh = true,
  }) async {
    if (refresh) {
      _currentFilters = filters ?? {};
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMore: true,
      );
    } else if (!state.hasMore || state.isLoading) {
      return;
    }

    try {
      final result = await _jobService.getJobPosts(
        page: refresh ? 1 : state.currentPage,
        pageSize: 10,
        search: _currentFilters['search'],
        specialized: _currentFilters['specialized'],
        location: _currentFilters['location'],
      );

      final newJobs = result['jobs'] as List<JobModel>;
      final totalCount = result['totalCount'] as int;
      final hasMore = newJobs.length == 10; // If we got full page, there might be more

      state = state.copyWith(
        jobs: refresh ? newJobs : [...state.jobs, ...newJobs],
        isLoading: false,
        hasMore: hasMore,
        currentPage: refresh ? 2 : state.currentPage + 1,
        totalCount: totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreJobs() async {
    if (!state.hasMore || state.isLoading) return;
    await loadJobs(refresh: false);
  }

  Future<void> refreshJobs() async {
    await loadJobs(filters: _currentFilters, refresh: true);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final jobProvider = StateNotifierProvider<JobNotifier, JobState>((ref) {
  final jobService = JobService();
  return JobNotifier(jobService);
});

// Featured Jobs Provider
final featuredJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final jobService = JobService();
  final result = await jobService.getJobPosts(
    page: 1,
    pageSize: 6,
    // Add any featured job filters here
  );
  return result['jobs'] as List<JobModel>;
});

// Job Statistics Provider
final jobStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Mock statistics for now - replace with actual API call
  return {
    'totalJobs': 50000,
    'totalCompanies': 10000,
    'totalCandidates': 1000000,
    'successRate': 95,
  };
});

// Single Job Provider
final jobByIdProvider = FutureProvider.family<JobModel?, int>((ref, jobId) async {
  final jobService = JobService();
  try {
    final job = await jobService.getJobById(jobId);
    return job;
  } catch (e) {
    return null;
  }
});

// Search Suggestions Provider
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.length < 2) return [];
  
  // Mock search suggestions - replace with actual API call
  final suggestions = [
    'Flutter Developer',
    'React Developer', 
    'Frontend Developer',
    'Backend Developer',
    'Full Stack Developer',
    'Mobile Developer',
    'UI/UX Designer',
    'Product Manager',
    'DevOps Engineer',
    'Data Analyst',
  ].where((suggestion) => 
    suggestion.toLowerCase().contains(query.toLowerCase())
  ).take(5).toList();
  
  return suggestions;
});
