import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _systemAlerts = true;
  bool _darkMode = false;
  String _language = 'Tiếng Việt';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt Admin'),
      ),
      body: ListView(
        children: [
          // System Management Section
          _buildSectionHeader('Quản lý hệ thống'),
          _buildListTile(
            icon: Icons.admin_panel_settings,
            title: 'Cấu hình hệ thống',
            subtitle: 'Cài đặt thông số hệ thống',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chuyển đến trang cấu hình hệ thống')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.backup,
            title: 'Sao lưu dữ liệu',
            subtitle: 'Tạo bản sao lưu hệ thống',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng sao lưu đang phát triển')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.restore,
            title: 'Khôi phục dữ liệu',
            subtitle: 'Khôi phục từ bản sao lưu',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng khôi phục đang phát triển')),
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
            secondary: const Icon(Icons.warning),
            title: const Text('Cảnh báo hệ thống'),
            subtitle: const Text('Thông báo sự cố hệ thống'),
            value: _systemAlerts,
            onChanged: (value) {
              setState(() {
                _systemAlerts = value;
              });
            },
          ),
          
          const Divider(),
          
          // Security Section
          _buildSectionHeader('Bảo mật'),
          _buildListTile(
            icon: Icons.lock,
            title: 'Đổi mật khẩu',
            subtitle: 'Cập nhật mật khẩu admin',
            onTap: () {
              _showChangePasswordDialog();
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
          _buildListTile(
            icon: Icons.vpn_key,
            title: 'Quản lý API Keys',
            subtitle: 'Quản lý khóa API hệ thống',
            onTap: () {
              _showApiKeysDialog();
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
          
          // System Section
          _buildSectionHeader('Hệ thống'),
          _buildListTile(
            icon: Icons.analytics,
            title: 'Xem logs hệ thống',
            subtitle: 'Theo dõi hoạt động hệ thống',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mở logs hệ thống')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.analytics,
            title: 'Thống kê hệ thống',
            subtitle: 'Xem thống kê chi tiết',
            onTap: () {
              _showSystemStatsDialog();
            },
          ),
          _buildListTile(
            icon: Icons.update,
            title: 'Cập nhật hệ thống',
            subtitle: 'Kiểm tra và cập nhật',
            onTap: () {
              _showUpdateDialog();
            },
          ),
          
          const Divider(),
          
          // Support Section
          _buildSectionHeader('Hỗ trợ'),
          _buildListTile(
            icon: Icons.help,
            title: 'Trung tâm trợ giúp',
            subtitle: 'Hướng dẫn quản trị',
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
            title: 'Về hệ thống',
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

  void _showApiKeysDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quản lý API Keys'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tính năng quản lý API Keys đang phát triển...'),
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

  void _showSystemLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Logs'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tính năng xem logs hệ thống đang phát triển...'),
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

  void _showSystemStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thống kê hệ thống'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng số người dùng: 1,250'),
            Text('Tổng số công ty: 150'),
            Text('Tổng số tin tuyển dụng: 500'),
            Text('Ứng viên online: 45'),
            SizedBox(height: 16),
            Text('Tính năng thống kê chi tiết đang phát triển...'),
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

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật hệ thống'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Phiên bản hiện tại: 1.0.0'),
            Text('Phiên bản mới nhất: 1.0.0'),
            SizedBox(height: 16),
            Text('Hệ thống đã được cập nhật mới nhất!'),
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
        title: const Text('Về hệ thống'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WorkNest Admin System'),
            Text('Phiên bản: 1.0.0'),
            Text('Hệ thống quản trị WorkNest'),
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