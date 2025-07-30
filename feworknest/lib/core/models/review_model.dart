import 'user_model.dart';

class ReviewModel {
  final int id;
  final String reviewerId;
  final String reviewedUserId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final UserModel? reviewer;
  final UserModel? reviewedUser;
  final bool isActive;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.reviewer,
    this.reviewedUser,
    this.isActive = true,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as int,
      reviewerId: json['reviewerId'] as String,
      reviewedUserId: json['reviewedUserId'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewer: json['reviewer'] != null
          ? UserModel.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
      reviewedUser: json['reviewedUser'] != null
          ? UserModel.fromJson(json['reviewedUser'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'reviewedUserId': reviewedUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'reviewer': reviewer?.toJson(),
      'reviewedUser': reviewedUser?.toJson(),
      'isActive': isActive,
    };
  }
}

class CreateCandidateReviewModel {
  final int companyId;
  final int rating;
  final String? comment;

  const CreateCandidateReviewModel({
    required this.companyId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    };
  }
}

class CreateRecruiterReviewModel {
  final String candidateId;
  final int rating;
  final String? comment;

  const CreateRecruiterReviewModel({
    required this.candidateId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'candidateId': candidateId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    };
  }
}

class ReviewState {
  final List<ReviewModel> reviews;
  final List<ReviewModel> myReviews;
  final bool isLoading;
  final String? error;

  const ReviewState({
    this.reviews = const [],
    this.myReviews = const [],
    this.isLoading = false,
    this.error,
  });

  ReviewState copyWith({
    List<ReviewModel>? reviews,
    List<ReviewModel>? myReviews,
    bool? isLoading,
    String? error,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      myReviews: myReviews ?? this.myReviews,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
