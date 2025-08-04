import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';

class WebSidebar extends ConsumerStatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const WebSidebar({
    super.key,
    this.isCollapsed = false,
    required this.onToggle,
  });

  @override
  ConsumerState<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends ConsumerState<WebSidebar> {
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _selectedRoute = GoRouter.of(context).routeInformationProvider.value.uri.path;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildSidebarHeader(),
          
          // Navigation Menu
          Expanded(
            child: _buildNavigationMenu(isAuthenticated, user),
          ),
          
          // Footer
          _buildSidebarFooter(isAuthenticated, user),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue,
            Colors.blue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: widget.isCollapsed 
        ? Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.work,
                color: Colors.white,
                size: 24,
              ),
            ),
          )
        : Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'WorkNest',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildNavigationMenu(bool isAuthenticated, dynamic user) {
    final menuItems = _getMenuItems(isAuthenticated, user);
    
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: menuItems.map((item) => _buildMenuItem(item)).toList(),
    );
  }

  List<SidebarMenuItem> _getMenuItems(bool isAuthenticated, dynamic user) {
    final List<SidebarMenuItem> items = [
      SidebarMenuItem(
        icon: Icons.dashboard,
        title: 'Trang chủ',
        route: isAuthenticated 
            ? (user?.isRecruiter == true ? '/recruiter/home' : '/candidate/home')
            : '/',
      ),
      SidebarMenuItem(
        icon: Icons.work,
        title: 'Việc làm',
        route: isAuthenticated 
            ? (user?.isRecruiter == true ? '/recruiter/jobs' : '/candidate/jobs')
            : '/candidate/jobs',
      ),
    ];

    if (isAuthenticated) {
      if (user?.role == 'admin') {
        items.addAll([
          SidebarMenuItem(
            icon: Icons.people,
            title: 'Quản lý người dùng',
            route: '/admin/users',
          ),
          SidebarMenuItem(
            icon: Icons.work,
            title: 'Quản lý tin tuyển dụng',
            route: '/admin/jobs',
          ),
          SidebarMenuItem(
            icon: Icons.business,
            title: 'Duyệt công ty',
            route: '/admin/companies',
          ),
        ]);
      } else if (user?.isRecruiter == true) {
        items.addAll([
          SidebarMenuItem(
            icon: Icons.add_business,
            title: 'Đăng tin tuyển dụng',
            route: '/recruiter/post-job',
          ),
          SidebarMenuItem(
            icon: Icons.manage_accounts,
            title: 'Quản lý tin đăng',
            route: '/recruiter/jobs',
          ),
          SidebarMenuItem(
            icon: Icons.people,
            title: 'Ứng viên',
            route: '/recruiter/applicants',
          ),
          SidebarMenuItem(
            icon: Icons.business,
            title: 'Công ty',
            route: '/recruiter/company',
          ),
        ]);
      } else {
        items.addAll([
          SidebarMenuItem(
            icon: Icons.description,
            title: 'Đơn ứng tuyển',
            route: '/candidate/applications',
          ),
          SidebarMenuItem(
            icon: Icons.favorite,
            title: 'Việc làm đã lưu',
            route: '/candidate/favorites',
          ),
        ]);
      }

      items.addAll([
        SidebarMenuItem(
          icon: Icons.chat,
          title: 'Tin nhắn',
          route: isAuthenticated 
              ? (user?.isRecruiter == true ? '/recruiter/chat' : '/candidate/chat')
              : '/candidate/chat',
          badge: '3',
        ),
        SidebarMenuItem(
          icon: Icons.notifications,
          title: 'Thông báo',
          route: '/notifications',
          badge: '5',
        ),
        SidebarMenuItem(
          icon: Icons.search,
          title: 'Tìm kiếm nâng cao',
          route: '/search',
        ),
      ]);
    } else {
      items.addAll([
        SidebarMenuItem(
          icon: Icons.search,
          title: 'Tìm kiếm việc làm',
          route: '/search',
        ),
        SidebarMenuItem(
          icon: Icons.info,
          title: 'Về chúng tôi',
          route: '/about',
        ),
      ]);
    }

    return items;
  }

  Widget _buildMenuItem(SidebarMenuItem item) {
    final isSelected = _selectedRoute == item.route;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedRoute = item.route;
            });
            context.go(item.route);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                  ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected 
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                  size: 20,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: isSelected 
                            ? Theme.of(context).primaryColor
                            : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (item.badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(bool isAuthenticated, dynamic user) {
    if (!isAuthenticated) {
      if (widget.isCollapsed) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              IconButton(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login, color: Colors.blue),
                tooltip: 'Đăng nhập',
              ),
              IconButton(
                onPressed: () => context.go('/register'),
                icon: const Icon(Icons.person_add, color: Colors.green),
                tooltip: 'Đăng ký',
              ),
            ],
          ),
        );
      }
      
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Đăng nhập'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/register'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Đăng ký'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: widget.isCollapsed
          ? Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  onSelected: (value) {
                    if (value == 'profile') {
                      context.go('/profile');
                    } else if (value == 'settings') {
                      context.go('/settings');
                    } else if (value == 'logout') {
                      ref.read(authProvider.notifier).logout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Text('Hồ sơ'),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('Cài đặt'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Đăng xuất'),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'profile') {
                      context.go('/profile');
                    } else if (value == 'settings') {
                      context.go('/settings');
                    } else if (value == 'logout') {
                      ref.read(authProvider.notifier).logout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Text('Hồ sơ'),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('Cài đặt'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Đăng xuất'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class SidebarMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final String? badge;

  SidebarMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.badge,
  });
}
