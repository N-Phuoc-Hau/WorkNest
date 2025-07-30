import 'user_model.dart';

class JobModel {
  final int id;
  final String title;
  final String specialized;
  final String description;
  final String location;
  final double salary;
  final String workingHours;
  final String? jobType;
  final DateTime createdAt;
  final UserModel recruiter;
  final int applicationCount;
  final bool isActive;

  const JobModel({
    required this.id,
    required this.title,
    required this.specialized,
    required this.description,
    required this.location,
    required this.salary,
    required this.workingHours,
    required this.createdAt,
    required this.recruiter,
    required this.applicationCount,
    this.jobType,
    this.isActive = true,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as int,
      title: json['title'] as String,
      specialized: json['specialized'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      salary: (json['salary'] as num).toDouble(),
      workingHours: json['workingHours'] as String,
      jobType: json['jobType'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      recruiter: UserModel.fromJson(json['recruiter'] as Map<String, dynamic>),
      applicationCount: json['applicationCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'specialized': specialized,
      'description': description,
      'location': location,
      'salary': salary,
      'workingHours': workingHours,
      'jobType': jobType,
      'createdAt': createdAt.toIso8601String(),
      'recruiter': recruiter.toJson(),
      'applicationCount': applicationCount,
      'isActive': isActive,
    };
  }

  JobModel copyWith({
    int? id,
    String? title,
    String? specialized,
    String? description,
    String? location,
    double? salary,
    String? workingHours,
    String? jobType,
    DateTime? createdAt,
    UserModel? recruiter,
    int? applicationCount,
    bool? isActive,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      specialized: specialized ?? this.specialized,
      description: description ?? this.description,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      workingHours: workingHours ?? this.workingHours,
      jobType: jobType ?? this.jobType,
      createdAt: createdAt ?? this.createdAt,
      recruiter: recruiter ?? this.recruiter,
      applicationCount: applicationCount ?? this.applicationCount,
      isActive: isActive ?? this.isActive,
    );
  }
}

class CreateJobModel {
  final String title;
  final String specialized;
  final String description;
  final String location;
  final double salary;
  final String workingHours;
  final String? jobType;

  const CreateJobModel({
    required this.title,
    required this.specialized,
    required this.description,
    required this.location,
    required this.salary,
    required this.workingHours,
    this.jobType,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'specialized': specialized,
      'description': description,
      'location': location,
      'salary': salary,
      'workingHours': workingHours,
      if (jobType != null) 'jobType': jobType,
    };
  }
}

class UpdateJobModel {
  final String? title;
  final String? specialized;
  final String? description;
  final String? location;
  final double? salary;
  final String? workingHours;
  final String? jobType;

  const UpdateJobModel({
    this.title,
    this.specialized,
    this.description,
    this.location,
    this.salary,
    this.workingHours,
    this.jobType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (specialized != null) data['specialized'] = specialized;
    if (description != null) data['description'] = description;
    if (location != null) data['location'] = location;
    if (salary != null) data['salary'] = salary;
    if (workingHours != null) data['workingHours'] = workingHours;
    if (jobType != null) data['jobType'] = jobType;
    return data;
  }
}

class JobsState {
  final List<JobModel> jobs;
  final List<JobModel> favoriteJobs;
  final bool isLoading;
  final String? error;

  const JobsState({
    this.jobs = const [],
    this.favoriteJobs = const [],
    this.isLoading = false,
    this.error,
  });

  JobsState copyWith({
    List<JobModel>? jobs,
    List<JobModel>? favoriteJobs,
    bool? isLoading,
    String? error,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      favoriteJobs: favoriteJobs ?? this.favoriteJobs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
