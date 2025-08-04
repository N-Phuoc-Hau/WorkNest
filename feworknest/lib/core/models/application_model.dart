import 'user_model.dart';
import 'job_model.dart';

enum ApplicationStatus { pending, accepted, rejected }

class ApplicationModel {
  final int id;
  final String applicantId;
  final int jobId;
  final String? cvUrl;
  final String? coverLetter;
  final ApplicationStatus status;
  final DateTime createdAt;
  final UserModel? applicant;
  final JobModel? job;
  final bool isActive;
  final String? rejectionReason;
  final DateTime? appliedAt;

  const ApplicationModel({
    required this.id,
    required this.applicantId,
    required this.jobId,
    required this.status,
    required this.createdAt,
    this.cvUrl,
    this.coverLetter,
    this.applicant,
    this.job,
    this.isActive = true,
    this.rejectionReason,
    this.appliedAt,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as int,
      applicantId: json['applicantId'] as String,
      jobId: json['jobId'] as int,
      cvUrl: json['cvUrl'] as String?,
      coverLetter: json['coverLetter'] as String?,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      applicant: json['applicant'] != null
          ? UserModel.fromJson(json['applicant'] as Map<String, dynamic>)
          : null,
      job: json['job'] != null
          ? JobModel.fromJson(json['job'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      rejectionReason: json['rejectionReason'] as String?,
      appliedAt: json['appliedAt'] != null 
          ? DateTime.parse(json['appliedAt'] as String)
          : null,
    );
  }

  static ApplicationStatus _parseStatus(String status) {
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicantId': applicantId,
      'jobId': jobId,
      'cvUrl': cvUrl,
      'coverLetter': coverLetter,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'applicant': applicant?.toJson(),
      'job': job?.toJson(),
      'isActive': isActive,
      'rejectionReason': rejectionReason,
      'appliedAt': appliedAt?.toIso8601String(),
    };
  }

  ApplicationModel copyWith({
    int? id,
    String? applicantId,
    int? jobId,
    String? cvUrl,
    String? coverLetter,
    ApplicationStatus? status,
    DateTime? createdAt,
    UserModel? applicant,
    JobModel? job,
    bool? isActive,
    String? rejectionReason,
    DateTime? appliedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      applicantId: applicantId ?? this.applicantId,
      jobId: jobId ?? this.jobId,
      cvUrl: cvUrl ?? this.cvUrl,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      applicant: applicant ?? this.applicant,
      job: job ?? this.job,
      isActive: isActive ?? this.isActive,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }

  // Getters for convenience
  String get jobTitle => job?.title ?? 'Unknown Job';
  String get companyName => job?.recruiter.company?.name ?? 'Unknown Company';
  String get applicantName => applicant?.fullName ?? 'Unknown Applicant';
  String get applicantEmail => applicant?.email ?? '';
  DateTime get appliedDate => appliedAt ?? createdAt;
}

class CreateApplicationModel {
  final int jobId;
  final String? coverLetter;

  const CreateApplicationModel({
    required this.jobId,
    this.coverLetter,
  });

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      if (coverLetter != null) 'coverLetter': coverLetter,
    };
  }
}

class UpdateApplicationStatusModel {
  final String status;

  const UpdateApplicationStatusModel({
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
    };
  }
}

class ApplicationsState {
  final List<ApplicationModel> applications;
  final List<ApplicationModel> myApplications;
  final bool isLoading;
  final String? error;

  const ApplicationsState({
    this.applications = const [],
    this.myApplications = const [],
    this.isLoading = false,
    this.error,
  });

  ApplicationsState copyWith({
    List<ApplicationModel>? applications,
    List<ApplicationModel>? myApplications,
    bool? isLoading,
    String? error,
  }) {
    return ApplicationsState(
      applications: applications ?? this.applications,
      myApplications: myApplications ?? this.myApplications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
