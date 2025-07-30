import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review_model.dart';
import '../services/review_service.dart';

// Review Notifier  
class ReviewNotifier extends StateNotifier<ReviewState> {
  final ReviewService _reviewService;

  ReviewNotifier(this._reviewService) : super(const ReviewState());

  // Get reviews for a company
  Future<void> getCompanyReviews(int companyId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _reviewService.getCompanyReviews(companyId);
      final reviews = result['reviews'] as List<ReviewModel>;
      
      state = state.copyWith(
        reviews: reviews,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Get reviews by current user
  Future<void> getMyReviews() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _reviewService.getMyReviews();
      final reviews = result['reviews'] as List<ReviewModel>;
      
      state = state.copyWith(
        myReviews: reviews,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Create candidate review (for company)
  Future<ReviewModel?> createCandidateReview(CreateCandidateReviewModel createReview) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final review = await _reviewService.createCandidateReview(createReview);
      
      // Add to reviews list
      state = state.copyWith(
        reviews: [...state.reviews, review],
        myReviews: [...state.myReviews, review],
        isLoading: false,
      );
      
      return review;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  // Create recruiter review (for candidate)
  Future<ReviewModel?> createRecruiterReview(CreateRecruiterReviewModel createReview) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final review = await _reviewService.createRecruiterReview(createReview);
      
      // Add to reviews list
      state = state.copyWith(
        reviews: [...state.reviews, review],
        myReviews: [...state.myReviews, review],
        isLoading: false,
      );
      
      return review;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  // Delete a review
  Future<bool> deleteReview(int reviewId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _reviewService.deleteReview(reviewId);
      
      // Remove from reviews list
      final updatedReviews = state.reviews.where((review) => review.id != reviewId).toList();
      
      // Remove from my reviews list
      final updatedMyReviews = state.myReviews.where((review) => review.id != reviewId).toList();
      
      state = state.copyWith(
        reviews: updatedReviews,
        myReviews: updatedMyReviews,
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

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear reviews (useful when switching companies)
  void clearReviews() {
    state = state.copyWith(reviews: []);
  }
}

// Provider
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

final reviewProvider = StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  final reviewService = ref.read(reviewServiceProvider);
  return ReviewNotifier(reviewService);
});
