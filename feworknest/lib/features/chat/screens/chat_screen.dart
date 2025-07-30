import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/message_tile.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final Map<String, dynamic>? otherUserInfo;
  final Map<String, dynamic>? jobInfo;

  const ChatScreen({
    super.key,
    required this.roomId,
    this.otherUserInfo,
    this.jobInfo,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToMessages();
    });
  }

  void _subscribeToMessages() {
    final user = ref.read(authProvider);
    if (user != null) {
      ref.read(chatProvider({
        'userId': user.id,
        'userType': user.role.toLowerCase(),
      })).subscribeToMessages(widget.roomId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(chatProvider({
        'userId': user.id,
        'userType': user.role.toLowerCase(),
      })).sendMessage(
        widget.roomId,
        _messageController.text.trim(),
        user.role.toLowerCase(),
        {
          'name': user.firstName + ' ' + user.lastName,
          'avatar': user.avatar,
        },
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi tin nhắn: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập'),
        ),
      );
    }

    final chatState = ref.watch(chatProvider({
      'userId': user.id,
      'userType': user.role.toLowerCase(),
    }));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserInfo?['name'] ?? 'Unknown User',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.jobInfo != null)
              Text(
                widget.jobInfo!['title'] ?? 'Unknown Job',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: chatState.error != null
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
                          chatState.error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(chatProvider({
                              'userId': user.id,
                              'userType': user.role.toLowerCase(),
                            })).clearError();
                            _subscribeToMessages();
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : chatState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có tin nhắn nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bắt đầu trò chuyện!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatState.messages[index];
                          final isMe = message['senderId'] == user.id;
                          
                          return MessageTile(
                            message: message,
                            isMe: isMe,
                            showAvatar: index == 0 || 
                                (index > 0 && 
                                 chatState.messages[index - 1]['senderId'] != message['senderId']),
                          );
                        },
                      ),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: Colors.grey[600],
            ),
            onPressed: () {
              // TODO: Implement file attachment
            },
          ),
          
          // Message input
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Send button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Thông tin chat'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show chat info
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Xóa chat'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa chat'),
        content: const Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _deleteChat() {
    final user = ref.read(authProvider);
    if (user != null) {
      ref.read(chatProvider({
        'userId': user.id,
        'userType': user.role.toLowerCase(),
      })).deleteChatRoom(widget.roomId).then((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa cuộc trò chuyện'),
          ),
        );
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }
} 