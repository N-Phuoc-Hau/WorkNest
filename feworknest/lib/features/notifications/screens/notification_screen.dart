import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/notification_tile.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập để xem thông báo'),
        ),
      );
    }

    final notificationState = ref.watch(notificationProvider(user.user?.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (notificationState.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationProvider(user.user?.id ?? '').notifier).markAllAsRead();
              },
              child: const Text(
                'Đánh dấu tất cả',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: notificationState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Có lỗi xảy ra',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notificationState.error!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(notificationProvider(user.user?.id ?? '').notifier).clearError();
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : notificationState.notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có thông báo nào',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bạn sẽ nhận được thông báo khi có\nhoạt động mới',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.read(notificationProvider(user.user?.id ?? '').notifier).refreshUnreadCount();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: notificationState.notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notificationState.notifications[index];
                          return NotificationTile(
                            notification: notification,
                            onTap: () {
                              _handleNotificationTap(context, notification);
                            },
                            onMarkAsRead: () {
                              ref.read(notificationProvider(user.user?.id ?? '').notifier)
                                  .markAsRead(notification['id']);
                            },
                            onDelete: () {
                              _showDeleteConfirmation(context, ref, user.user?.id ?? '', notification['id']);
                            },
                          );
                        },
                      ),
                    ),
    );
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    final type = notification['type'];
    final data = notification['data'];
    
    switch (type) {
      case 'chat':
        // Navigate to chat screen
        if (data != null && data['chatRoomId'] != null) {
          // TODO: Navigate to chat screen
          print('Navigate to chat: ${data['chatRoomId']}');
        }
        break;
      case 'job_application':
        // Navigate to job application screen
        if (data != null && data['applicationId'] != null) {
          // TODO: Navigate to application screen
          print('Navigate to application: ${data['applicationId']}');
        }
        break;
      case 'system':
        // Show system notification details
        _showNotificationDetails(context, notification);
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  void _showNotificationDetails(BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title'] ?? 'Thông báo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['body'] ?? ''),
            const SizedBox(height: 16),
            Text(
              'Thời gian: ${_formatTimestamp(notification['timestamp'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String userId, String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thông báo'),
        content: const Text('Bạn có chắc chắn muốn xóa thông báo này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notificationProvider(userId).notifier).deleteNotification(notificationId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa thông báo'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
} 