import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';

class CandidateHomeScreen extends ConsumerStatefulWidget {
  const CandidateHomeScreen({super.key});

  @override
  ConsumerState<CandidateHomeScreen> createState() => _CandidateHomeScreenState();
}

class _CandidateHomeScreenState extends ConsumerState<CandidateHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Xin chào, ${user?.firstName ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _onItemTapped(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Tìm kiếm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildFavoriteTab();
      case 3:
        return _buildNotificationTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào mừng bạn đến với WorkNest',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tìm kiếm công việc mơ ước của bạn',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Quick actions
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildQuickActionCard(
                icon: Icons.search,
                title: 'Tìm việc làm',
                subtitle: 'Khám phá cơ hội mới',
                onTap: () => context.go('/jobs'),
              ),
              _buildQuickActionCard(
                icon: Icons.work,
                title: 'Đơn ứng tuyển',
                subtitle: 'Theo dõi trạng thái',
                onTap: () => context.go('/candidate/applications'),
              ),
              _buildQuickActionCard(
                icon: Icons.favorite,
                title: 'Việc yêu thích',
                subtitle: 'Danh sách đã lưu',
                onTap: () => context.go('/candidate/favorites'),
              ),
              _buildQuickActionCard(
                icon: Icons.person,
                title: 'Hồ sơ của tôi',
                subtitle: 'Cập nhật thông tin',
                onTap: () {
                  setState(() {
                    _selectedIndex = 4;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    // Navigate to job list when search tab is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/jobs');
    });
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildFavoriteTab() {
    // Navigate to favorites when favorite tab is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/candidate/favorites');
    });
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildNotificationTab() {
    return const Center(
      child: Text('Notification Tab - Coming Soon'),
    );
  }

  Widget _buildProfileTab() {
    final user = ref.watch(authProvider).user;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: user?.avatar != null
                        ? NetworkImage(user!.avatar!)
                        : null,
                    child: user?.avatar == null
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.blue[700],
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Unknown User',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Profile Actions
          Text(
            'Hoạt động của tôi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Action Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildActionCard(
                'Đánh giá của tôi',
                'Xem các đánh giá đã viết',
                Icons.rate_review,
                Colors.orange,
                () => context.push('/reviews?showMyReviews=true'),
              ),
              _buildActionCard(
                'Ứng tuyển',
                'Quản lý đơn ứng tuyển',
                Icons.work,
                Colors.blue,
                () => context.push('/candidate/applications'),
              ),
              _buildActionCard(
                'Yêu thích',
                'Công việc đã lưu',
                Icons.favorite,
                Colors.red,
                () => context.push('/candidate/favorites'),
              ),
              _buildActionCard(
                'Cài đặt',
                'Tùy chỉnh tài khoản',
                Icons.settings,
                Colors.grey,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    // Handle any additional logic when tab is tapped
  }
}
