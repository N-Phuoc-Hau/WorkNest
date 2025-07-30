import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job_model.dart';
import '../services/job_service.dart';
import 'job_provider.dart';

class JobPostingState {
  final List<JobModel> myJobs;
  final JobModel? selectedJob;
  final bool isLoading;
  final String? error;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;

  const JobPostingState({
    this.myJobs = const [],
    this.selectedJob,
    this.isLoading = false,
    this.error,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
  });

  JobPostingState copyWith({
    List<JobModel>? myJobs,
    JobModel? selectedJob,
    bool? isLoading,
    String? error,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
  }) {
    return JobPostingState(
      myJobs: myJobs ?? this.myJobs,
      selectedJob: selectedJob ?? this.selectedJob,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

class JobPostingNotifier extends StateNotifier<JobPostingState> {
  final JobService _jobService;

  JobPostingNotifier(this._jobService) : super(const JobPostingState());

  Future<void> loadMyJobs({int page = 1, int pageSize = 10}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _jobService.getMyJobPosts(
        page: page,
        pageSize: pageSize,
      );

      final jobs = result['jobs'] as List<JobModel>;
      
      state = state.copyWith(
        myJobs: jobs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createJob(CreateJobModel createJob) async {
    state = state.copyWith(isCreating: true, error: null);

    try {
      final newJob = await _jobService.createJobPost(createJob);
      
      state = state.copyWith(
        myJobs: [newJob, ...state.myJobs],
        isCreating: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateJob(int jobId, UpdateJobModel updateJob) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      await _jobService.updateJobPost(jobId, updateJob);
      
      // Update job in the local state
      final updatedJobs = state.myJobs.map((job) {
        if (job.id == jobId) {
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
        myJobs: updatedJobs,
        isUpdating: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteJob(int jobId) async {
    state = state.copyWith(isDeleting: true, error: null);

    try {
      await _jobService.deleteJobPost(jobId);
      
      state = state.copyWith(
        myJobs: state.myJobs.where((job) => job.id != jobId).toList(),
        isDeleting: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void setSelectedJob(JobModel? job) {
    state = state.copyWith(selectedJob: job);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final jobPostingProvider = StateNotifierProvider<JobPostingNotifier, JobPostingState>((ref) {
  return JobPostingNotifier(ref.watch(jobServiceProvider));
});
