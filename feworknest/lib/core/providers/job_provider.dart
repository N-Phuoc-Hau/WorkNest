import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job_model.dart';
import '../services/job_service.dart';

class JobsState {
  final List<JobModel> jobs;
  final List<JobModel> myJobs;
  final List<JobModel> featuredJobs;
  final JobModel? selectedJob;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasMore;

  const JobsState({
    this.jobs = const [],
    this.myJobs = const [],
    this.featuredJobs = const [],
    this.selectedJob,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.hasMore = true,
  });

  JobsState copyWith({
    List<JobModel>? jobs,
    List<JobModel>? myJobs,
    List<JobModel>? featuredJobs,
    JobModel? selectedJob,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool? hasMore,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      myJobs: myJobs ?? this.myJobs,
      featuredJobs: featuredJobs ?? this.featuredJobs,
      selectedJob: selectedJob ?? this.selectedJob,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class JobNotifier extends StateNotifier<JobsState> {
  final JobService _jobService;
  Map<String, dynamic> _currentFilters = {};

  JobNotifier(this._jobService) : super(const JobsState());

  Future<void> getJobPosts({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? specialized,
    String? location,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await _jobService.getJobPosts(
        page: page,
        pageSize: pageSize,
        search: search,
        specialized: specialized,
        location: location,
      );

      final newJobs = result['jobs'] as List<JobModel>;
      final totalCount = result['totalCount'] as int? ?? newJobs.length;
      final hasMoreItems = newJobs.length == pageSize; // If we got full page, there might be more
      
      if (loadMore && page > 1) {
        // Append to existing jobs for pagination
        state = state.copyWith(
          jobs: [...state.jobs, ...newJobs],
          currentPage: page,
          totalPages: result['totalPages'],
          totalCount: totalCount,
          hasMore: hasMoreItems,
          isLoading: false,
        );
      } else {
        // Replace jobs for new search or first load
        _currentFilters = {
          'search': search,
          'specialized': specialized,
          'location': location,
        };
        state = state.copyWith(
          jobs: newJobs,
          currentPage: page,
          totalPages: result['totalPages'],
          totalCount: totalCount,
          hasMore: hasMoreItems,
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

  Future<void> getJobPost(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final job = await _jobService.getJobPost(id);
      state = state.copyWith(
        selectedJob: job,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createJobPost(CreateJobModel createJob) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newJob = await _jobService.createJobPost(createJob);
      state = state.copyWith(
        myJobs: [newJob, ...state.myJobs],
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

  Future<bool> updateJobPost(int id, UpdateJobModel updateJob) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _jobService.updateJobPost(id, updateJob);
      
      // Update job in the lists
      final updatedJobs = state.jobs.map((job) {
        if (job.id == id) {
          return job.copyWith(
            title: updateJob.title ?? job.title,
            specialized: updateJob.specialized ?? job.specialized,
            description: updateJob.description ?? job.description,
            location: updateJob.location ?? job.location,
            salary: updateJob.salary ?? job.salary,
            workingHours: updateJob.workingHours ?? job.workingHours,
            jobType: updateJob.jobType ?? job.jobType,
          );
        }
        return job;
      }).toList();

      final updatedMyJobs = state.myJobs.map((job) {
        if (job.id == id) {
          return job.copyWith(
            title: updateJob.title ?? job.title,
            specialized: updateJob.specialized ?? job.specialized,
            description: updateJob.description ?? job.description,
            location: updateJob.location ?? job.location,
            salary: updateJob.salary ?? job.salary,
            workingHours: updateJob.workingHours ?? job.workingHours,
            jobType: updateJob.jobType ?? job.jobType,
          );
        }
        return job;
      }).toList();

      state = state.copyWith(
        jobs: updatedJobs,
        myJobs: updatedMyJobs,
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

  Future<bool> deleteJobPost(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _jobService.deleteJobPost(id);
      
      state = state.copyWith(
        jobs: state.jobs.where((job) => job.id != id).toList(),
        myJobs: state.myJobs.where((job) => job.id != id).toList(),
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

  Future<void> getMyJobPosts({
    int page = 1,
    int pageSize = 10,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await _jobService.getMyJobPosts(
        page: page,
        pageSize: pageSize,
      );

      final newJobs = result['jobs'] as List<JobModel>;
      
      if (loadMore && page > 1) {
        state = state.copyWith(
          myJobs: [...state.myJobs, ...newJobs],
          currentPage: page,
          totalPages: result['totalPages'],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          myJobs: newJobs,
          currentPage: page,
          totalPages: result['totalPages'],
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

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSelectedJob() {
    state = state.copyWith(selectedJob: null);
  }

  // Additional methods for enhanced functionality
  Future<void> loadMoreJobs() async {
    if (!state.hasMore || state.isLoading) return;
    
    await getJobPosts(
      page: state.currentPage + 1,
      pageSize: 10,
      search: _currentFilters['search'],
      specialized: _currentFilters['specialized'],
      location: _currentFilters['location'],
      loadMore: true,
    );
  }

  Future<void> refreshJobs() async {
    await getJobPosts(
      page: 1,
      pageSize: 10,
      search: _currentFilters['search'],
      specialized: _currentFilters['specialized'],
      location: _currentFilters['location'],
      loadMore: false,
    );
  }

  Future<void> searchJobs({
    String? search,
    String? specialized,
    String? location,
  }) async {
    await getJobPosts(
      page: 1,
      pageSize: 10,
      search: search,
      specialized: specialized,
      location: location,
      loadMore: false,
    );
  }

  Future<void> getFeaturedJobs() async {
    try {
      final result = await _jobService.getJobPosts(
        page: 1,
        pageSize: 6,
      );

      final featuredJobs = result['jobs'] as List<JobModel>;
      
      state = state.copyWith(
        featuredJobs: featuredJobs,
      );
    } catch (e) {
      // Don't update error state for featured jobs, just fail silently
    }
  }

  // Get job by ID (for job detail screen)
  Future<JobModel?> getJobById(int jobId) async {
    try {
      final job = await _jobService.getJobById(jobId);
      
      // Update selected job
      state = state.copyWith(selectedJob: job);
      return job;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

// Providers
final jobServiceProvider = Provider<JobService>((ref) => JobService());

final jobProvider = StateNotifierProvider<JobNotifier, JobsState>((ref) {
  return JobNotifier(ref.watch(jobServiceProvider));
});

// Featured Jobs Provider
final featuredJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final jobService = JobService();
  final result = await jobService.getJobPosts(
    page: 1,
    pageSize: 6,
  );
  return result['jobs'] as List<JobModel>;
});

// Job Statistics Provider
final jobStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Mock statistics for now - replace with actual API call when available
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
  
  // Mock search suggestions - replace with actual API call when available
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
    'Software Engineer',
    'QA Engineer',
    'Business Analyst',
    'Marketing Manager',
    'Sales Manager',
  ].where((suggestion) => 
    suggestion.toLowerCase().contains(query.toLowerCase())
  ).take(5).toList();
  
  return suggestions;
});
