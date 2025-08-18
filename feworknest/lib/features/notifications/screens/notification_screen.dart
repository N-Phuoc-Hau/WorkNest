import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/signalr_notification_service.dart';

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
          // Test Notification Button (for development)
          IconButton(
            onPressed: () => _showTestNotificationDialog(context),
            icon: const Icon(Icons.bug_report),
            tooltip: 'Test Notifications',
          ),
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
                          return _buildNotificationTile(context, ref, notification, user.user?.id ?? '');
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, WidgetRef ref, Map<String, dynamic> notification, String userId) {
    final isRead = notification['isRead'] ?? false;
    final title = notification['title'] ?? 'Thông báo';
    final body = notification['body'] ?? '';
    final timestamp = notification['timestamp'];
    final type = notification['type'] ?? 'system';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isRead ? 1 : 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(type),
          child: Icon(
            _getNotificationIcon(type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: isRead ? Colors.grey[700] : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'mark_read' && !isRead) {
              ref.read(notificationProvider(userId).notifier)
                  .markAsRead(notification['id']);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, ref, userId, notification['id']);
            }
          },
          itemBuilder: (context) => [
            if (!isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Đánh dấu đã đọc'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa thông báo'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          _handleNotificationTap(context, notification);
          if (!isRead) {
            ref.read(notificationProvider(userId).notifier)
                .markAsRead(notification['id']);
          }
        },
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'chat':
        return Colors.blue;
      case 'job_application':
        return Colors.green;
      case 'interview':
        return Colors.orange;
      case 'system':
      default:
        return Colors.purple;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat;
      case 'job_application':
        return Icons.work;
      case 'interview':
        return Icons.event;
      case 'system':
      default:
        return Icons.notifications;
    }
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

  void _showTestNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn loại thông báo để test:'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _testLocalNotification('Chat Message', 'You have a new message from John Doe', context);
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat Notification'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _testLocalNotification('New Job Posted', 'A new "Flutter Developer" position has been posted', context);
              },
              icon: const Icon(Icons.work),
              label: const Text('Job Notification'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _testLocalNotification('Interview Scheduled', 'Your interview has been scheduled for tomorrow at 2:00 PM', context);
              },
              icon: const Icon(Icons.event),
              label: const Text('Interview Notification'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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

  void _testLocalNotification(String title, String body, BuildContext context) async {
    try {
      // Import SignalRNotificationService at the top
      final signalRService = SignalRNotificationService();
      await signalRService.showLocalNotification(
        title: title,
        body: body,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notification sent: $title'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 