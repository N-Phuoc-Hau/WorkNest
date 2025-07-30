import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_widget.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboard('admin');
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
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
              ref.read(dashboardProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboardState.error != null
              ? _buildErrorWidget(dashboardState.error!)
              : _buildDashboardContent(dashboardState.dashboardData),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(dashboardProvider.notifier).refresh();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dashboardProvider.notifier).refresh();
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
            _buildStatsCards(data),
            const SizedBox(height: 24),

            // Charts Section
            _buildChartsSection(data),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final user = ref.watch(authProvider).user;
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
              Icons.admin_panel_settings,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng, ${user?.firstName ?? 'Admin'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quản lý toàn bộ hệ thống WorkNest',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> data) {
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
          value: '${data['totalJobs'] ?? 0}',
          icon: Icons.work,
          color: Colors.blue,
          trend: '+12%',
          trendUp: true,
        ),
        StatCard(
          title: 'Việc làm đang hoạt động',
          value: '${data['activeJobs'] ?? 0}',
          icon: Icons.work_outline,
          color: Colors.green,
          trend: '+8%',
          trendUp: true,
        ),
        StatCard(
          title: 'Tổng đơn ứng tuyển',
          value: '${data['totalApplications'] ?? 0}',
          icon: Icons.description,
          color: Colors.orange,
          trend: '+15%',
          trendUp: true,
        ),
        StatCard(
          title: 'Đơn chờ xử lý',
          value: '${data['pendingApplications'] ?? 0}',
          icon: Icons.pending,
          color: Colors.red,
          trend: '-5%',
          trendUp: false,
        ),
        StatCard(
          title: 'Tổng người dùng',
          value: '${data['totalUsers'] ?? 0}',
          icon: Icons.people,
          color: Colors.purple,
          trend: '+20%',
          trendUp: true,
        ),
        StatCard(
          title: 'Người dùng mới tháng này',
          value: '${data['newUsersThisMonth'] ?? 0}',
          icon: Icons.person_add,
          color: Colors.teal,
          trend: '+25%',
          trendUp: true,
        ),
      ],
    );
  }

  Widget _buildChartsSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê chi tiết',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Job Views Chart
        if (data['jobViewsByDay'] != null) ...[
          ChartWidget(
            title: 'Lượt xem việc làm (7 ngày qua)',
            data: List<Map<String, dynamic>>.from(data['jobViewsByDay']),
            chartType: ChartType.line,
          ),
          const SizedBox(height: 16),
        ],

        // Applications Chart
        if (data['applicationsByDay'] != null) ...[
          ChartWidget(
            title: 'Đơn ứng tuyển (7 ngày qua)',
            data: List<Map<String, dynamic>>.from(data['applicationsByDay']),
            chartType: ChartType.bar,
          ),
          const SizedBox(height: 16),
        ],

        // Top Categories
        if (data['topJobCategories'] != null) ...[
          ChartWidget(
            title: 'Top danh mục việc làm',
            data: List<Map<String, dynamic>>.from(data['topJobCategories']),
            chartType: ChartType.pie,
          ),
          const SizedBox(height: 16),
        ],

        // Top Locations
        if (data['topLocations'] != null) ...[
          ChartWidget(
            title: 'Top địa điểm',
            data: List<Map<String, dynamic>>.from(data['topLocations']),
            chartType: ChartType.doughnut,
          ),
        ],
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hoạt động gần đây',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.work,
            title: 'Việc làm mới được đăng',
            subtitle: 'Senior Flutter Developer tại Tech Company',
            time: '2 giờ trước',
            color: Colors.blue,
          ),
          const Divider(),
          _buildActivityItem(
            icon: Icons.person_add,
            title: 'Người dùng mới đăng ký',
            subtitle: 'Nguyễn Văn A - Candidate',
            time: '3 giờ trước',
            color: Colors.green,
          ),
          const Divider(),
          _buildActivityItem(
            icon: Icons.description,
            title: 'Đơn ứng tuyển mới',
            subtitle: 'Frontend Developer - Ứng viên: Trần Thị B',
            time: '4 giờ trước',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 