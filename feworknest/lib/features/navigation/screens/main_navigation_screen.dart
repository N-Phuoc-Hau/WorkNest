import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/job_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../applications/screens/my_applications_screen.dart';
import '../../favorites/screens/favorite_screen.dart';
import '../../jobs/screens/job_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../widgets/notification_badge.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Auto-load jobs when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobProvider.notifier).getJobPosts();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated;
    
    // Define tabs based on authentication status
    final List<NavigationTab> tabs = isAuthenticated
        ? _getAuthenticatedTabs()
        : _getPublicTabs();
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,  
        children: tabs.map((tab) => tab.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Check if user needs authentication for this tab
          if (!isAuthenticated && tabs[index].requiresAuth) {
            _showLoginDialog(context);
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          
          // Add notification badge for notification tab
          if (tab.label == 'Thông báo') {
            return BottomNavigationBarItem(
              icon: NotificationBadge(
                child: Icon(tab.icon),
              ),
              activeIcon: NotificationBadge(
                child: Icon(tab.activeIcon),
              ),
              label: tab.label,
            );
          }
          
          return BottomNavigationBarItem(
            icon: Icon(tab.icon),
            activeIcon: Icon(tab.activeIcon),
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
  
  List<NavigationTab> _getPublicTabs() {
    return [
      NavigationTab(
        icon: Icons.work_outline,
        activeIcon: Icons.work,
        label: 'Việc làm',
        screen: const JobListScreen(),
        requiresAuth: false,
      ),
      NavigationTab(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Yêu thích',
        screen: const _LoginRequiredScreen(message: 'Đăng nhập để xem danh sách yêu thích'),
        requiresAuth: true,
      ),
      NavigationTab(
        icon: Icons.description_outlined,
        activeIcon: Icons.description,
        label: 'Hồ sơ',
        screen: const _LoginRequiredScreen(message: 'Đăng nhập để xem đơn ứng tuyển'),
        requiresAuth: true,
      ),
      NavigationTab(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Tài khoản',
        screen: const _LoginRequiredScreen(message: 'Đăng nhập để xem thông tin cá nhân'),
        requiresAuth: true,
      ),
    ];
  }
  
  List<NavigationTab> _getAuthenticatedTabs() {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    if (user != null && user.isRecruiter) {
      return _getRecruiterTabs();
    } else {
      return _getCandidateTabs();
    }
  }
  
  List<NavigationTab> _getCandidateTabs() {
    return [
      NavigationTab(
        icon: Icons.work_outline,
        activeIcon: Icons.work,
        label: 'Việc làm',
        screen: const JobListScreen(),
        requiresAuth: false,
      ),
      NavigationTab(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Chat',
        screen: const ChatListScreen(),
        requiresAuth: true,
      ),
      NavigationTab(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Yêu thích',
        screen: const FavoriteScreen(),
        requiresAuth: true,
      ),
      NavigationTab(
        icon: Icons.description_outlined,
        activeIcon: Icons.description,
        label: 'Hồ sơ UV',
        screen: const MyApplicationsScreen(),
        requiresAuth: true,
      ),
      NavigationTab(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Tài khoản',
        screen: const ProfileScreen(),
        requiresAuth: true,
      ),
    ];
  }
  
  List<NavigationTab> _getRecruiterTabs() {
    return [
      NavigationTab(
        icon: Icons.business_center_outlined,
        activeIcon: Icons.business_center,
        label: 'Tuyển dụng',
        screen: const JobListScreen(), // Could be different for recruiters
        requiresAuth: false,
      ),
      NavigationTab(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Chat',
        screen: const ChatListScreen(),
        requiresAuth: true,
      ),
      NavigationTab(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications,
        label: 'Thông báo',
        screen: const NotificationScreen(),
        requiresAuth: true,
      ),
      NavigationTab(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Ứng viên',
        screen: const MyApplicationsScreen(), // Different screen for recruiters
        requiresAuth: true,
      ),
      NavigationTab(
        icon: Icons.add_circle_outline,
        activeIcon: Icons.add_circle,
        label: 'Đăng tin',
        screen: const _CreateJobScreen(),
        requiresAuth: true,
      ),
      NavigationTab(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Công ty',
        screen: const ProfileScreen(),
        requiresAuth: true,
      ),
    ];
  }
  
  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yêu cầu đăng nhập'),
          content: const Text('Bạn cần đăng nhập để sử dụng chức năng này.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/login');
              },
              child: const Text('Đăng nhập'),
            ),
          ],
        );
      },
    );
  }
}

class NavigationTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
  final bool requiresAuth;
  
  NavigationTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
    this.requiresAuth = false,
  });
}

class _LoginRequiredScreen extends StatelessWidget {
  final String message;
  
  const _LoginRequiredScreen({required this.message});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkNest'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Đăng nhập'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Đăng ký'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateJobScreen extends StatelessWidget {
  const _CreateJobScreen();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tin tuyển dụng'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Tạo tin tuyển dụng mới',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/create-job'),
              icon: const Icon(Icons.add),
              label: const Text('Đăng tin mới'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.push('/manage-jobs'),
              icon: const Icon(Icons.list),
              label: const Text('Quản lý tin đã đăng'),
            ),
          ],
        ),
      ),
    );
  }
}
