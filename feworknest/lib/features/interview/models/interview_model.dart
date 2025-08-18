class InterviewModel {
  final int id;
  final int applicationId;
  final int candidateId;
  final int recruiterId;
  final DateTime scheduledAt;
  final String title;
  final String? description;
  final String? meetingLink;
  final String? location;
  final InterviewStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Navigation properties
  final String? candidateName;
  final String? candidateEmail;
  final String? recruiterName;
  final String? recruiterEmail;
  final String? jobTitle;
  final String? companyName;

  const InterviewModel({
    required this.id,
    required this.applicationId,
    required this.candidateId,
    required this.recruiterId,
    required this.scheduledAt,
    required this.title,
    this.description,
    this.meetingLink,
    this.location,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.candidateName,
    this.candidateEmail,
    this.recruiterName,
    this.recruiterEmail,
    this.jobTitle,
    this.companyName,
  });

  factory InterviewModel.fromJson(Map<String, dynamic> json) {
    return InterviewModel(
      id: json['id'] as int,
      applicationId: json['applicationId'] as int,
      candidateId: json['candidateId'] as int,
      recruiterId: json['recruiterId'] as int,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      meetingLink: json['meetingLink'] as String?,
      location: json['location'] as String?,
      status: _parseStatus(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      candidateName: json['candidateName'] as String?,
      candidateEmail: json['candidateEmail'] as String?,
      recruiterName: json['recruiterName'] as String?,
      recruiterEmail: json['recruiterEmail'] as String?,
      jobTitle: json['jobTitle'] as String?,
      companyName: json['companyName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicationId': applicationId,
      'candidateId': candidateId,
      'recruiterId': recruiterId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'title': title,
      'description': description,
      'meetingLink': meetingLink,
      'location': location,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'candidateName': candidateName,
      'candidateEmail': candidateEmail,
      'recruiterName': recruiterName,
      'recruiterEmail': recruiterEmail,
      'jobTitle': jobTitle,
      'companyName': companyName,
    };
  }

  static InterviewStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return InterviewStatus.scheduled;
      case 'completed':
        return InterviewStatus.completed;
      case 'cancelled':
        return InterviewStatus.cancelled;
      case 'rescheduled':
        return InterviewStatus.rescheduled;
      default:
        return InterviewStatus.scheduled;
    }
  }

  InterviewModel copyWith({
    int? id,
    int? applicationId,
    int? candidateId,
    int? recruiterId,
    DateTime? scheduledAt,
    String? title,
    String? description,
    String? meetingLink,
    String? location,
    InterviewStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? candidateName,
    String? candidateEmail,
    String? recruiterName,
    String? recruiterEmail,
    String? jobTitle,
    String? companyName,
  }) {
    return InterviewModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      candidateId: candidateId ?? this.candidateId,
      recruiterId: recruiterId ?? this.recruiterId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      title: title ?? this.title,
      description: description ?? this.description,
      meetingLink: meetingLink ?? this.meetingLink,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      candidateName: candidateName ?? this.candidateName,
      candidateEmail: candidateEmail ?? this.candidateEmail,
      recruiterName: recruiterName ?? this.recruiterName,
      recruiterEmail: recruiterEmail ?? this.recruiterEmail,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
    );
  }

  bool get isUpcoming => 
      status == InterviewStatus.scheduled && 
      scheduledAt.isAfter(DateTime.now());

  bool get isPast => 
      scheduledAt.isBefore(DateTime.now());

  String get statusDisplayText {
    switch (status) {
      case InterviewStatus.scheduled:
        return 'Đã lên lịch';
      case InterviewStatus.completed:
        return 'Đã hoàn thành';
      case InterviewStatus.cancelled:
        return 'Đã hủy';
      case InterviewStatus.rescheduled:
        return 'Đã dời lịch';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InterviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InterviewModel(id: $id, title: $title, scheduledAt: $scheduledAt, status: $status)';
  }
}

enum InterviewStatus {
  scheduled,
  completed,
  cancelled,
  rescheduled,
}
