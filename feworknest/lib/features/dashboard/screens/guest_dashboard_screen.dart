import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/job_provider.dart' as job_provider;
import '../widgets/stat_card.dart';

class GuestDashboardScreen extends ConsumerStatefulWidget {
  const GuestDashboardScreen({super.key});

  @override
  ConsumerState<GuestDashboardScreen> createState() => _GuestDashboardScreenState();
}

class _GuestDashboardScreenState extends ConsumerState<GuestDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load recent jobs for guest users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(job_provider.jobProvider.notifier).getJobPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(job_provider.jobProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WorkNest - Tìm việc dễ dàng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(job_provider.jobProvider.notifier).getJobPosts();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(job_provider.jobProvider.notifier).getJobPosts();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatsCards(jobState),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Recent Jobs
              _buildRecentJobs(jobState),
              const SizedBox(height: 24),

              // Call to Action
              _buildCallToAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              Icons.work,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chào mừng đến với WorkNest!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Khám phá hàng ngàn cơ hội việc làm',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Đăng nhập'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => context.push('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Đăng ký'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(job_provider.JobsState jobState) {
    final totalJobs = jobState.jobs.length;
    final recentJobs = jobState.jobs.where((job) {
      final daysDiff = DateTime.now().difference(job.createdAt).inDays;
      return daysDiff <= 7;
    }).length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        StatCard(
          title: 'Tổng việc làm',
          value: '$totalJobs',
          icon: Icons.work,
          color: Colors.blue,
          trend: null,
        ),
        StatCard(
          title: 'Việc mới (7 ngày)',
          value: '$recentJobs',
          icon: Icons.new_releases,
          color: Colors.green,
          trend: null,
        ),
        StatCard(
          title: 'Công ty',
          value: '${_getUniqueCompanies(jobState.jobs)}',
          icon: Icons.business,
          color: Colors.orange,
          trend: null,
        ),
        StatCard(
          title: 'Địa điểm',
          value: '${_getUniqueLocations(jobState.jobs)}',
          icon: Icons.location_on,
          color: Colors.purple,
          trend: null,
        ),
      ],
    );
  }

  int _getUniqueCompanies(List<JobModel> jobs) {
    return jobs.map((job) => job.recruiter.company?.name ?? job.recruiter.fullName).toSet().length;
  }

  int _getUniqueLocations(List<JobModel> jobs) {
    return jobs.map((job) => job.location).toSet().length;
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hành động nhanh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildQuickActionCard(
                'Tìm việc làm',
                Icons.search,
                Colors.blue,
                () => context.go('/jobs'),
              ),
              _buildQuickActionCard(
                'Tạo tài khoản',
                Icons.person_add,
                Colors.green,
                () => context.push('/register'),
              ),
              _buildQuickActionCard(
                'Đăng nhập',
                Icons.login,
                Colors.orange,
                () => context.push('/login'),
              ),
              _buildQuickActionCard(
                'Hướng dẫn',
                Icons.help,
                Colors.purple,
                () {
                  // Navigate to guide
                  _showGuideDialog();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJobs(job_provider.JobsState jobState) {
    final recentJobs = jobState.jobs.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Việc làm mới nhất',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/jobs'),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentJobs.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Đang tải việc làm...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...recentJobs.map((job) => _buildJobCard(job)),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.work,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.recruiter.company?.name ?? job.recruiter.fullName,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                Text(
                  '${job.createdAt.day}/${job.createdAt.month}/${job.createdAt.year}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.push('/jobs/${job.id}');
        },
      ),
    );
  }

  Widget _buildCallToAction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Sẵn sàng bắt đầu sự nghiệp?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tạo tài khoản để ứng tuyển việc làm, lưu công việc yêu thích và nhận thông báo về cơ hội mới.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.push('/register'),
                child: const Text('Đăng ký ngay'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hướng dẫn sử dụng'),
          content: const SingleChildScrollView(
            child: Text(
              '• Xem danh sách việc làm mà không cần đăng nhập\n'
              '• Tạo tài khoản để ứng tuyển việc làm\n'
              '• Lưu công việc yêu thích\n'
              '• Nhận thông báo về cơ hội mới\n'
              '• Chat trực tiếp với nhà tuyển dụng\n'
              '• Quản lý hồ sơ ứng tuyển',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/register');
              },
              child: const Text('Đăng ký ngay'),
            ),
          ],
        );
      },
    );
  }
}
