import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String otherUserName;
  final String otherUserAvatar;
  final Map<String, dynamic> jobInfo;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.jobInfo = const {},
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Job info banner (nếu có)
          if (widget.jobInfo.isNotEmpty) _buildJobInfoBanner(),
          
          // Messages
          Expanded(child: _buildMessagesArea()),
          
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: widget.otherUserAvatar.isNotEmpty
                ? NetworkImage(widget.otherUserAvatar)
                : null,
            backgroundColor: Colors.blue.shade100,
            child: widget.otherUserAvatar.isEmpty
                ? Icon(Icons.person, size: 20, color: Colors.blue.shade600)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Đang hoạt động',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng gọi điện sẽ sớm có')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng video call sẽ sớm có')),
            );
          },
        ),
        PopupMenuButton<String>(
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
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Thông tin'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all_outlined),
                  SizedBox(width: 8),
                  Text('Xóa tin nhắn'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildJobInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.work_outline,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.jobInfo['title'] ?? 'Vị trí tuyển dụng',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                if (widget.jobInfo['company'] != null)
                  Text(
                    widget.jobInfo['company'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Navigate to job detail
            },
            child: Text(
              'Xem',
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    return Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatProvider);
        
        if (chatState.isLoading && chatState.currentMessages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tải tin nhắn',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  chatState.error!,
                  style: TextStyle(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(chatProvider.notifier).loadMessages(widget.roomId),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final messages = chatState.currentMessages;
        
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Chưa có tin nhắn',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Gửi tin nhắn đầu tiên để bắt đầu trò chuyện',
                  style: TextStyle(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: false, // Đổi thành false để không bị xổ ngược
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            // Đảo ngược index để tin nhắn mới nhất ở dưới cùng
            final reversedIndex = messages.length - 1 - index;
            final message = messages[reversedIndex];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final String senderId = message['senderId'] ?? '';
    final String content = message['content'] ?? '';
    final String type = message['messageType'] ?? message['type'] ?? 'text';
    final String timestamp = message['timestamp'] ?? '';
    final String? imageUrl = message['fileUrl'];
    
    // Get current user ID from auth provider
    final authState = ref.watch(authProvider);
    final String? currentUserId = authState.user?.id;
    final bool isMyMessage = currentUserId != null && senderId == currentUserId;
    
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: isMyMessage 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other user's messages (left side)
            if (!isMyMessage) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.otherUserAvatar.isNotEmpty
                    ? NetworkImage(widget.otherUserAvatar)
                    : null,
                backgroundColor: Colors.grey.shade300,
                child: widget.otherUserAvatar.isEmpty
                    ? Icon(Icons.person, size: 16, color: Colors.grey.shade600)
                    : null,
              ),
              const SizedBox(width: 8),
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
                      maxWidth: MediaQuery.of(context).size.width * 0.70,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMyMessage 
                          ? Colors.blue.shade500 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isMyMessage 
                            ? const Radius.circular(4) 
                            : const Radius.circular(20),
                        bottomLeft: !isMyMessage 
                            ? const Radius.circular(4) 
                            : const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildMessageContent(type, content, imageUrl, isMyMessage),
                  ),
                  if (timestamp.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                      child: Text(
                        _formatMessageTime(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Space for my messages (right side) to balance layout
            if (isMyMessage) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(String type, String content, String? fileUrl, bool isMyMessage) {
    switch (type) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fileUrl != null && fileUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.broken_image, size: 40),
                    );
                  },
                ),
              ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  color: isMyMessage ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        );
      case 'text':
      default:
        return Text(
          content,
          style: TextStyle(
            color: isMyMessage ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
                onChanged: (text) {
                  setState(() {
                    _isTyping = text.isNotEmpty;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _isTyping ? Colors.blue.shade500 : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _isTyping ? _sendMessage : null,
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
