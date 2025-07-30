import 'job_model.dart';

class FavoriteJobModel {
  final int id;
  final String userId;
  final int jobId;
  final DateTime createdAt;
  final JobModel? job;

  const FavoriteJobModel({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.createdAt,
    this.job,
  });

  factory FavoriteJobModel.fromJson(Map<String, dynamic> json) {
    return FavoriteJobModel(
      id: json['id'] as int,
      userId: json['userId'] as String,
      jobId: json['jobId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      job: json['job'] != null
          ? JobModel.fromJson(json['job'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'jobId': jobId,
      'createdAt': createdAt.toIso8601String(),
      'job': job?.toJson(),
    };
  }
}

class FavoriteJobDto {
  final int id;
  final int jobId;
  final String jobTitle;
  final String companyName;
  final String location;
  final String salary;
  final String? jobType;
  final DateTime createdAt;
  final DateTime jobPostedAt;
  final bool isActive;

  const FavoriteJobDto({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.salary,
    required this.createdAt,
    required this.jobPostedAt,
    required this.isActive,
    this.jobType,
  });

  factory FavoriteJobDto.fromJson(Map<String, dynamic> json) {
    return FavoriteJobDto(
      id: json['id'] as int,
      jobId: json['jobId'] as int,
      jobTitle: json['jobTitle'] as String,
      companyName: json['companyName'] as String,
      location: json['location'] as String,
      salary: json['salary'] as String,
      jobType: json['jobType'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      jobPostedAt: DateTime.parse(json['jobPostedAt'] as String),
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'location': location,
      'salary': salary,
      'jobType': jobType,
      'createdAt': createdAt.toIso8601String(),
      'jobPostedAt': jobPostedAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class FavoriteStatsModel {
  final int totalFavorites;
  final int activeFavorites;
  final int recentFavorites;

  const FavoriteStatsModel({
    required this.totalFavorites,
    required this.activeFavorites,
    required this.recentFavorites,
  });

  factory FavoriteStatsModel.fromJson(Map<String, dynamic> json) {
    return FavoriteStatsModel(
      totalFavorites: json['totalFavorites'] as int,
      activeFavorites: json['activeFavorites'] as int,
      recentFavorites: json['recentFavorites'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFavorites': totalFavorites,
      'activeFavorites': activeFavorites,
      'recentFavorites': recentFavorites,
    };
  }
}

class FavoriteState {
  final List<FavoriteJobDto> favoriteJobs;
  final FavoriteStatsModel? stats;
  final bool isLoading;
  final String? error;

  const FavoriteState({
    this.favoriteJobs = const [],
    this.stats,
    this.isLoading = false,
    this.error,
  });

  FavoriteState copyWith({
    List<FavoriteJobDto>? favoriteJobs,
    FavoriteStatsModel? stats,
    bool? isLoading,
    String? error,
  }) {
    return FavoriteState(
      favoriteJobs: favoriteJobs ?? this.favoriteJobs,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
