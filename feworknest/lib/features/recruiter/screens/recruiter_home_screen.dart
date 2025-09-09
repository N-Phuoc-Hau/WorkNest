import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/analytics_models.dart';
import '../../../core/providers/analytics_provider.dart';
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
    );
  }
}

// Dashboard Page
class RecruiterDashboardPage extends ConsumerStatefulWidget {
  const RecruiterDashboardPage({super.key});

  @override
  ConsumerState<RecruiterDashboardPage> createState() => _RecruiterDashboardPageState();
}

class _RecruiterDashboardPageState extends ConsumerState<RecruiterDashboardPage> {
  @override
  void initState() {
    super.initState();
    print('🔥 RecruiterDashboard: initState called');
    // Load analytics data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔥 RecruiterDashboard: addPostFrameCallback executed');
      ref.read(analyticsProvider.notifier).loadSummaryAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    print('🔥 RecruiterDashboard: build called - isLoading: ${analyticsState.isLoading}, error: ${analyticsState.error}, hasData: ${analyticsState.analytics != null}');
    
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
                    'Chào mừng ${user?.firstName ?? 'bạn'} trở lại!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.company?.name != null
                        ? 'Quản lý tuyển dụng cho ${user!.company!.name}'
                        : 'Quản lý tuyển dụng hiệu quả với WorkNest',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (analyticsState.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (analyticsState.error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        analyticsState.error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(analyticsProvider.notifier).loadSummaryAnalytics(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Quick Stats
            _buildStatsSection(context, analyticsState.summary),
            
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActionsSection(context),
            
            const SizedBox(height: 24),

            // Company Info Section
            if (analyticsState.summary?.companyInfo != null)
              _buildCompanyInfoSection(context, analyticsState.summary!.companyInfo),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, SummaryAnalytics? summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Tin tuyển dụng',
                summary?.jobStats.totalJobsPosted.toString() ?? '0',
                Icons.work_outline,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Ứng viên',
                summary?.applicationStats.totalApplicationsReceived.toString() ?? '0',
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
                summary?.jobStats.activeJobs.toString() ?? '0',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => context.push('/recruiter/analytics'),
                child: _buildStatCard(
                  context,
                  'Phân tích',
                  'Chi tiết',
                  Icons.analytics,
                  Colors.purple,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  Widget _buildCompanyInfoSection(BuildContext context, CompanySummary company) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin công ty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Người theo dõi',
                    company.totalFollowers.toString(),
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Đánh giá',
                    '${company.averageRating.toStringAsFixed(1)}/5',
                    Icons.star,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Số đánh giá',
                    company.totalReviews.toString(),
                    Icons.rate_review,
                  ),
                ),
              ],
            ),
            if (!company.isVerified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Công ty chưa được xác minh. Hoàn thiện hồ sơ để tăng độ tin cậy.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
                'Phân tích & Báo cáo',
                'Xem thống kê chi tiết',
                Icons.analytics,
                Colors.purple,
                () => context.push('/analytics'),
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
