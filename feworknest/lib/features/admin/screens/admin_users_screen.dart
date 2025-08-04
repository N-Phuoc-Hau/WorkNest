import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new user functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng thêm người dùng đang phát triển')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm người dùng...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      // TODO: Implement search functionality
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'candidate', child: Text('Ứng viên')),
                    DropdownMenuItem(value: 'recruiter', child: Text('Nhà tuyển dụng')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Users List
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Mock data
              itemBuilder: (context, index) {
                return _buildUserCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(int index) {
    final mockUsers = [
      {'name': 'Nguyễn Văn A', 'email': 'nguyenvana@email.com', 'role': 'candidate', 'status': 'active'},
      {'name': 'Trần Thị B', 'email': 'tranthib@email.com', 'role': 'recruiter', 'status': 'active'},
      {'name': 'Lê Văn C', 'email': 'levanc@email.com', 'role': 'admin', 'status': 'active'},
      {'name': 'Phạm Thị D', 'email': 'phamthid@email.com', 'role': 'candidate', 'status': 'inactive'},
      {'name': 'Hoàng Văn E', 'email': 'hoangvane@email.com', 'role': 'recruiter', 'status': 'active'},
    ];

    final user = mockUsers[index % mockUsers.length];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user['role']!),
          child: Text(
            user['name']!.substring(0, 1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user['name']!),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email']!),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user['role']!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleText(user['role']!),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user['status'] == 'active' ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user['status'] == 'active' ? 'Hoạt động' : 'Không hoạt động',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _handleUserAction(value, user);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
            const PopupMenuItem(value: 'block', child: Text('Khóa tài khoản')),
            const PopupMenuItem(value: 'delete', child: Text('Xóa')),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'recruiter':
        return Colors.blue;
      case 'candidate':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'recruiter':
        return 'Nhà tuyển dụng';
      case 'candidate':
        return 'Ứng viên';
      default:
        return 'Unknown';
    }
  }

  void _handleUserAction(String action, Map<String, String> user) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chỉnh sửa người dùng: ${user['name']}')),
        );
        break;
      case 'block':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Khóa tài khoản: ${user['name']}')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa người dùng: ${user['name']}')),
        );
        break;
    }
  }
} 