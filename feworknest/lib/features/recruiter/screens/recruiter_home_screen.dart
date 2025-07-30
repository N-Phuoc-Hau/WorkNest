import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';

class RecruiterHomeScreen extends ConsumerStatefulWidget {
  const RecruiterHomeScreen({super.key});

  @override
  ConsumerState<RecruiterHomeScreen> createState() => _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends ConsumerState<RecruiterHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const RecruiterDashboardPage(),
    const RecruiterJobsPage(),
    const RecruiterCandidatesPage(),
    const RecruiterMessagesPage(),
    const RecruiterCompanyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.company?.name ?? 'Công ty của bạn'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Việc làm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Ứng viên',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Công ty',
          ),
        ],
      ),
    );
  }
}

// Dashboard Page
class RecruiterDashboardPage extends StatelessWidget {
  const RecruiterDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào mừng trở lại!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quản lý tuyển dụng hiệu quả với WorkNest',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Tin tuyển dụng',
                  '0',
                  Icons.work_outline,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Ứng viên',
                  '0',
                  Icons.people_outline,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Đang tuyển',
                  '0',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Hoàn thành',
                  '0',
                  Icons.check_circle_outline,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Hành động nhanh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'Đăng tin tuyển dụng',
                  'Tạo tin tuyển dụng mới',
                  Icons.add_box,
                  Colors.blue,
                  () => context.push('/create-job'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  'Quản lý tin',
                  'Xem và chỉnh sửa tin',
                  Icons.edit_document,
                  Colors.green,
                  () => context.push('/manage-jobs'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Jobs Page
class RecruiterJobsPage extends StatelessWidget {
  const RecruiterJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with action button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý việc làm',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/create-job'),
                icon: const Icon(Icons.add),
                label: const Text('Đăng tin'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions for Jobs
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildJobActionCard(
                context,
                'Tất cả tin tuyển dụng',
                'Xem tất cả tin đã đăng',
                Icons.list_alt,
                Colors.blue,
                () => context.push('/manage-jobs'),
              ),
              _buildJobActionCard(
                context,
                'Đăng tin mới',
                'Tạo tin tuyển dụng mới',
                Icons.add_circle,
                Colors.green,
                () => context.push('/create-job'),
              ),
              _buildJobActionCard(
                context,
                'Ứng viên',
                'Xem hồ sơ ứng viên',
                Icons.people,
                Colors.orange,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
              ),
              _buildJobActionCard(
                context,
                'Đánh giá',
                'Xem đánh giá công ty',
                Icons.star,
                Colors.amber,
                () => context.push('/reviews?showMyReviews=true'),
              ),
              _buildJobActionCard(
                context,
                'Đánh giá ứng viên',
                'Viết đánh giá cho ứng viên',
                Icons.rate_review,
                Colors.teal,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chọn ứng viên từ danh sách ứng tuyển')),
                  );
                },
              ),
              _buildJobActionCard(
                context,
                'Thống kê',
                'Xem báo cáo tuyển dụng',
                Icons.analytics,
                Colors.purple,
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

  Widget _buildJobActionCard(
    BuildContext context,
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
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Other placeholder pages
class RecruiterCandidatesPage extends StatelessWidget {
  const RecruiterCandidatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Quản lý ứng viên\n(Đang phát triển)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class RecruiterMessagesPage extends StatelessWidget {
  const RecruiterMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tin nhắn\n(Đang phát triển)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class RecruiterCompanyPage extends StatelessWidget {
  const RecruiterCompanyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Thông tin công ty\n(Đang phát triển)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
