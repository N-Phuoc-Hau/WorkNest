import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/notification_model.dart';
import '../services/notification_service.dart';

// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// State class for notifications
class NotificationListState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  NotificationListState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationListState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// Notification list provider
class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationService _service;

  NotificationListNotifier(this._service) : super(NotificationListState()) {
    loadNotifications();
  }

  Future<void> loadNotifications({int page = 1, int pageSize = 20}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final notifications = await _service.getNotifications(page: page, pageSize: pageSize);
      final unreadCount = await _service.getUnreadCount();
      
      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final success = await _service.markAsRead(notificationId);
      if (success) {
        // Update local state
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == notificationId) {
            return NotificationModel.fromJson({
              ...n.toJson(),
              'isRead': true,
            });
          }
          return n;
        }).toList();
        
        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
        
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.markAllAsRead();
      if (success) {
        final updatedNotifications = state.notifications.map((n) {
          return NotificationModel.fromJson({
            ...n.toJson(),
            'isRead': true,
          });
        }).toList();
        
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final success = await _service.deleteNotification(notificationId);
      if (success) {
        final updatedNotifications = state.notifications
            .where((n) => n.id != notificationId)
            .toList();
        
        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
        
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refresh() async {
    await loadNotifications();
  }
}

// Provider for notification list
final notificationListProvider = StateNotifierProvider<NotificationListNotifier, NotificationListState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationListNotifier(service);
});

// Provider for unread count only
final unreadCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getUnreadCount();
});
