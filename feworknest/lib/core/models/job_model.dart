import 'user_model.dart';

class JobModel {
  final int id;
  final String title;
  final String specialized;
  final String description;
  final String requirements;
  final String benefits;
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
    required this.requirements,
    required this.benefits,
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
    try {
      print('DEBUG JobModel.fromJson: Processing job ID: ${json['id']}');
      return JobModel(
        id: json['id'] as int,
        title: json['title'] as String,
        specialized: json['specialized'] as String,
        description: json['description'] as String,
        requirements: json['requirements'] as String? ?? '',
        benefits: json['benefits'] as String? ?? '',
        location: json['location'] as String,
        salary: (json['salary'] as num).toDouble(),
        workingHours: json['workingHours'] as String,
        jobType: json['jobType'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        recruiter: UserModel.fromJson(json['recruiter'] as Map<String, dynamic>),
        applicationCount: json['applicationCount'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );
    } catch (e) {
      print('DEBUG JobModel.fromJson: Error parsing job: $e');
      print('DEBUG JobModel.fromJson: Raw JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'specialized': specialized,
      'description': description,
      'requirements': requirements,
      'benefits': benefits,
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

  String get salaryFormatted {
    if (salary >= 1000000) {
      return '\$${(salary / 1000000).toStringAsFixed(1)}M';
    } else if (salary >= 1000) {
      return '\$${(salary / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${salary.toStringAsFixed(0)}';
    }
  }

  JobModel copyWith({
    int? id,
    String? title,
    String? specialized,
    String? description,
    String? requirements,
    String? benefits,
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
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'JobModel{id: $id, title: $title, location: $location}';
  }
}

class CreateJobModel {
  final String title;
  final String specialized;
  final String description;
  final String requirements;
  final String benefits;
  final String location;
  final double salary;
  final String workingHours;
  final String? jobType;
  final String? experienceLevel;
  final DateTime? deadLine;

  const CreateJobModel({
    required this.title,
    required this.specialized,
    required this.description,
    required this.requirements,
    required this.benefits,
    required this.location,
    required this.salary,
    required this.workingHours,
    this.jobType,
    this.experienceLevel,
    this.deadLine,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'specialized': specialized,
      'description': description,
      'requirements': requirements,
      'benefits': benefits,
      'location': location,
      'salary': salary,
      'workingHours': workingHours,
      'jobType': jobType,
      'experienceLevel': experienceLevel,
      'deadLine': deadLine?.toIso8601String(),
    };
  }
}

class UpdateJobModel {
  final String? title;
  final String? specialized;
  final String? description;
  final String? requirements;
  final String? benefits;
  final String? location;
  final double? salary;
  final String? workingHours;
  final String? jobType;
  final String? experienceLevel;
  final DateTime? deadLine;
  final bool? isActive;

  const UpdateJobModel({
    this.title,
    this.specialized,
    this.description,
    this.requirements,
    this.benefits,
    this.location,
    this.salary,
    this.workingHours,
    this.jobType,
    this.experienceLevel,
    this.deadLine,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (title != null) data['title'] = title;
    if (specialized != null) data['specialized'] = specialized;
    if (description != null) data['description'] = description;
    if (requirements != null) data['requirements'] = requirements;
    if (benefits != null) data['benefits'] = benefits;
    if (location != null) data['location'] = location;
    if (salary != null) data['salary'] = salary;
    if (workingHours != null) data['workingHours'] = workingHours;
    if (jobType != null) data['jobType'] = jobType;
    if (experienceLevel != null) data['experienceLevel'] = experienceLevel;
    if (deadLine != null) data['deadLine'] = deadLine!.toIso8601String();
    if (isActive != null) data['isActive'] = isActive;
    
    return data;
  }
}
