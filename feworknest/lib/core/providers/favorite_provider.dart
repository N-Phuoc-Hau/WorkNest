import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite_model.dart';
import '../services/favorite_service.dart';
import 'auth_provider.dart';

class FavoriteNotifier extends StateNotifier<FavoriteState> {
  final FavoriteService _favoriteService;
  final Ref _ref;

  FavoriteNotifier(this._favoriteService, this._ref) : super(const FavoriteState());

  /// Xử lý lỗi authentication - logout user nếu token hết hạn
  void _handleAuthError(String error) {
    if (error.contains('AUTH_REQUIRED') || error.contains('401') || 
        error.contains('Không có quyền truy cập') || error.contains('đăng nhập')) {
      // Token hết hạn, logout user
      _ref.read(authProvider.notifier).logout();
    }
  }

  Future<bool> addToFavorite(int jobId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _favoriteService.addToFavorite(jobId);
      state = state.copyWith(isLoading: false);

      // Refresh favorites list
      await getMyFavorites();
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return false;
    }
  }

  Future<bool> removeFromFavorite(int jobId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _favoriteService.removeFromFavorite(jobId);

      // Remove from local state immediately
      final updatedFavorites = state.favoriteJobs
          .where((favorite) => favorite.jobId != jobId)
          .toList();

      state = state.copyWith(
        favoriteJobs: updatedFavorites,
        isLoading: false,
      );
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return false;
    }
  }

  Future<void> getMyFavorites({
    int page = 1,
    int pageSize = 10,
    bool loadMore = false,
  }) async {
    // ...
    try {
      final result = await _favoriteService.getMyFavorites(
        page: page,
        pageSize: pageSize,
      );

      // Use 'favorites' key from service
      final newFavorites = result['favorites'] as List<FavoriteJobDto>? ?? <FavoriteJobDto>[];

      if (loadMore && page > 1) {
        state = state.copyWith(
          favoriteJobs: [...state.favoriteJobs, ...newFavorites],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          favoriteJobs: newFavorites,
          isLoading: false,
        );
      }
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  Future<bool> checkFavoriteStatus(int jobId) async {
    try {
      return await _favoriteService.checkFavoriteStatus(jobId);
    } catch (e) {
      return false;
    }
  }

  Future<void> getFavoriteStats() async {
    try {
      final stats = await _favoriteService.getFavoriteStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(error: errorMsg);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  bool isFavorited(int jobId) {
    return state.favoriteJobs.any((favorite) => favorite.jobId == jobId);
  }
}

// Providers
final favoriteServiceProvider =
    Provider<FavoriteService>((ref) => FavoriteService());

final favoriteProvider =
    StateNotifierProvider<FavoriteNotifier, FavoriteState>((ref) {
  return FavoriteNotifier(ref.watch(favoriteServiceProvider), ref);
});

// Provider để check trạng thái favorite của một job cụ thể
final jobFavoriteStatusProvider =
    FutureProvider.family<bool, int>((ref, jobId) async {
  final favoriteNotifier = ref.watch(favoriteProvider.notifier);
  return await favoriteNotifier.checkFavoriteStatus(jobId);
});
