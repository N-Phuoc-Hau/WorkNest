import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/notification_provider.dart';

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
    _selectedRoute =
        GoRouter.of(context).routeInformationProvider.value.uri.path;

    // Load unread counts khi khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        // Load chat data để có unread count
        ref.read(chatProvider.notifier).loadChatRooms();

        // Load notification unread count nếu có userId
        if (authState.user?.id != null) {
          try {
            ref
                .read(notificationProvider(authState.user!.id).notifier)
                .refreshUnreadCount();
          } catch (e) {
            print('Error loading notification count in sidebar: $e');
          }
        }
      }
    });
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
    return Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatProvider);
        int notificationUnreadCount = 0;

        // Chỉ load notification count nếu user đã đăng nhập và có userId
        if (isAuthenticated && user?.id != null) {
          try {
            final notificationState = ref.watch(notificationProvider(user.id));
            notificationUnreadCount = notificationState.unreadCount;
          } catch (e) {
            print('Error loading notification count: $e');
          }
        }

        final menuItems = _getMenuItems(
          isAuthenticated,
          user,
          chatState.unreadCount,
          notificationUnreadCount,
        );

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: menuItems.map((item) => _buildMenuItem(item)).toList(),
        );
      },
    );
  }

  List<SidebarMenuItem> _getMenuItems(bool isAuthenticated, dynamic user,
      int chatUnreadCount, int notificationUnreadCount) {
    final List<SidebarMenuItem> items = [
      SidebarMenuItem(
        icon: Icons.home,
        title: 'Trang chủ',
        route: isAuthenticated
            ? (user?.isRecruiter == true ? '/recruiter/home' : '/home')
            : '/',
      ),
      SidebarMenuItem(
        icon: Icons.work,
        title: 'Việc làm',
        route: isAuthenticated
            ? (user?.isRecruiter == true ? '/recruiter/jobs' : '/jobs')
            : '/jobs',
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
            route: '/applications',
          ),
          SidebarMenuItem(
            icon: Icons.favorite,
            title: 'Việc làm đã lưu',
            route: '/favorites',
          ),
          SidebarMenuItem(
            icon: Icons.business,
            title: 'Công ty theo dõi',
            route: '/following-companies',
          ),
        ]);
      }

      // Chỉ hiển thị tin nhắn và thông báo với số lượng thật, bỏ search
      items.addAll([
        SidebarMenuItem(
          icon: Icons.chat,
          title: 'Tin nhắn',
          route: isAuthenticated
              ? (user?.isRecruiter == true ? '/recruiter/chat' : '/chat')
              : '/chat',
          badge: chatUnreadCount > 0 ? chatUnreadCount.toString() : null,
        ),
        SidebarMenuItem(
          icon: Icons.notifications,
          title: 'Thông báo',
          route: '/notifications',
          badge: notificationUnreadCount > 0
              ? notificationUnreadCount.toString()
              : null,
        ),
      ]);
    }

    return items;
  }

  Widget _buildMenuItem(SidebarMenuItem item) {
    final isSelected = _selectedRoute == item.route;

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: widget.isCollapsed ? 8 : 12, vertical: 2),
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
            padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 8 : 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3))
                  : null,
            ),
            child: widget.isCollapsed
                ? Center(
                    child: Icon(
                      item.icon,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                      size: 20,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (item.badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
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
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login, color: Colors.blue, size: 20),
                tooltip: 'Đăng nhập',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () => context.go('/register'),
                icon:
                    const Icon(Icons.person_add, color: Colors.green, size: 20),
                tooltip: 'Đăng ký',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Đăng nhập', style: TextStyle(fontSize: 14)),
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Đăng ký', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(widget.isCollapsed ? 8 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: widget.isCollapsed
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: user?.avatar == null
                      ? Theme.of(context).primaryColor
                      : null,
                  backgroundImage:
                      user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                  child: user?.avatar == null
                      ? Text(
                          (user?.firstName?.isNotEmpty == true)
                              ? user!.firstName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  tooltip: 'Menu',
                  onSelected: (value) {
                    if (value == 'profile') {
                      context.go('/profile');
                    } else if (value == 'settings') {
                      final user = ref.read(authProvider).user;
                      if (user?.isRecruiter == true) {
                        context.go('/recruiter/settings');
                      } else {
                        context.go('/settings');
                      }
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
                  radius: 12,
                  backgroundColor: user?.avatar == null
                      ? Theme.of(context).primaryColor
                      : null,
                  backgroundImage:
                      user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                  child: user?.avatar == null
                      ? Text(
                          (user?.firstName?.isNotEmpty == true)
                              ? user!.firstName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'profile') {
                      context.go('/profile');
                    } else if (value == 'settings') {
                      final user = ref.read(authProvider).user;
                      if (user?.isRecruiter == true) {
                        context.go('/recruiter/settings');
                      } else {
                        context.go('/settings');
                      }
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
