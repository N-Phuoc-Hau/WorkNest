import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/unified_notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/worknest_logo.dart';

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
                .read(unifiedNotificationProvider.notifier)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral900 : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildSidebarHeader(isDark),

          // Navigation Menu
          Expanded(
            child: _buildNavigationMenu(isAuthenticated, user, isDark),
          ),

          // Footer
          _buildSidebarFooter(isAuthenticated, user, isDark),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: widget.isCollapsed
          ? Center(
              child: Container(
                padding: EdgeInsets.all(AppSpacing.spacing8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const WorkNestLogo(
                  size: 28,
                  showName: false,

                ),
              ),
            )
          : Row(
               children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacing8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const WorkNestLogo(
                    size: 28,
                    showName: false,
                  ),
                ),
                SizedBox(width: AppSpacing.spacing12),
                const Flexible(
                  child: Text(
                    'WorkNest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNavigationMenu(bool isAuthenticated, dynamic user, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatProvider);
        int notificationUnreadCount = 0;

        // Chỉ load notification count nếu user đã đăng nhập và có userId
        if (isAuthenticated && user?.id != null) {
          try {
            notificationUnreadCount = ref.watch(unreadCountProvider);
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
          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
          children: [
            // Settings section header (only in expanded mode)
            if (!widget.isCollapsed && menuItems.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing16,
                  vertical: AppSpacing.spacing8,
                ),
                child: Text(
                  'MENU',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.neutral500 : AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ...menuItems.map((item) => _buildMenuItem(item, isDark)).toList(),
          ],
        );
      },
    );
  }

  List<SidebarMenuItem> _getMenuItems(bool isAuthenticated, dynamic user,
      int chatUnreadCount, int notificationUnreadCount) {
    final List<SidebarMenuItem> items = [
      SidebarMenuItem(
        icon: Icons.home_rounded,
        title: 'Trang chủ',
        route: isAuthenticated
            ? (user?.isRecruiter == true ? '/recruiter/home' : '/home')
            : '/',
      ),
      SidebarMenuItem(
        icon: Icons.work_rounded,
        title: 'Việc làm',
        route: isAuthenticated
            ? (user?.isRecruiter == true ? '/jobs' : '/jobs')
            : '/jobs',
      ),
    ];

    if (isAuthenticated) {
      if (user?.role == 'admin') {
        items.addAll([
          SidebarMenuItem(
            icon: Icons.people_rounded,
            title: 'Quản lý người dùng',
            route: '/admin/users',
          ),
          SidebarMenuItem(
            icon: Icons.work_history_rounded,
            title: 'Quản lý tin tuyển dụng',
            route: '/admin/jobs',
          ),
          SidebarMenuItem(
            icon: Icons.business_rounded,
            title: 'Duyệt công ty',
            route: '/admin/companies',
          ),
        ]);
      } else if (user?.isRecruiter == true) {
        items.addAll([
          SidebarMenuItem(
            icon: Icons.add_business_rounded,
            title: 'Đăng tin tuyển dụng',
            route: '/recruiter/post-job',
          ),
          SidebarMenuItem(
            icon: Icons.manage_accounts_rounded,
            title: 'Quản lý tin đăng',
            route: '/recruiter/jobs',
          ),
          SidebarMenuItem(
            icon: Icons.people_alt_rounded,
            title: 'Ứng viên',
            route: '/recruiter/applicants',
          ),
          SidebarMenuItem(
            icon: Icons.apartment_rounded,
            title: 'Công ty',
            route: '/recruiter/company',
          ),
        ]);
      } else {
        items.addAll([
          SidebarMenuItem(
            icon: Icons.description_rounded,
            title: 'Đơn ứng tuyển',
            route: '/applications',
          ),
          SidebarMenuItem(
            icon: Icons.analytics_rounded,
            title: 'Phân tích CV',
            route: '/cv-analysis',
          ),
          SidebarMenuItem(
            icon: Icons.favorite_rounded,
            title: 'Việc làm đã lưu',
            route: '/favorites',
          ),
          SidebarMenuItem(
            icon: Icons.business_center_rounded,
            title: 'Công ty theo dõi',
            route: '/following-companies',
          ),
        ]);
      }

      // Chỉ hiển thị tin nhắn và thông báo với số lượng thật, bỏ search
      items.addAll([
        SidebarMenuItem(
          icon: Icons.chat_bubble_rounded,
          title: 'Tin nhắn',
          route: isAuthenticated
              ? (user?.isRecruiter == true ? '/recruiter/chat' : '/chat')
              : '/chat',
          badge: chatUnreadCount > 0 ? chatUnreadCount.toString() : null,
        ),
        SidebarMenuItem(
          icon: Icons.notifications_rounded,
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

  Widget _buildMenuItem(SidebarMenuItem item, bool isDark) {
    final isSelected = _selectedRoute == item.route;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? AppSpacing.spacing8 : AppSpacing.spacing12,
        vertical: AppSpacing.spacing2,
      ),
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
              horizontal: widget.isCollapsed ? AppSpacing.spacing8 : AppSpacing.spacing16,
              vertical: AppSpacing.spacing12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.primary.withOpacity(0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: widget.isCollapsed
                ? Center(
                    child: Icon(
                      item.icon,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.neutral400 : AppColors.neutral600),
                      size: 22,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.neutral400 : AppColors.neutral600),
                        size: 22,
                      ),
                      SizedBox(width: AppSpacing.spacing12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.neutral300 : AppColors.neutral700),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (item.badge != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacing8,
                            vertical: AppSpacing.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.badge!,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
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

  Widget _buildSidebarFooter(bool isAuthenticated, dynamic user, bool isDark) {
    if (!isAuthenticated) {
      if (widget.isCollapsed) {
        return Padding(
          padding: EdgeInsets.all(AppSpacing.spacing8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => context.go('/login'),
                icon: Icon(
                  Icons.login_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                tooltip: 'Đăng nhập',
              ),
              SizedBox(height: AppSpacing.spacing4),
              IconButton(
                onPressed: () => context.go('/register'),
                icon: Icon(
                  Icons.person_add_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
                tooltip: 'Đăng ký',
              ),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.05),
              Colors.transparent,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.login_rounded, size: 20),
              label: Text(
                'Đăng nhập',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.spacing12),
            OutlinedButton.icon(
              onPressed: () => context.go('/register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: Text(
                'Đăng ký',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Authenticated user footer
    return Container(
      padding: EdgeInsets.all(widget.isCollapsed ? AppSpacing.spacing8 : AppSpacing.spacing16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
          ),
        ),
      ),
      child: widget.isCollapsed
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: user?.avatar == null
                      ? AppColors.primary
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                SizedBox(height: AppSpacing.spacing8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                  ),
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
                      context.go('/');
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, size: 20, color: AppColors.neutral600),
                          SizedBox(width: AppSpacing.spacing12),
                          const Text('Hồ sơ'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_rounded, size: 20, color: AppColors.neutral600),
                          SizedBox(width: AppSpacing.spacing12),
                          const Text('Cài đặt'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                          SizedBox(width: AppSpacing.spacing12),
                          Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: user?.avatar == null
                      ? AppColors.primary
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.neutral200 : AppColors.neutral900,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: AppSpacing.spacing4),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.neutral500 : AppColors.neutral600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.spacing8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                  ),
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
                      context.go('/');
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, size: 20, color: AppColors.neutral600),
                          SizedBox(width: AppSpacing.spacing12),
                          const Text('Hồ sơ'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_rounded, size: 20, color: AppColors.neutral600),
                          SizedBox(width: AppSpacing.spacing12),
                          const Text('Cài đặt'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                          SizedBox(width: AppSpacing.spacing12),
                          Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
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
