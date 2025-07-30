import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../widgets/user_search_tile.dart';

class StartChatScreen extends ConsumerStatefulWidget {
  const StartChatScreen({super.key});

  @override
  ConsumerState<StartChatScreen> createState() => _StartChatScreenState();
}

class _StartChatScreenState extends ConsumerState<StartChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement user search API
      // For now, show mock data
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _searchResults = [
          {
            'id': 'user1',
            'name': 'John Doe',
            'avatar': null,
            'role': 'recruiter',
            'company': 'Tech Corp',
          },
          {
            'id': 'user2',
            'name': 'Jane Smith',
            'avatar': null,
            'role': 'candidate',
            'title': 'Software Engineer',
          },
        ].where((user) => 
          user['name'].toLowerCase().contains(query.toLowerCase()) ||
          (user['company']?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (user['title']?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tìm kiếm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startChat(Map<String, dynamic> otherUser) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    try {
      final chatNotifier = ref.read(chatProvider({
        'userId': user.id,
        'userType': user.role.toLowerCase(),
      }));

      final roomId = await chatNotifier.createOrGetChatRoom(
        recruiterId: user.role.toLowerCase() == 'recruiter' ? user.id : otherUser['id'],
        candidateId: user.role.toLowerCase() == 'candidate' ? user.id : otherUser['id'],
        recruiterInfo: user.role.toLowerCase() == 'recruiter' ? {
          'name': user.firstName + ' ' + user.lastName,
          'avatar': user.avatar,
        } : {
          'name': otherUser['name'],
          'avatar': otherUser['avatar'],
        },
        candidateInfo: user.role.toLowerCase() == 'candidate' ? {
          'name': user.firstName + ' ' + user.lastName,
          'avatar': user.avatar,
        } : {
          'name': otherUser['name'],
          'avatar': otherUser['avatar'],
        },
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              roomId: roomId,
              otherUserInfo: {
                'name': otherUser['name'],
                'avatar': otherUser['avatar'],
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bắt đầu chat'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
          ),
          
          // Search results
          Expanded(
            child: _searchResults.isEmpty && _searchController.text.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy người dùng',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thử tìm kiếm với từ khóa khác',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : _searchResults.isEmpty
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
                              'Tìm kiếm để bắt đầu chat',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nhập tên người dùng hoặc công ty\nđể tìm kiếm',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return UserSearchTile(
                            user: user,
                            onTap: () => _startChat(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 