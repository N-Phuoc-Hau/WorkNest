import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String otherUserName;
  final String otherUserAvatar;
  final Map<String, dynamic> jobInfo;
  final Map<String, dynamic> recruiterInfo;
  final Map<String, dynamic> candidateInfo;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.jobInfo = const {},
    this.recruiterInfo = const {},
    this.candidateInfo = const {},
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatNotifier = ref.read(chatProvider.notifier);
      chatNotifier.loadMessages(widget.roomId);
      chatNotifier.markAsRead(widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get role info
    final String otherUserRole = widget.recruiterInfo.isNotEmpty
        ? 'Recruiter at ${widget.recruiterInfo['company'] ?? 'Company'}'
        : widget.candidateInfo['role'] ?? 'Candidate';

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: _buildAppBar(otherUserRole),
      body: Column(
        children: [
          // Messages
          Expanded(child: _buildMessagesArea()),
          
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String otherUserRole) {
    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.neutral900,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildAvatar(widget.otherUserAvatar, widget.otherUserName, radius: 20),
          SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.neutral900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  otherUserRole,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.star_outline_rounded,
            color: AppColors.neutral600,
          ),
          onPressed: () {
            // TODO: Favorite chat
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: AppColors.neutral600,
          ),
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          onSelected: (value) {
            switch (value) {
              case 'info':
                _showChatInfo();
                break;
              case 'clear':
                _clearChat();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.neutral700,
                  ),
                  SizedBox(width: AppSpacing.spacing12),
                  Text(
                    'Thông tin',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_sweep_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  SizedBox(width: AppSpacing.spacing12),
                  Text(
                    'Xóa tin nhắn',
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.neutral200,
        ),
      ),
    );
  }

  Widget _buildMessagesArea() {
    return Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatProvider);
        
        if (chatState.isLoading && chatState.currentMessages.isEmpty) {
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
                    onPressed: () => ref.read(chatProvider.notifier).loadMessages(widget.roomId),
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

        final messages = chatState.currentMessages;
        
        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.spacing32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: AppColors.neutral300,
                  ),
                  SizedBox(height: AppSpacing.spacing16),
                  Text(
                    'This is the very beginning of your direct message with ${widget.otherUserName}',
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

        // Group messages by date
        final groupedMessages = _groupMessagesByDate(messages);

        return ListView.builder(
          controller: _scrollController,
          reverse: false,
          padding: EdgeInsets.all(AppSpacing.spacing16),
          itemCount: groupedMessages.length,
          itemBuilder: (context, index) {
            final group = groupedMessages[index];
            return Column(
              children: [
                // Date divider
                _buildDateDivider(group['date'] as String),
                SizedBox(height: AppSpacing.spacing16),
                // Messages
                ...((group['messages'] as List).map((message) => _buildMessageBubble(message as Map<String, dynamic>))),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateDivider(String date) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Text(
        date,
        style: AppTypography.caption.copyWith(
          color: AppColors.neutral600,
          fontWeight: AppTypography.medium,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupMessagesByDate(List messages) {
    final grouped = <Map<String, dynamic>>[];
    String? currentDate;
    List currentMessages = [];

    for (var message in messages) {
      final timestamp = message['timestamp']?.toString() ?? '';
      if (timestamp.isEmpty) continue;

      try {
        final messageDate = DateTime.parse(timestamp);
        final dateKey = _getDateLabel(messageDate);

        if (dateKey != currentDate) {
          if (currentMessages.isNotEmpty) {
            grouped.add({
              'date': currentDate!,
              'messages': List.from(currentMessages),
            });
            currentMessages.clear();
          }
          currentDate = dateKey;
        }
        currentMessages.add(message);
      } catch (e) {
        // Skip invalid timestamps
      }
    }

    if (currentMessages.isNotEmpty && currentDate != null) {
      grouped.add({
        'date': currentDate,
        'messages': currentMessages,
      });
    }

    return grouped;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final String senderId = (message['senderId'] ?? '').toString();
    final String content = (message['content'] ?? '').toString();
    final String type = (message['messageType'] ?? message['type'] ?? 'text').toString();
    final String timestamp = (message['timestamp'] ?? '').toString();
    final String? imageUrl = message['fileUrl']?.toString();
    
    // Get current user ID from auth provider
    final authState = ref.watch(authProvider);
    final String? currentUserId = authState.user?.id;
    final bool isMyMessage = currentUserId != null && senderId == currentUserId;
    
    // Get sender avatar and name based on senderId
    String senderAvatar = '';
    String senderName = '';
    
    if (!isMyMessage) {
      // Determine if sender is recruiter or candidate
      if (widget.recruiterInfo.isNotEmpty && widget.recruiterInfo['id']?.toString() == senderId) {
        senderAvatar = (widget.recruiterInfo['avatar'] ?? '').toString();
        senderName = (widget.recruiterInfo['name'] ?? 'Recruiter').toString();
      } else if (widget.candidateInfo.isNotEmpty && widget.candidateInfo['id']?.toString() == senderId) {
        senderAvatar = (widget.candidateInfo['avatar'] ?? '').toString();
        senderName = (widget.candidateInfo['name'] ?? 'Candidate').toString();
      } else {
        // Fallback to otherUserAvatar
        senderAvatar = widget.otherUserAvatar;
        senderName = widget.otherUserName;
      }
    }
    
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacing12),
      child: Row(
        mainAxisAlignment: isMyMessage 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other user's messages (left side)
          if (!isMyMessage) ...[
            _buildAvatar(senderAvatar, senderName, radius: 16),
            SizedBox(width: AppSpacing.spacing8),
          ],
          
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing16,
                    vertical: AppSpacing.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: isMyMessage 
                        ? AppColors.primary 
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isMyMessage 
                          ? const Radius.circular(4) 
                          : const Radius.circular(16),
                      bottomLeft: !isMyMessage 
                          ? const Radius.circular(4) 
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(type, content, imageUrl, isMyMessage),
                ),
                if (timestamp.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppSpacing.spacing4,
                      left: AppSpacing.spacing4,
                      right: AppSpacing.spacing4,
                    ),
                    child: Text(
                      _formatMessageTime(timestamp),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl, String name, {double radius = 16}) {
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
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: AppTypography.semiBold,
            fontSize: radius * 0.875,
          ),
        ),
      );
    }
  }

  Widget _buildMessageContent(String type, String content, String? fileUrl, bool isMyMessage) {
    switch (type) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fileUrl != null && fileUrl.isNotEmpty)
              ClipRRect(
                borderRadius: AppSpacing.borderRadiusLg,
                child: Image.network(
                  fileUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: AppSpacing.borderRadiusLg,
                      ),
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 40,
                        color: AppColors.neutral400,
                      ),
                    );
                  },
                ),
              ),
            if (content.isNotEmpty) ...[
              SizedBox(height: AppSpacing.spacing8),
              Text(
                content,
                style: AppTypography.bodyMedium.copyWith(
                  color: isMyMessage ? AppColors.white : AppColors.neutral900,
                ),
              ),
            ],
          ],
        );
      case 'text':
      default:
        return Text(
          content,
          style: AppTypography.bodyMedium.copyWith(
            color: isMyMessage ? AppColors.white : AppColors.neutral900,
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.neutral500,
                size: 24,
              ),
              onPressed: _pickImage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Reply message',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide: BorderSide(
                      color: AppColors.neutral200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide: BorderSide(
                      color: AppColors.neutral200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing16,
                    vertical: AppSpacing.spacing12,
                  ),
                  isDense: true,
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: AppTypography.bodyMedium,
                onChanged: (text) {
                  setState(() {
                    _isTyping = text.isNotEmpty;
                  });
                },
              ),
            ),
            SizedBox(width: AppSpacing.spacing12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isTyping ? AppColors.primary : AppColors.neutral300,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
                onPressed: _isTyping ? _sendMessage : null,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final String content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    setState(() {
      _isTyping = false;
    });

    final success = await ref.read(chatProvider.notifier).sendTextMessage(
      widget.roomId,
      content,
    );

    if (success) {
      _scrollToBottom();
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi tin nhắn')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Validate file extension
        final fileName = image.name.toLowerCase();
        final supportedExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
        final isSupported = supportedExtensions.any((ext) => fileName.endsWith(ext));
        
        if (!isSupported) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chỉ hỗ trợ định dạng ảnh JPEG, PNG và GIF'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Đang gửi ảnh...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }
        
        final success = await ref.read(chatProvider.notifier).sendImageMessage(
          widget.roomId,
          image,
        );
        
        // Clear loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }
        
        if (success) {
          _scrollToBottom();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gửi ảnh thành công'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể gửi hình ảnh'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error picking/sending image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().contains('Chỉ hỗ trợ') ? e.toString().split('Exception: ').last : 'Không thể gửi ảnh'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Thay đổi để scroll xuống bottom thay vì lên top (do không còn reverse)
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatMessageTime(String timestamp) {
    try {
      final DateTime messageTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      
      if (now.difference(messageTime).inDays == 0) {
        return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${messageTime.day}/${messageTime.month} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin cuộc trò chuyện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Người nhận: ${widget.otherUserName}'),
            if (widget.jobInfo.isNotEmpty)
              Text('Công việc: ${widget.jobInfo['title']}'),
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

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin nhắn'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả tin nhắn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng xóa tin nhắn sẽ sớm có')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
