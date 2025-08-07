import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class MobileLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String? title;
  final int currentIndex;

  const MobileLayout({
    super.key,
    required this.child,
    this.title,
    this.currentIndex = 0,
  });

  @override
  ConsumerState<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<MobileLayout> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              backgroundColor: AppTheme.white,
              foregroundColor: AppTheme.black,
              elevation: 1,
              actions: [
                IconButton(
                  onPressed: () {
                    // TODO: Show notifications
                  },
                  icon: const Icon(Icons.notifications_outlined, color: AppTheme.primaryBlue),
                ),
              ],
            )
          : null,
      drawer: userRole != null ? MobileDrawer(userRole: userRole) : null,
      body: widget.child,
      bottomNavigationBar: userRole != null
          ? MobileBottomNavBar(
              userRole: userRole,
              currentIndex: widget.currentIndex,
            )
          : null,
    );
  }
}

class MobileBottomNavBar extends StatelessWidget {
  final String userRole;
  final int currentIndex;

  const MobileBottomNavBar({
    super.key,
    required this.userRole,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final items = _getBottomNavItems(userRole);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.white,
      selectedItemColor: AppTheme.primaryBlue,
      unselectedItemColor: AppTheme.mediumGrey,
      currentIndex: currentIndex < items.length ? currentIndex : 0,
      elevation: 8,
      items: items,
      onTap: (index) {
        final routes = _getBottomNavRoutes(userRole);
        if (index < routes.length) {
          context.go(routes[index]);
        }
      },
    );
  }

  List<BottomNavigationBarItem> _getBottomNavItems(String userRole) {
    if (userRole == 'candidate') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Tìm việc',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite),
          label: 'Yêu thích',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'Hồ sơ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Cá nhân',
        ),
      ];
    } else if (userRole == 'recruiter') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'Đăng tin',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work_outline),
          activeIcon: Icon(Icons.work),
          label: 'Tin tuyển dụng',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Ứng viên',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_outlined),
          activeIcon: Icon(Icons.chat),
          label: 'Tin nhắn',
        ),
      ];
    }
    
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Trang chủ',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search),
        label: 'Tìm việc',
      ),
    ];
  }

  List<String> _getBottomNavRoutes(String userRole) {
    if (userRole == 'candidate') {
      return [
        '/home',
        '/jobs',
        '/favorites',
        '/applications',
        '/profile',
      ];
    } else if (userRole == 'recruiter') {
      return [
        '/recruiter/home',
        '/recruiter/post-job',
        '/recruiter/jobs',
        '/recruiter/applicants',
        '/recruiter/chat',
      ];
    }
    
    return [
      '/',
      '/jobs',
    ];
  }
}

class MobileDrawer extends ConsumerWidget {
  final String userRole;

  const MobileDrawer({super.key, required this.userRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Drawer(
      backgroundColor: AppTheme.white,
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.white,
                    child: Text(
                      authState.user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.user?.fullName ?? 'User',
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authState.user?.email ?? 'user@email.com',
                          style: TextStyle(
                            color: AppTheme.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _buildDrawerItems(context, userRole),
              ),
            ),
            
            // Logout
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: AppTheme.error),
              ),
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context, String userRole) {
    if (userRole == 'candidate') {
      return [
        _buildDrawerItem(context, 'Chat với HR', Icons.chat_outlined, '/chat'),
        _buildDrawerItem(context, 'Cài đặt', Icons.settings_outlined, '/settings'),
        _buildDrawerItem(context, 'Thông báo', Icons.notifications_outlined, '/notifications'),
        _buildDrawerItem(context, 'Hỗ trợ', Icons.help_outline, '/help'),
      ];
    } else if (userRole == 'recruiter') {
      return [
        _buildDrawerItem(context, 'Trang công ty', Icons.business_outlined, '/recruiter/company'),
        _buildDrawerItem(context, 'Cài đặt', Icons.settings_outlined, '/recruiter/settings'),
        _buildDrawerItem(context, 'Thống kê', Icons.analytics_outlined, '/recruiter/analytics'),
        _buildDrawerItem(context, 'Hỗ trợ', Icons.help_outline, '/recruiter/support'),
      ];
    }
    
    return [
      _buildDrawerItem(context, 'Đăng nhập', Icons.login_outlined, '/login'),
      _buildDrawerItem(context, 'Đăng ký', Icons.person_add_outlined, '/register'),
      _buildDrawerItem(context, 'Hỗ trợ', Icons.help_outline, '/support'),
    ];
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, String route) {
    final isActive = GoRouterState.of(context).uri.path == route;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppTheme.primaryBlue : AppTheme.mediumGrey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primaryBlue : AppTheme.darkGrey,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppTheme.lightBlue,
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
