import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';

class JobsState {
  final List<JobModel> jobs;
  final List<JobModel> myJobs;
  final JobModel? selectedJob;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;

  const JobsState({
    this.jobs = const [],
    this.myJobs = const [],
    this.selectedJob,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  JobsState copyWith({
    List<JobModel>? jobs,
    List<JobModel>? myJobs,
    JobModel? selectedJob,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      myJobs: myJobs ?? this.myJobs,
      selectedJob: selectedJob ?? this.selectedJob,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class JobNotifier extends StateNotifier<JobsState> {
  final JobService _jobService;

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
      
      if (loadMore && page > 1) {
        // Append to existing jobs for pagination
        state = state.copyWith(
          jobs: [...state.jobs, ...newJobs],
          currentPage: page,
          totalPages: result['totalPages'],
          isLoading: false,
        );
      } else {
        // Replace jobs for new search or first load
        state = state.copyWith(
          jobs: newJobs,
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
}

// Providers
final jobServiceProvider = Provider<JobService>((ref) => JobService());

final jobProvider = StateNotifierProvider<JobNotifier, JobsState>((ref) {
  return JobNotifier(ref.watch(jobServiceProvider));
});
