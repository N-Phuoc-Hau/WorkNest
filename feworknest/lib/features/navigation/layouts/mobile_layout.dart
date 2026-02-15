import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/unified_notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

class MobileLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String? title;

  const MobileLayout({
    super.key,
    required this.child,
    this.title,
  });

  @override
  ConsumerState<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<MobileLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.neutral100,
      appBar: _buildAppBar(context, userRole),
      drawer: userRole != null ? _buildMobileDrawer() : null,
      body: widget.child,
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, String? userRole) {
    if (widget.title == null && userRole == null) return null;
    
    return AppBar(
      title: Text(
        widget.title ?? 'WorkNest',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.neutral900,
      elevation: 1,
      shadowColor: AppColors.neutral900.withOpacity(0.1),
      leading: userRole != null 
          ? IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _scaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              tooltip: 'Mở menu',
              splashRadius: 24,
            )
          : null,
      actions: [
        if (userRole != null) ...[
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              int unreadCount = 0;
              
              // Get notification unread count
              if (authState.user?.id != null) {
                try {
                  unreadCount = ref.watch(unreadCountProvider);
                } catch (e) {
                  // Handle error silently
                }
              }
              
              return IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/notifications');
                },
                icon: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_outlined, 
                      color: AppColors.primary,
                      size: 26,
                    ),
                    // Badge for unread notifications
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Thông báo',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: AppColors.white,
      width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
      child: SafeArea(
        child: Column(
          children: [
            // Custom mobile header with user info
            _buildMobileDrawerHeader(),
            
            // Navigation menu using WebSidebar logic but mobile-optimized
            Expanded(
              child: WebSidebar(
                isCollapsed: false,
                onToggle: () {
                  // Add haptic feedback and close drawer when navigation happens
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                },
              ),
            ),
            
            // Mobile-specific footer
            _buildMobileDrawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawerHeader() {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.white.withOpacity(0.2),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.white,
              backgroundImage: user?.avatar != null
                  ? NetworkImage(user!.avatar!)
                  : null,
              child: user?.avatar == null
                  ? Text(
                      (user?.fullName != null && user!.fullName.isNotEmpty)
                          ? user.fullName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // User name
          Text(
            user?.fullName ?? 'User',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // User email
          Text(
            user?.email ?? 'user@email.com',
            style: TextStyle(
              color: AppColors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // User role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user?.isRecruiter == true 
                  ? 'Nhà tuyển dụng' 
                  : user?.role == 'admin' 
                      ? 'Quản trị viên'
                      : 'Ứng viên',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.neutral500,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'WorkNest v1.0.0',
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
