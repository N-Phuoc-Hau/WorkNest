import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final type = notification['type'] ?? '';
    final timestamp = notification['timestamp'];
    final isRead = notification['isRead'] ?? false;
    final imageUrl = notification['imageUrl'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: isRead ? 1 : 2,
      color: isRead ? Colors.white : Colors.blue[50],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon based on notification type
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getIconColor(type),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getIcon(type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                        color: isRead ? Colors.grey[700] : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Body
                    if (body.isNotEmpty)
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Timestamp and actions
                    Row(
                      children: [
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        if (!isRead && onMarkAsRead != null)
                          TextButton(
                            onPressed: onMarkAsRead,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text(
                              'Đánh dấu đã đọc',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Image (if available)
              if (imageUrl != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[500],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'job_application':
        return Icons.work_outline;
      case 'system':
        return Icons.notifications_outlined;
      case 'favorite':
        return Icons.favorite_outline;
      case 'follow':
        return Icons.person_add_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'chat':
        return Colors.blue;
      case 'job_application':
        return Colors.green;
      case 'system':
        return Colors.orange;
      case 'favorite':
        return Colors.red;
      case 'follow':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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