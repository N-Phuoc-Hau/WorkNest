import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

// Unified notification state
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final bool hasReachedEnd;
  final int currentPage;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.hasReachedEnd = false,
    this.currentPage = 1,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool? hasReachedEnd,
    int? currentPage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationState &&
          runtimeType == other.runtimeType &&
          notifications == other.notifications &&
          unreadCount == other.unreadCount &&
          isLoading == other.isLoading &&
          error == other.error &&
          isInitialized == other.isInitialized &&
          hasReachedEnd == other.hasReachedEnd &&
          currentPage == other.currentPage;

  @override
  int get hashCode =>
      notifications.hashCode ^
      unreadCount.hashCode ^
      isLoading.hashCode ^
      error.hashCode ^
      isInitialized.hashCode ^
      hasReachedEnd.hashCode ^
      currentPage.hashCode;
}

// Unified notification notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;
  StreamSubscription? _notificationSubscription;
  Timer? _refreshTimer;

  NotificationNotifier(this._notificationService) : super(const NotificationState()) {
    _initialize();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Initialize the provider
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Load initial notifications
      await _loadNotifications(reset: true);
      
      // Set up periodic refresh
      _setupPeriodicRefresh();
      
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isInitialized: true,
      );
    }
  }

  // Set up periodic refresh every 30 seconds
  void _setupPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state.isInitialized && !state.isLoading) {
        refreshUnreadCount();
      }
    });
  }

  // Load notifications with pagination
  Future<void> _loadNotifications({
    bool reset = false,
    int? page,
    int pageSize = 20,
  }) async {
    try {
      if (reset) {
        state = state.copyWith(
          currentPage: 1,
          hasReachedEnd: false,
          error: null,
        );
      }

      final targetPage = page ?? (reset ? 1 : state.currentPage);
      
      final newNotifications = await _notificationService.getNotifications(
        page: targetPage,
        pageSize: pageSize,
      );

      final allNotifications = reset 
          ? newNotifications
          : [...state.notifications, ...newNotifications];

      // Remove duplicates based on ID
      final uniqueNotifications = <int, NotificationModel>{};
      for (final notification in allNotifications) {
        uniqueNotifications[notification.id] = notification;
      }
      final finalNotifications = uniqueNotifications.values.toList();
      
      // Sort by creation date (newest first)
      finalNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Calculate unread count
      final unreadCount = finalNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: finalNotifications,
        unreadCount: unreadCount,
        hasReachedEnd: newNotifications.length < pageSize,
        currentPage: targetPage,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Public methods
  Future<void> loadNotifications({
    bool reset = false,
    int? page,
    int pageSize = 20,
  }) async {
    if (state.isLoading && !reset) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      await _loadNotifications(reset: reset, page: page, pageSize: pageSize);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMoreNotifications({int pageSize = 20}) async {
    if (state.isLoading || state.hasReachedEnd) return;
    
    await loadNotifications(
      page: state.currentPage + 1,
      pageSize: pageSize,
    );
  }

  Future<void> refresh() async {
    await loadNotifications(reset: true);
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      // Optimistically update UI
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId && !n.isRead) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      
      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );

      // Make API call
      final success = await _notificationService.markAsRead(notificationId);
      
      if (!success) {
        // Revert on failure
        final revertedNotifications = state.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: false);
          }
          return n;
        }).toList();
        
        final revertedUnreadCount = revertedNotifications.where((n) => !n.isRead).length;
        
        state = state.copyWith(
          notifications: revertedNotifications,
          unreadCount: revertedUnreadCount,
          error: 'Không thể đánh dấu thông báo đã đọc',
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Optimistically update UI
      final updatedNotifications = state.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );

      final success = await _notificationService.markAllAsRead();
      
      if (!success) {
        // Revert on failure - reload to get correct state
        await refresh();
        state = state.copyWith(error: 'Không thể đánh dấu tất cả thông báo');
      }
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      // Reload to get correct state
      await refresh();
      rethrow;
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      // Optimistically update UI
      final updatedNotifications = state.notifications
          .where((n) => n.id != notificationId)
          .toList();
      
      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      // Store original state for potential revert
      final originalNotifications = List<NotificationModel>.from(state.notifications);
      final originalUnreadCount = state.unreadCount;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );

      final success = await _notificationService.deleteNotification(notificationId);
      
      if (!success) {
        // Revert on failure
        state = state.copyWith(
          notifications: originalNotifications,
          unreadCount: originalUnreadCount,
          error: 'Không thể xóa thông báo',
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Reload to get correct state
      await refresh();
      rethrow;
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final unreadCount = await _notificationService.getUnreadCount();
      
      // Only update if different to avoid unnecessary rebuilds
      if (unreadCount != state.unreadCount) {
        state = state.copyWith(unreadCount: unreadCount);
      }
    } catch (e) {
      // Silently fail for background refresh
      // Log error in production
    }
  }

  // Get notification by ID
  NotificationModel? getNotificationById(int id) {
    try {
      return state.notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(String type) {
    return state.notifications.where((n) => n.type == type).toList();
  }

  // Get unread notifications
  List<NotificationModel> getUnreadNotifications() {
    return state.notifications.where((n) => !n.isRead).toList();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider definitions
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationNotifier(notificationService);
});

// Convenience providers
final unreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationProvider);
  return state.unreadCount;
});

final notificationsProvider = Provider<List<NotificationModel>>((ref) {
  final state = ref.watch(notificationProvider);
  return state.notifications;
});

final unreadNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final state = ref.watch(notificationProvider);
  return state.notifications.where((n) => !n.isRead).toList();
});

final notificationsByTypeProvider = Provider.family<List<NotificationModel>, String>((ref, type) {
  final state = ref.watch(notificationProvider);
  return state.notifications.where((n) => n.type == type).toList();
});