import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../widgets/message_tile.dart';

class RealChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final Map<String, dynamic>? otherUserInfo;
  final Map<String, dynamic>? jobInfo;

  const RealChatScreen({
    super.key,
    required this.roomId,
    this.otherUserInfo,
    this.jobInfo,
  });

  @override
  ConsumerState<RealChatScreen> createState() => _RealChatScreenState();
}

class _RealChatScreenState extends ConsumerState<RealChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() async {
    try {
      print('DEBUG Chat: Initializing chat for room: ${widget.roomId}');
      
      final user = ref.read(authProvider);
      if (user.user == null) {
        print('DEBUG Chat: User not authenticated');
        return;
      }

      print('DEBUG Chat: User authenticated - ${user.user!.id}');

      // Subscribe to messages
      ref.read(chatProvider({
        'userId': user.user!.id,
        'userType': user.user!.role.toLowerCase(),
      }).notifier).subscribeToMessages(widget.roomId);

      setState(() {
        _isInitialized = true;
      });

      print('DEBUG Chat: Chat initialized successfully');
    } catch (e) {
      print('DEBUG Chat: Error initializing chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khởi tạo chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authProvider);
    if (user.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để gửi tin nhắn'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG Chat: Sending message: $text');

      await ref.read(chatProvider({
        'userId': user.user!.id,
        'userType': user.user!.role.toLowerCase(),
      }).notifier).sendMessage(
        widget.roomId,
        text,
        user.user!.role.toLowerCase(),
        {
          'name': '${user.user!.firstName} ${user.user!.lastName}'.trim(),
          'avatar': user.user!.avatar,
          'id': user.user!.id,
        },
      );

      _messageController.clear();
      
      // Auto scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      print('DEBUG Chat: Message sent successfully');
    } catch (e) {
      print('DEBUG Chat: Error sending message: $e');
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
    
    if (user.user == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Vui lòng đăng nhập để sử dụng chat'),
            ],
          ),
        ),
      );
    }

    final chatState = ref.watch(chatProvider({
      'userId': user.user!.id,
      'userType': user.user!.role.toLowerCase(),
    }));

    final otherUserName = widget.otherUserInfo?['name'] ?? 'Người dùng';
    final jobTitle = widget.jobInfo?['title'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherUserName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (jobTitle.isNotEmpty)
              Text(
                jobTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              _isInitialized && !chatState.isLoading 
                  ? Icons.circle
                  : Icons.circle_outlined,
              color: _isInitialized && !chatState.isLoading 
                  ? Colors.green
                  : Colors.orange,
              size: 12,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showChatInfo(),
          ),
          // Debug connection test button
          IconButton(
            icon: const Icon(Icons.wifi),
            onPressed: () => _testFirebaseConnection(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status bar
          if (!_isInitialized || chatState.isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange[100],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isInitialized ? 'Đang tải tin nhắn...' : 'Đang kết nối...',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

          // Chat info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Firebase Chat',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Spacer(),
                    Text(
                      _isInitialized && !chatState.isLoading ? '🟢 Kết nối' : '🟡 Đang kết nối',
                      style: TextStyle(
                        fontSize: 10, 
                        color: _isInitialized && !chatState.isLoading ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Room: ${widget.roomId}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (chatState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Lỗi: ${chatState.error}',
                      style: const TextStyle(fontSize: 10, color: Colors.red),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Messages area
          Expanded(
            child: _buildMessagesArea(chatState, user.user!.id),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesArea(chatState, String currentUserId) {
    if (chatState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Có lỗi xảy ra', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              chatState.error!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeChat(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (chatState.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có tin nhắn nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy bắt đầu cuộc trò chuyện!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        final isMe = message['senderId'] == currentUserId;
        
        return MessageTile(
          message: message,
          isMe: isMe,
          showAvatar: index == 0 || 
              (index > 0 && 
               chatState.messages[index - 1]['senderId'] != message['senderId']),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
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
            decoration: const BoxDecoration(
              color: Colors.blue,
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

  void _testFirebaseConnection() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang chạy Firebase diagnostic test...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      final chatService = ref.read(chatServiceProvider);
      final results = await chatService.diagnosticTest();

      // Show detailed results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Firebase Diagnostic Results'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...results.entries.map((entry) {
                  final value = entry.value;
                  final isSuccess = value is Map && value['status'] == 'success';
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSuccess ? Icons.check_circle : Icons.error,
                              color: isSuccess ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _testSimpleConnection();
              },
              child: const Text('Test Lại'),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi diagnostic: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _testSimpleConnection() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final isConnected = await chatService.testConnection();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConnected 
                ? '✅ Firebase kết nối thành công!' 
                : '❌ Firebase không thể kết nối',
          ),
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi test connection: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Room ID', widget.roomId),
            const SizedBox(height: 8),
            _buildInfoRow('Người chat', widget.otherUserInfo?['name'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow('Email', widget.otherUserInfo?['email'] ?? 'N/A'),
            if (widget.jobInfo != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Công việc', widget.jobInfo!['title'] ?? 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow('Công ty', widget.jobInfo!['company'] ?? 'N/A'),
            ],
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
