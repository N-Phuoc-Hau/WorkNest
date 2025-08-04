import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecruiterSettingsScreen extends ConsumerStatefulWidget {
  const RecruiterSettingsScreen({super.key});

  @override
  ConsumerState<RecruiterSettingsScreen> createState() => _RecruiterSettingsScreenState();
}

class _RecruiterSettingsScreenState extends ConsumerState<RecruiterSettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _applicationAlerts = true;
  bool _darkMode = false;
  String _language = 'Tiếng Việt';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          // Company Profile Section
          _buildSectionHeader('Hồ sơ công ty'),
          _buildListTile(
            icon: Icons.business,
            title: 'Chỉnh sửa thông tin công ty',
            subtitle: 'Cập nhật thông tin công ty',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chuyển đến trang chỉnh sửa thông tin công ty')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.photo_camera,
            title: 'Thay đổi logo công ty',
            subtitle: 'Cập nhật logo công ty',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng thay đổi logo đang phát triển')),
              );
            },
          ),
          
          const Divider(),
          
          // Notifications Section
          _buildSectionHeader('Thông báo'),
          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Thông báo email'),
            subtitle: const Text('Nhận thông báo qua email'),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Thông báo đẩy'),
            subtitle: const Text('Nhận thông báo trên thiết bị'),
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.people),
            title: const Text('Thông báo ứng viên'),
            subtitle: const Text('Thông báo khi có ứng viên mới'),
            value: _applicationAlerts,
            onChanged: (value) {
              setState(() {
                _applicationAlerts = value;
              });
            },
          ),
          
          const Divider(),
          
          // Privacy & Security Section
          _buildSectionHeader('Bảo mật & Quyền riêng tư'),
          _buildListTile(
            icon: Icons.lock,
            title: 'Đổi mật khẩu',
            subtitle: 'Cập nhật mật khẩu tài khoản',
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
          _buildListTile(
            icon: Icons.visibility,
            title: 'Quyền riêng tư',
            subtitle: 'Quản lý quyền riêng tư công ty',
            onTap: () {
              _showPrivacySettingsDialog();
            },
          ),
          _buildListTile(
            icon: Icons.security,
            title: 'Bảo mật hai lớp',
            subtitle: 'Bật xác thực hai yếu tố',
            onTap: () {
              _showTwoFactorDialog();
            },
          ),
          
          const Divider(),
          
          // Preferences Section
          _buildSectionHeader('Tùy chọn'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Chế độ tối'),
            subtitle: const Text('Giao diện tối'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Ngôn ngữ'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showLanguageDialog();
            },
          ),
          
          const Divider(),
          
          // Account Section
          _buildSectionHeader('Tài khoản'),
          _buildListTile(
            icon: Icons.download,
            title: 'Xuất dữ liệu',
            subtitle: 'Tải xuống dữ liệu công ty',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng xuất dữ liệu đang phát triển')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.delete_forever,
            title: 'Xóa tài khoản',
            subtitle: 'Xóa vĩnh viễn tài khoản',
            onTap: () {
              _showDeleteAccountDialog();
            },
            textColor: Colors.red,
          ),
          
          const Divider(),
          
          // Support Section
          _buildSectionHeader('Hỗ trợ'),
          _buildListTile(
            icon: Icons.help,
            title: 'Trung tâm trợ giúp',
            subtitle: 'Hướng dẫn sử dụng',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chuyển đến trang trợ giúp')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.feedback,
            title: 'Gửi phản hồi',
            subtitle: 'Đóng góp ý kiến',
            onTap: () {
              _showFeedbackDialog();
            },
          ),
          _buildListTile(
            icon: Icons.info,
            title: 'Về ứng dụng',
            subtitle: 'Phiên bản 1.0.0',
            onTap: () {
              _showAboutDialog();
            },
          ),
          
          const SizedBox(height: 20),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                _showLogoutDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Đăng xuất'),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: textColor?.withOpacity(0.7))),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tính năng đổi mật khẩu đang phát triển...'),
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

  void _showPrivacySettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quyền riêng tư'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tính năng quản lý quyền riêng tư đang phát triển...'),
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

  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bảo mật hai lớp'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tính năng xác thực hai yếu tố đang phát triển...'),
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tiếng Việt'),
              onTap: () {
                setState(() {
                  _language = 'Tiếng Việt';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                setState(() {
                  _language = 'English';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text('Bạn có chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng xóa tài khoản đang phát triển')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi phản hồi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tính năng gửi phản hồi đang phát triển...'),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Về ứng dụng'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WorkNest'),
            Text('Phiên bản: 1.0.0'),
            Text('Ứng dụng tìm kiếm việc làm và tuyển dụng'),
            SizedBox(height: 16),
            Text('© 2024 WorkNest. All rights reserved.'),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đăng xuất thành công')),
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
} 