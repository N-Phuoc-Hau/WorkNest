import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../screens/chat_screen.dart';

class ChatRoomTile extends ConsumerWidget {
  final Map<String, dynamic> chatRoom;
  final String currentUserId;
  final String userType;

  const ChatRoomTile({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.userType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecruiter = userType == 'recruiter';
    final otherUserInfo = isRecruiter 
        ? chatRoom['candidateInfo'] 
        : chatRoom['recruiterInfo'];
    final jobInfo = chatRoom['jobInfo'];
    final lastMessage = chatRoom['lastMessage'];
    final lastMessageTimestamp = chatRoom['lastMessageTimestamp'];
    final lastSenderId = chatRoom['lastSenderId'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                roomId: chatRoom['id'],
                otherUserInfo: otherUserInfo,
                jobInfo: jobInfo,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                backgroundImage: otherUserInfo?['avatar'] != null
                    ? NetworkImage(otherUserInfo['avatar'])
                    : null,
                child: otherUserInfo?['avatar'] == null
                    ? Icon(
                        Icons.person,
                        size: 24,
                        color: Colors.grey[600],
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUserInfo?['name'] ?? 'Unknown User',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageTimestamp != null)
                          Text(
                            _formatTimestamp(lastMessageTimestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Job title
                    if (jobInfo != null)
                      Text(
                        jobInfo['title'] ?? 'Unknown Job',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // Last message
                    Row(
                      children: [
                        if (lastSenderId == currentUserId)
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lastMessage ?? 'Chưa có tin nhắn nào',
                            style: TextStyle(
                              fontSize: 14,
                              color: lastMessage != null 
                                  ? Colors.grey[800] 
                                  : Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Unread count
              if (_getUnreadCount(chatRoom) > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getUnreadCount(chatRoom).toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(messageTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  int _getUnreadCount(Map<String, dynamic> chatRoom) {
    final participants = chatRoom['participants'];
    if (participants == null) return 0;
    
    final currentParticipant = participants[currentUserId];
    if (currentParticipant == null) return 0;
    
    // This is a simplified version - in real app, you'd calculate from messages
    return 0; // TODO: Implement unread count calculation
  }
} 