import 'package:flutter/material.dart';

class MessageTile extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showAvatar;

  const MessageTile({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = message['text'] ?? '';
    final timestamp = message['timestamp'];
    final senderInfo = message['senderInfo'];
    final isRead = message['read'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: senderInfo?['avatar'] != null
                  ? NetworkImage(senderInfo['avatar'])
                  : null,
              child: senderInfo?['avatar'] == null
                  ? Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Timestamp and read status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe 
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead 
                              ? Colors.blue[200]
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe && showAvatar) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: senderInfo?['avatar'] != null
                  ? NetworkImage(senderInfo['avatar'])
                  : null,
              child: senderInfo?['avatar'] == null
                  ? Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
          ],
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
      return '${messageTime.day}/${messageTime.month} ${messageTime.hour}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${messageTime.hour}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
} 