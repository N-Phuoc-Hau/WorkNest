import 'user_model.dart';

class FollowModel {
  final int id;
  final String followerId;
  final String recruiterId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserModel? recruiter;
  final UserModel? follower;
  final bool isActive;

  const FollowModel({
    required this.id,
    required this.followerId,
    required this.recruiterId,
    required this.createdAt,
    this.updatedAt,
    this.recruiter,
    this.follower,
    this.isActive = true,
  });

  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      id: json['id'] as int,
      followerId: json['followerId'] as String,
      recruiterId: json['recruiterId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      recruiter: json['recruiter'] != null
          ? UserModel.fromJson(json['recruiter'] as Map<String, dynamic>)
          : null,
      follower: json['follower'] != null
          ? UserModel.fromJson(json['follower'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'followerId': followerId,
      'recruiterId': recruiterId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'recruiter': recruiter?.toJson(),
      'follower': follower?.toJson(),
      'isActive': isActive,
    };
  }
}

class CreateFollowModel {
  final int companyId;

  const CreateFollowModel({
    required this.companyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
    };
  }
}

class FollowState {
  final List<FollowModel> following;
  final List<FollowModel> followers;
  final bool isLoading;
  final String? error;

  const FollowState({
    this.following = const [],
    this.followers = const [],
    this.isLoading = false,
    this.error,
  });

  FollowState copyWith({
    List<FollowModel>? following,
    List<FollowModel>? followers,
    bool? isLoading,
    String? error,
  }) {
    return FollowState(
      following: following ?? this.following,
      followers: followers ?? this.followers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
