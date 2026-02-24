import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/chat_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../profile/screens/user_profile_screen.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        title: Text(
          'Messages',
          style: AppTypography.h4.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.neutral200,
          ),
        ),
      ),
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          
          // Divider
          Container(
            height: 1,
            color: AppColors.neutral200,
          ),
          
          // Messages list
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final chatState = ref.watch(chatProvider);
                
                if (chatState.isLoading && chatState.chatRooms.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (chatState.error != null) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.spacing32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: AppColors.neutral300,
                          ),
                          SizedBox(height: AppSpacing.spacing16),
                          Text(
                            'Lỗi tải tin nhắn',
                            style: AppTypography.h5.copyWith(
                              color: AppColors.neutral700,
                            ),
                          ),
                          SizedBox(height: AppSpacing.spacing8),
                          Text(
                            chatState.error!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.neutral500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.spacing24),
                          ElevatedButton(
                            onPressed: () => ref.read(chatProvider.notifier).loadChatRooms(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.spacing24,
                                vertical: AppSpacing.spacing12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.borderRadiusLg,
                              ),
                            ),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Filter chat rooms based on search query
                final filteredChatRooms = _searchQuery.isEmpty
                    ? chatState.chatRooms
                    : chatState.chatRooms.where((chatRoom) {
                        final recruiterInfo = chatRoom['recruiterInfo'] ?? {};
                        final candidateInfo = chatRoom['candidateInfo'] ?? {};
                        final jobInfo = chatRoom['jobInfo'] ?? {};
                        
                        final otherUserName = (recruiterInfo['fullName'] ?? candidateInfo['fullName'] ?? '').toString().toLowerCase();
                        final jobTitle = (jobInfo['title'] ?? '').toString().toLowerCase();
                        final query = _searchQuery.toLowerCase();
                        
                        return otherUserName.contains(query) || jobTitle.contains(query);
                      }).toList();

                if (filteredChatRooms.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.spacing32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty 
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.search_off_rounded,
                            size: 64,
                            color: AppColors.neutral300,
                          ),
                          SizedBox(height: AppSpacing.spacing16),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'Chưa có tin nhắn nào'
                                : 'Không tìm thấy kết quả',
                            style: AppTypography.h5.copyWith(
                              color: AppColors.neutral700,
                            ),
                          ),
                          SizedBox(height: AppSpacing.spacing8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Bắt đầu trò chuyện với nhà tuyển dụng hoặc ứng viên'
                                : 'Thử tìm kiếm với từ khóa khác',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.neutral500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(chatProvider.notifier).loadChatRooms(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filteredChatRooms.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.neutral100,
                      indent: AppSpacing.spacing64,
                    ),
                    itemBuilder: (context, index) {
                      final chatRoom = filteredChatRooms[index];
                      return _buildChatRoomCard(chatRoom);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing16),
      color: AppColors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search messages',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutral400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.neutral400,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.neutral400,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.neutral50,
          border: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusLg,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusLg,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusLg,
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing16,
            vertical: AppSpacing.spacing12,
          ),
          isDense: true,
        ),
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

    // Xác định thông tin người chat
    final bool isRecruiter = recruiterInfo.isNotEmpty && candidateInfo.isNotEmpty 
        ? true
        : recruiterInfo.isNotEmpty;
    final Map<String, dynamic> otherUserInfo = isRecruiter ? candidateInfo : recruiterInfo;
    final String otherUserName = (otherUserInfo['fullName'] ?? otherUserInfo['name'] ?? 'Người dùng').toString();
    final String otherUserAvatar = (otherUserInfo['avatar'] ?? '').toString();
    final String otherUserRole = isRecruiter 
        ? (candidateInfo['role'] ?? 'Candidate').toString()
        : 'Recruiter at ${recruiterInfo['company'] ?? 'Company'}';

    return Material(
      color: AppColors.white,
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
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing16,
            vertical: AppSpacing.spacing16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  _buildAvatar(otherUserAvatar, otherUserName, radius: 24),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: AppSpacing.spacing12),
              
              // Message info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: AppTypography.semiBold,
                              color: AppColors.neutral900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageTime.isNotEmpty)
                          Text(
                            _formatTime(lastMessageTime),
                            style: AppTypography.caption.copyWith(
                              color: unreadCount > 0 
                                  ? AppColors.primary
                                  : AppColors.neutral500,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacing2),
                    
                    // Role/Company
                    Text(
                      otherUserRole,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.neutral500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.spacing8),
                    
                    // Last message and unread badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getLastMessageText(lastMessageData),
                            style: AppTypography.bodyMedium.copyWith(
                              color: unreadCount > 0
                                  ? AppColors.neutral900
                                  : AppColors.neutral500,
                              fontWeight: unreadCount > 0 
                                  ? AppTypography.medium
                                  : AppTypography.regular,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          SizedBox(width: AppSpacing.spacing8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacing8,
                              vertical: AppSpacing.spacing2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.white,
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // More options
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.neutral400,
                  size: 20,
                ),
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusLg,
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
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: AppColors.neutral700,
                        ),
                        SizedBox(width: AppSpacing.spacing12),
                        Text(
                          'Xem hồ sơ',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                        SizedBox(width: AppSpacing.spacing12),
                        Text(
                          'Xóa cuộc trò chuyện',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
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

  Widget _buildAvatar(String avatarUrl, String name, {double radius = 24}) {
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppColors.neutral200,
      );
    } else {
      // Use first letter of name as avatar
      String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryLighter,
        child: Text(
          initial,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.primary,
            fontWeight: AppTypography.semiBold,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
