import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/chat_room_tile.dart';
import '../widgets/start_chat_fab.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập để xem chat'),
        ),
      );
    }

    final chatState = ref.watch(chatProvider({
      'userId': user.user?.id ?? '',
      'userType': user.user?.role.toLowerCase() ?? '',
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: chatState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatState.error != null
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
                            'userId': user.user?.id ?? '',
                            'userType': user.user?.role.toLowerCase() ?? '',
                          }).notifier).clearError();
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : chatState.chatRooms.isEmpty
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
                            'Bắt đầu trò chuyện với nhà tuyển dụng\nhoặc ứng viên',
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
                        // Refresh chat rooms
                        ref.read(chatProvider({
                          'userId': user.user?.id ?? '',
                          'userType': user.user?.role.toLowerCase() ?? '',
                        }).notifier).clearError();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: chatState.chatRooms.length,
                        itemBuilder: (context, index) {
                          final chatRoom = chatState.chatRooms[index];
                          return ChatRoomTile(
                            chatRoom: chatRoom,
                            currentUserId: user.user?.id ?? '',
                            userType: user.user?.role.toLowerCase() ?? '',
                          );
                        },
                      ),
                    ),
      floatingActionButton: const StartChatFAB(),
    );
  }
} 