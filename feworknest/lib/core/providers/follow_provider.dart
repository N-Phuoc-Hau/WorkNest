import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company_model.dart';
import '../models/follow_model.dart';
import '../services/follow_service.dart';
import 'auth_provider.dart';

class FollowNotifier extends StateNotifier<FollowState> {
  final FollowService _followService;
  final Ref _ref;

  FollowNotifier(this._followService, this._ref) : super(const FollowState());

  void _handleAuthError(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      print('FollowProvider: Authentication error detected, logging out...');
      _ref.read(authProvider.notifier).logout();
    }
  }

  Future<bool> followCompany(CreateFollowModel createFollow) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _followService.followCompany(createFollow);
      state = state.copyWith(isLoading: false);

      // Refresh following list
      await getMyFollowing();
      return true;
    } catch (e) {
      _handleAuthError(e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> unfollowCompany(int companyId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _followService.unfollowCompany(companyId);

      // Remove from local state immediately
      final updatedFollowing = state.following
          .where((follow) => follow.recruiter?.company?.id != companyId)
          .toList();

      state = state.copyWith(
        following: updatedFollowing,
        isLoading: false,
      );
      return true;
    } catch (e) {
      _handleAuthError(e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> getMyFollowing({
    int page = 1,
    int pageSize = 10,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await _followService.getMyFollowing(
        page: page,
        pageSize: pageSize,
      );

      // Use 'companies' key from service
      final newCompanies = result['companies'] as List<CompanyModel>? ?? <CompanyModel>[];
      final totalCount = result['totalCount'] as int? ?? 0;
      final totalPages = result['totalPages'] as int? ?? 1;

      if (loadMore && page > 1) {
        // Append to existing following companies for pagination
        state = state.copyWith(
          followingCompanies: [...state.followingCompanies, ...newCompanies],
          totalCount: totalCount,
          totalPages: totalPages,
          currentPage: page,
          isLoading: false,
        );
      } else {
        // Replace following companies for first load
        state = state.copyWith(
          followingCompanies: newCompanies,
          totalCount: totalCount,
          totalPages: totalPages,
          currentPage: page,
          isLoading: false,
        );
      }
    } catch (e) {
      _handleAuthError(e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> getMyFollowers({
    int page = 1,
    int pageSize = 10,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await _followService.getMyFollowers(
        page: page,
        pageSize: pageSize,
      );

      final newFollowers = result['followers'] as List<FollowModel>;
      final totalCount = result['totalCount'] as int? ?? 0;
      final totalPages = result['totalPages'] as int? ?? 1;

      if (loadMore && page > 1) {
        // Append to existing followers for pagination
        state = state.copyWith(
          followers: [...state.followers, ...newFollowers],
          totalCount: totalCount,
          totalPages: totalPages,
          currentPage: page,
          isLoading: false,
        );
      } else {
        // Replace followers for first load
        state = state.copyWith(
          followers: newFollowers,
          totalCount: totalCount,
          totalPages: totalPages,
          currentPage: page,
          isLoading: false,
        );
      }
    } catch (e) {
      _handleAuthError(e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> checkFollowStatus(int companyId) async {
    try {
      return await _followService.isFollowing(companyId);
    } catch (e) {
      _handleAuthError(e);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  bool isFollowing(int companyId) {
    return state.following
        .any((follow) => follow.recruiter?.company?.id == companyId);
  }
}

// Follow State
class FollowState {
  final List<FollowModel> following;
  final List<FollowModel> followers;
  final List<CompanyModel> followingCompanies; // Add this for company data
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const FollowState({
    this.following = const [],
    this.followers = const [],
    this.followingCompanies = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
  });

  FollowState copyWith({
    List<FollowModel>? following,
    List<FollowModel>? followers,
    List<CompanyModel>? followingCompanies,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalCount,
  }) {
    return FollowState(
      following: following ?? this.following,
      followers: followers ?? this.followers,
      followingCompanies: followingCompanies ?? this.followingCompanies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// Providers
final followServiceProvider = Provider<FollowService>((ref) => FollowService());

final followProvider =
    StateNotifierProvider<FollowNotifier, FollowState>((ref) {
  return FollowNotifier(ref.watch(followServiceProvider), ref);
});

// Provider để check trạng thái follow của một company cụ thể
final companyFollowStatusProvider =
    FutureProvider.family<bool, int>((ref, companyId) async {
  final followNotifier = ref.watch(followProvider.notifier);
  return await followNotifier.checkFollowStatus(companyId);
});
