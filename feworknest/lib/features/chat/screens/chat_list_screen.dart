import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/chat_provider.dart';
import '../../profile/screens/user_profile_screen.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatNotifier = ref.read(chatProvider.notifier);
      chatNotifier.loadChatRooms();
      // Cập nhật unread count định kỳ
      _startPeriodicUnreadCountUpdate();
    });
  }

  void _startPeriodicUnreadCountUpdate() {
    // Cập nhật unread count mỗi 30 giây
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        ref.read(chatProvider.notifier).updateUnreadCount();
        _startPeriodicUnreadCountUpdate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: Consumer(
        builder: (context, ref, child) {
          final chatState = ref.watch(chatProvider);
          
          if (chatState.isLoading && chatState.chatRooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải tin nhắn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chatState.error!,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(chatProvider.notifier).loadChatRooms(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (chatState.chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có tin nhắn nào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bắt đầu trò chuyện với nhà tuyển dụng hoặc ứng viên',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(chatProvider.notifier).loadChatRooms(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chatState.chatRooms.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final chatRoom = chatState.chatRooms[index];
                return _buildChatRoomCard(chatRoom);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatRoomCard(Map<String, dynamic> chatRoom) {
    final String roomId = chatRoom['id']?.toString() ?? '';
    final Map<String, dynamic> recruiterInfo = chatRoom['recruiterInfo'] ?? {};
    final Map<String, dynamic> candidateInfo = chatRoom['candidateInfo'] ?? {};
    final Map<String, dynamic> jobInfo = chatRoom['jobInfo'] ?? {};
    final dynamic lastMessageData = chatRoom['lastMessage'];
    final int unreadCount = chatRoom['unreadCount'] ?? 0;
    final String lastMessageTime = chatRoom['lastMessageTime']?.toString() ?? '';

    // Xác định thông tin người chat (dựa vào role của user hiện tại)
    // TODO: Lấy từ user provider thực tê
    final bool isRecruiter = recruiterInfo.isNotEmpty && candidateInfo.isNotEmpty 
        ? true  // Mặc định là recruiter, có thể thay đổi dựa trên context
        : recruiterInfo.isNotEmpty;
    final Map<String, dynamic> otherUserInfo = isRecruiter ? candidateInfo : recruiterInfo;
    final String otherUserName = (otherUserInfo['fullName'] ?? otherUserInfo['name'] ?? 'Người dùng').toString();
    final String otherUserAvatar = (otherUserInfo['avatar'] ?? '').toString();

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                roomId: roomId,
                otherUserName: otherUserName,
                otherUserAvatar: otherUserAvatar,
                jobInfo: jobInfo,
                recruiterInfo: recruiterInfo,
                candidateInfo: candidateInfo,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  _buildAvatar(otherUserAvatar, otherUserName, radius: 28),
                  // Online status indicator
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Thông tin chat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên và thời gian
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageTime.isNotEmpty)
                          Text(
                            _formatTime(lastMessageTime),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Công việc (nếu có)
                    if (jobInfo.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (jobInfo['title'] ?? 'Vị trí tuyển dụng').toString(),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    // Tin nhắn cuối và số tin nhắn chưa đọc
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getLastMessageText(lastMessageData),
                            style: TextStyle(
                              color: unreadCount > 0 
                                  ? Colors.black87 
                                  : Colors.grey.shade600,
                              fontWeight: unreadCount > 0 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Menu options
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade400,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      _viewProfile(otherUserInfo);
                      break;
                    case 'delete':
                      _deleteChatRoom(roomId);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline),
                        SizedBox(width: 8),
                        Text('Xem hồ sơ'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa cuộc trò chuyện', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl, String name, {double radius = 28}) {
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.grey.shade300,
      );
    } else {
      // Use first letter of name as avatar
      String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blue.shade100,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w600,
            fontSize: radius * 0.6, // Scale font size with radius
          ),
        ),
      );
    }
  }

  String _getLastMessageText(dynamic lastMessageData) {
    // Handle both string and Map cases
    if (lastMessageData == null) return 'Chưa có tin nhắn';
    
    // If it's already a string, return it directly
    if (lastMessageData is String) {
      return lastMessageData.isEmpty ? 'Tin nhắn' : lastMessageData;
    }
    
    // If it's a Map, parse it
    if (lastMessageData is Map<String, dynamic>) {
      final String type = (lastMessageData['type'] ?? 'text').toString();
      final String content = (lastMessageData['content'] ?? '').toString();
      
      switch (type) {
        case 'image':
          return '📷 Hình ảnh';
        case 'text':
        default:
          return content.isEmpty ? 'Tin nhắn' : content;
      }
    }
    
    // Fallback: convert anything to string
    return lastMessageData.toString().isEmpty ? 'Tin nhắn' : lastMessageData.toString();
  }

  String _formatTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    
    try {
      final DateTime messageTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(messageTime);
      
      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}p';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else {
        return '${messageTime.day}/${messageTime.month}';
      }
    } catch (e) {
      print('Error parsing timestamp: $timestamp, error: $e');
      return '';
    }
  }

  void _viewProfile(Map<String, dynamic> userInfo) {
    final String userId = userInfo['id'] ?? '';
    if (userId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: userId),
        ),
      );
    }
  }

  void _deleteChatRoom(String roomId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content: const Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện này? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(chatProvider.notifier).deleteChatRoom(roomId);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa cuộc trò chuyện'),
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
