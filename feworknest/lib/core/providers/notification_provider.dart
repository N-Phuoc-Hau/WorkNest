import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

class NotificationState {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  NotificationState copyWith({
    List<Map<String, dynamic>>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;
  final String _userId;

  NotificationNotifier(this._notificationService, this._userId) : super(NotificationState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Initialize notification service
      await _notificationService.initialize();
      
      // Subscribe to notifications stream for real-time updates
      _notificationService.getUserNotificationsStream(_userId).listen(
        (notifications) {
          final unreadCount = notifications.where((n) => n['isRead'] != true).length;
          state = state.copyWith(
            notifications: notifications,
            unreadCount: unreadCount,
            isInitialized: true,
          );
        },
        onError: (error) {
          state = state.copyWith(error: error.toString());
        },
      );
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(_userId, notificationId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      state = state.copyWith(isLoading: true);
      
      await _notificationService.markAllAsRead(_userId);
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(_userId, notificationId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> createNotification(Map<String, dynamic> notification) async {
    try {
      await _notificationService.createNotification(_userId, notification);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _notificationService.subscribeToTopic(topic);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _notificationService.unsubscribeFromTopic(topic);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void refreshUnreadCount() async {
    try {
      final unreadCount = await _notificationService.getUnreadNotificationCount(_userId);
      state = state.copyWith(unreadCount: unreadCount);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Providers
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationProvider = StateNotifierProvider.family<NotificationNotifier, NotificationState, String>((ref, userId) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationNotifier(notificationService, userId);
}); 