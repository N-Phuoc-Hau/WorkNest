// web_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../widgets/web_sidebar.dart';

class WebLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;

  const WebLayout({
    super.key,
    required this.child,
    this.title,
    this.actions,
  });

  @override
  ConsumerState<WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends ConsumerState<WebLayout> {
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    // Mobile layout - use drawer
    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: WebSidebar(
            isCollapsed: false,
            onToggle: () {},
          ),
        ),
        body: Column(
          children: [
            _buildHeaderBar(showMenuButton: true),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Desktop/Tablet layout - use persistent sidebar
    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: _isSidebarCollapsed ? 72 : 280,
            child: WebSidebar(
              isCollapsed: _isSidebarCollapsed,
              onToggle: _toggleSidebar,
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildHeaderBar(showMenuButton: false),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar({required bool showMenuButton}) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF374151) : Colors.grey[200]!,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Menu button for mobile or sidebar toggle for desktop
            if (showMenuButton)
              IconButton(
                onPressed: _openDrawer,
                icon: const Icon(Icons.menu),
                tooltip: 'Mở menu',
              )
            else
              IconButton(
                onPressed: _toggleSidebar,
                icon: Icon(_isSidebarCollapsed ? Icons.menu : Icons.menu_open),
                tooltip: _isSidebarCollapsed ? 'Mở sidebar' : 'Thu gọn sidebar',
              ),
            
            const SizedBox(width: 16),
            
            // Logo/Title
            Expanded(
              child: Text(
                widget.title ?? '', // Sử dụng widget.title
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(width: 16),

            // Right side actions
            if (widget.actions != null) Row(
              children: widget.actions!, // Sử dụng widget.actions
            ),

            if (isAuthenticated) ...[
              // User menu with real avatar
              PopupMenuButton<String>(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: user?.avatar == null ? Theme.of(context).primaryColor : null,
                        backgroundImage: user?.avatar != null
                            ? NetworkImage(user!.avatar!)
                            : null,
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
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          user?.firstName ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      if (user?.isRecruiter == true) {
                        context.go('/recruiter/profile');
                      } else {
                        context.go('/profile');
                      }
                      break;
                    case 'settings':
                      if (user?.isRecruiter == true) {
                        context.go('/recruiter/settings');
                      } else {
                        context.go('/settings');
                      }
                      break;
                    case 'logout':
                      ref.read(authProvider.notifier).logout();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline),
                        SizedBox(width: 12),
                        Text('Hồ sơ của tôi'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined),
                        SizedBox(width: 12),
                        Text('Cài đặt'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Login and register buttons for non-authenticated users
              OutlinedButton(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                child: const Text('Đăng nhập'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => context.go('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                child: const Text('Đăng ký'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}