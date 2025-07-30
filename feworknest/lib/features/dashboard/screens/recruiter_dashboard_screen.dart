import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_widget.dart';

class RecruiterDashboardScreen extends ConsumerStatefulWidget {
  const RecruiterDashboardScreen({super.key});

  @override
  ConsumerState<RecruiterDashboardScreen> createState() => _RecruiterDashboardScreenState();
}

class _RecruiterDashboardScreenState extends ConsumerState<RecruiterDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboard('recruiter');
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recruiter Dashboard',
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

            // Top Performing Jobs
            _buildTopPerformingJobs(data),
            const SizedBox(height: 24),

            // Charts Section
            _buildChartsSection(data),
            const SizedBox(height: 24),

            // Recent Applications
            _buildRecentApplications(data),
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
              Icons.business,
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
                  'Chào mừng, ${user?.firstName ?? 'Recruiter'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quản lý việc làm và ứng viên của bạn',
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
          value: '${data['totalJobPosts'] ?? 0}',
          icon: Icons.work,
          color: Colors.blue,
          trend: '+5%',
          trendUp: true,
        ),
        StatCard(
          title: 'Việc làm đang hoạt động',
          value: '${data['activeJobPosts'] ?? 0}',
          icon: Icons.work_outline,
          color: Colors.green,
          trend: '+3%',
          trendUp: true,
        ),
        StatCard(
          title: 'Tổng đơn ứng tuyển',
          value: '${data['totalApplications'] ?? 0}',
          icon: Icons.description,
          color: Colors.orange,
          trend: '+12%',
          trendUp: true,
        ),
        StatCard(
          title: 'Đơn chờ xử lý',
          value: '${data['pendingApplications'] ?? 0}',
          icon: Icons.pending,
          color: Colors.red,
          trend: '-2%',
          trendUp: false,
        ),
        StatCard(
          title: 'Tổng lượt xem',
          value: '${data['totalViews'] ?? 0}',
          icon: Icons.visibility,
          color: Colors.purple,
          trend: '+8%',
          trendUp: true,
        ),
        StatCard(
          title: 'Lượt xem tháng này',
          value: '${data['viewsThisMonth'] ?? 0}',
          icon: Icons.trending_up,
          color: Colors.teal,
          trend: '+15%',
          trendUp: true,
        ),
      ],
    );
  }

  Widget _buildTopPerformingJobs(Map<String, dynamic> data) {
    final topJobs = data['topPerformingJobs'] as List<dynamic>? ?? [];
    
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
            'Việc làm hiệu quả nhất',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (topJobs.isEmpty)
            const Center(
              child: Text(
                'Chưa có dữ liệu',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...topJobs.take(3).map((job) => _buildJobPerformanceCard(job)),
        ],
      ),
    );
  }

  Widget _buildJobPerformanceCard(Map<String, dynamic> job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job['jobTitle'] ?? 'Job Title',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${job['conversionRate']?.toStringAsFixed(1) ?? 0}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMetric('Lượt xem', '${job['views'] ?? 0}', Icons.visibility),
                const SizedBox(width: 16),
                _buildMetric('Ứng tuyển', '${job['applications'] ?? 0}', Icons.description),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
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
        
        // Applications by Status
        if (data['applicationsByStatus'] != null) ...[
          ChartWidget(
            title: 'Đơn ứng tuyển theo trạng thái',
            data: List<Map<String, dynamic>>.from(data['applicationsByStatus']),
            chartType: ChartType.pie,
          ),
          const SizedBox(height: 16),
        ],

        // Views by Day
        if (data['viewsByDay'] != null) ...[
          ChartWidget(
            title: 'Lượt xem theo ngày',
            data: List<Map<String, dynamic>>.from(data['viewsByDay']),
            chartType: ChartType.line,
          ),
        ],
      ],
    );
  }

  Widget _buildRecentApplications(Map<String, dynamic> data) {
    final applications = data['applicationTrends'] as List<dynamic>? ?? [];
    
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
            'Xu hướng ứng tuyển',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (applications.isEmpty)
            const Center(
              child: Text(
                'Chưa có dữ liệu',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...applications.take(5).map((app) => _buildApplicationTrendCard(app)),
        ],
      ),
    );
  }

  Widget _buildApplicationTrendCard(Map<String, dynamic> app) {
    final date = DateTime.tryParse(app['date'] ?? '') ?? DateTime.now();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(Icons.description, color: Colors.blue),
        ),
        title: Text(
          '${app['applications'] ?? 0} đơn ứng tuyển',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${app['views'] ?? 0} lượt xem • ${date.toString().substring(0, 10)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
} 