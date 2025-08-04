import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../navigation/layouts/web_layout.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_widget.dart';

class CandidateDashboardScreen extends ConsumerStatefulWidget {
  const CandidateDashboardScreen({super.key});

  @override
  ConsumerState<CandidateDashboardScreen> createState() => _CandidateDashboardScreenState();
}

class _CandidateDashboardScreenState extends ConsumerState<CandidateDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboard('candidate');
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    // Use WebLayout for responsive design
    return WebLayout(
      title: 'Dashboard Ứng viên',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(dashboardProvider.notifier).refresh();
          },
        ),
      ],
      child: dashboardState.isLoading
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
        padding: ResponsiveUtils.getContentPadding(context),
        child: ResponsiveUtils.isWeb(context) 
            ? _buildWebDashboard(data)
            : _buildMobileDashboard(data),
      ),
    );
  }

  Widget _buildWebDashboard(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section - Full width
        _buildWelcomeSection(),
        const SizedBox(height: 32),

        // Main Content Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column - Stats and Charts
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards Grid
                  _buildStatsCards(data),
                  const SizedBox(height: 32),
                  
                  // Charts Section
                  _buildChartsSection(data),
                ],
              ),
            ),
            
            const SizedBox(width: 32),
            
            // Right Sidebar - Recent Applications and Quick Actions
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Applications
                  _buildRecentApplications(data),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  _buildQuickActions(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileDashboard(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        _buildWelcomeSection(),
        const SizedBox(height: 24),

        // Stats Cards
        _buildStatsCards(data),
        const SizedBox(height: 24),

        // Recent Applications
        _buildRecentApplications(data),
        const SizedBox(height: 24),

        // Charts Section
        _buildChartsSection(data),
        const SizedBox(height: 24),

        // Quick Actions
        _buildQuickActions(),
      ],
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
              Icons.person,
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
                  'Chào mừng, ${user?.firstName ?? 'Candidate'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Theo dõi tiến trình ứng tuyển của bạn',
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
    final crossAxisCount = ResponsiveUtils.getCrossAxisCount(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 3,
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: ResponsiveUtils.isWeb(context) ? 24 : 16,
      mainAxisSpacing: ResponsiveUtils.isWeb(context) ? 24 : 16,
      childAspectRatio: ResponsiveUtils.isWeb(context) ? 1.4 : 1.2,
      children: [
        StatCard(
          title: 'Tổng đơn ứng tuyển',
          value: '${data['totalApplications'] ?? 0}',
          icon: Icons.description,
          color: Colors.blue,
          trend: '+3',
          trendUp: true,
        ),
        StatCard(
          title: 'Đơn chờ xử lý',
          value: '${data['pendingApplications'] ?? 0}',
          icon: Icons.pending,
          color: Colors.orange,
          trend: '+1',
          trendUp: true,
        ),
        StatCard(
          title: 'Đơn được chấp nhận',
          value: '${data['approvedApplications'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.green,
          trend: '+2',
          trendUp: true,
        ),
        StatCard(
          title: 'Đơn bị từ chối',
          value: '${data['rejectedApplications'] ?? 0}',
          icon: Icons.cancel,
          color: Colors.red,
          trend: '-1',
          trendUp: false,
        ),
        StatCard(
          title: 'Việc làm đã lưu',
          value: '${data['savedJobs'] ?? 0}',
          icon: Icons.favorite,
          color: Colors.pink,
          trend: '+5',
          trendUp: true,
        ),
        StatCard(
          title: 'Công ty đang theo dõi',
          value: '${data['followedCompanies'] ?? 0}',
          icon: Icons.business,
          color: Colors.purple,
          trend: '+2',
          trendUp: true,
        ),
      ],
    );
  }

  Widget _buildRecentApplications(Map<String, dynamic> data) {
    final applications = data['recentApplications'] as List<dynamic>? ?? [];
    
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
                'Đơn ứng tuyển gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to applications screen
                },
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (applications.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chưa có đơn ứng tuyển nào',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...applications.map((app) => _buildApplicationCard(app)),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final status = app['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          app['jobTitle'] ?? 'Job Title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app['companyName'] ?? 'Company Name',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${app['appliedDate'] ?? ''}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to application detail
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Được chấp nhận';
      case 'rejected':
        return 'Bị từ chối';
      case 'pending':
      default:
        return 'Chờ xử lý';
    }
  }

  Widget _buildChartsSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê ứng tuyển',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Application Status Distribution
        if (data['applicationStatusDistribution'] != null) ...[
          ChartWidget(
            title: 'Phân bố trạng thái đơn ứng tuyển',
            data: List<Map<String, dynamic>>.from(data['applicationStatusDistribution']),
            chartType: ChartType.pie,
          ),
          const SizedBox(height: 16),
        ],

        // Applications by Month
        if (data['applicationsByMonth'] != null) ...[
          ChartWidget(
            title: 'Đơn ứng tuyển theo tháng',
            data: List<Map<String, dynamic>>.from(data['applicationsByMonth']),
            chartType: ChartType.bar,
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions() {
    final isWeb = ResponsiveUtils.isWeb(context);
    final crossAxisCount = isWeb ? 1 : 2;
    final childAspectRatio = isWeb ? 4.0 : 2.5;

    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 12 : 16),
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
          Text(
            'Thao tác nhanh',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isWeb ? 20 : 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
            children: [
              _buildQuickActionCard(
                'Tìm việc làm',
                Icons.search,
                Colors.blue,
                () {
                  // Navigate to job search
                },
              ),
              _buildQuickActionCard(
                'Việc làm đã lưu',
                Icons.favorite,
                Colors.pink,
                () {
                  // Navigate to saved jobs
                },
              ),
              _buildQuickActionCard(
                'Cập nhật CV',
                Icons.edit,
                Colors.green,
                () {
                  // Navigate to profile edit
                },
              ),
              _buildQuickActionCard(
                'Cài đặt',
                Icons.settings,
                Colors.grey,
                () {
                  // Navigate to settings
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
} 