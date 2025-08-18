import 'job_model.dart';
import 'user_model.dart';

enum ApplicationStatus { pending, accepted, rejected, interviewing, hired, cancelled }

class ApplicationModel {
  final int id;
  final String applicantId;
  final int jobId;
  final String applicantName;
  final String applicantEmail;
  final String applicantPhone;
  final String jobTitle;
  final String? cvUrl;
  final String? cvFileName;
  final String? coverLetter;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime appliedAt;
  final UserModel? applicant;
  final JobModel? job;
  final bool isActive;
  final String? rejectionReason;
  final String? avatarUrl;

  const ApplicationModel({
    required this.id,
    required this.applicantId,
    required this.jobId,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantPhone,
    required this.jobTitle,
    required this.status,
    required this.createdAt,
    required this.appliedAt,
    this.cvUrl,
    this.cvFileName,
    this.coverLetter,
    this.applicant,
    this.job,
    this.isActive = true,
    this.rejectionReason,
    this.avatarUrl,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as int,
      applicantId: json['applicantId'] as String? ?? json['userId']?.toString() ?? '',
      jobId: json['jobId'] as int? ?? json['jobPostId'] as int,
      applicantName: json['applicantName'] as String? ?? json['fullName'] as String? ?? '',
      applicantEmail: json['applicantEmail'] as String? ?? json['email'] as String? ?? '',
      applicantPhone: json['applicantPhone'] as String? ?? json['phoneNumber'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? json['title'] as String? ?? '',
      cvUrl: json['cvUrl'] as String?,
      cvFileName: json['cvFileName'] as String?,
      coverLetter: json['coverLetter'] as String?,
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      appliedAt: json['appliedAt'] != null 
          ? DateTime.parse(json['appliedAt'] as String)
          : DateTime.now(),
      applicant: json['applicant'] != null
          ? UserModel.fromJson(json['applicant'] as Map<String, dynamic>)
          : null,
      job: json['job'] != null
          ? JobModel.fromJson(json['job'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      rejectionReason: json['rejectionReason'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  static ApplicationStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'accepted':
      case 'approved':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'interviewing':
        return ApplicationStatus.interviewing;
      case 'hired':
        return ApplicationStatus.hired;
      case 'cancelled':
        return ApplicationStatus.cancelled;
      default:
        return ApplicationStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicantId': applicantId,
      'jobId': jobId,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'applicantPhone': applicantPhone,
      'jobTitle': jobTitle,
      'cvUrl': cvUrl,
      'cvFileName': cvFileName,
      'coverLetter': coverLetter,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'appliedAt': appliedAt.toIso8601String(),
      'applicant': applicant?.toJson(),
      'job': job?.toJson(),
      'isActive': isActive,
      'rejectionReason': rejectionReason,
      'avatarUrl': avatarUrl,
    };
  }

  ApplicationModel copyWith({
    int? id,
    String? applicantId,
    int? jobId,
    String? applicantName,
    String? applicantEmail,
    String? applicantPhone,
    String? jobTitle,
    String? cvUrl,
    String? cvFileName,
    String? coverLetter,
    ApplicationStatus? status,
    DateTime? createdAt,
    DateTime? appliedAt,
    UserModel? applicant,
    JobModel? job,
    bool? isActive,
    String? rejectionReason,
    String? avatarUrl,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      applicantId: applicantId ?? this.applicantId,
      jobId: jobId ?? this.jobId,
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      applicantPhone: applicantPhone ?? this.applicantPhone,
      jobTitle: jobTitle ?? this.jobTitle,
      cvUrl: cvUrl ?? this.cvUrl,
      cvFileName: cvFileName ?? this.cvFileName,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      appliedAt: appliedAt ?? this.appliedAt,
      applicant: applicant ?? this.applicant,
      job: job ?? this.job,
      isActive: isActive ?? this.isActive,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  // Getters for convenience
  String get companyName => job?.recruiter.company?.name ?? 'Unknown Company';
  DateTime get appliedDate => appliedAt;
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
  final ApplicationModel? selectedApplication;
  final bool isLoading;
  final String? error;

  const ApplicationsState({
    this.applications = const [],
    this.myApplications = const [],
    this.selectedApplication,
    this.isLoading = false,
    this.error,
  });

  ApplicationsState copyWith({
    List<ApplicationModel>? applications,
    List<ApplicationModel>? myApplications,
    ApplicationModel? selectedApplication,
    bool? isLoading,
    String? error,
  }) {
    return ApplicationsState(
      applications: applications ?? this.applications,
      myApplications: myApplications ?? this.myApplications,
      selectedApplication: selectedApplication ?? this.selectedApplication,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
