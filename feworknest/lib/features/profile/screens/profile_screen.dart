import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? 'Người dùng',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user?.isRecruiter == true
                          ? Colors.orange
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.isRecruiter == true ? 'Nhà tuyển dụng' : 'Ứng viên',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Menu Items
            _buildMenuItem(
              context,
              icon: Icons.person,
              title: 'Chỉnh sửa hồ sơ',
              subtitle: 'Cập nhật thông tin cá nhân',
              onTap: () {
                context.push('/profile/edit');
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.star,
              title: 'Đánh giá của tôi',
              subtitle: 'Xem các đánh giá đã nhận',
              onTap: () {
                context.push('/reviews');
              },
            ),
            if (user?.isRecruiter == true) ...[
              _buildMenuItem(
                context,
                icon: Icons.business,
                title: 'Thông tin công ty',
                subtitle: 'Quản lý thông tin công ty',
                onTap: () {
                  context.push('/recruiter/company');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.work,
                title: 'Quản lý tin tuyển dụng',
                subtitle: 'Xem và chỉnh sửa tin đã đăng',
                onTap: () {
                  context.push('/recruiter/jobs');
                },
              ),
            ] else ...[
              _buildMenuItem(
                context,
                icon: Icons.description,
                title: 'Đơn ứng tuyển',
                subtitle: 'Theo dõi trạng thái đơn ứng tuyển',
                onTap: () {
                  context.push('/applications');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.favorite,
                title: 'Việc làm đã lưu',
                subtitle: 'Danh sách việc làm yêu thích',
                onTap: () {
                  context.push('/favorites');
                },
              ),
            ],
            _buildMenuItem(
              context,
              icon: Icons.notifications,
              title: 'Thông báo',
              subtitle: 'Cài đặt thông báo',
              onTap: () {
                context.push('/notifications');
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.help,
              title: 'Trợ giúp',
              subtitle: 'Câu hỏi thường gặp',
              onTap: () {
                context.push('/help');
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Đăng xuất',
              subtitle: 'Thoát khỏi tài khoản',
              onTap: () => _showLogoutDialog(context, ref),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/');
                }
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}
