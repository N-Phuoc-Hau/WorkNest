import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/analytics_provider.dart';
import '../../../core/providers/auth_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load analytics data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).loadDetailedAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final analyticsState = ref.watch(analyticsProvider);
    
    if (authState.user?.role != 'recruiter') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Phân tích'),
        ),
        body: const Center(
          child: Text('Chỉ nhà tuyển dụng mới có thể xem trang này'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích Tuyển dụng'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportToExcel(),
            tooltip: 'Xuất Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(analyticsProvider.notifier).loadDetailedAnalytics(),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.work), text: 'Công việc'),
            Tab(icon: Icon(Icons.people), text: 'Ứng viên'),
            Tab(icon: Icon(Icons.analytics), text: 'Biểu đồ'),
          ],
        ),
      ),
      body: analyticsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : analyticsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi: ${analyticsState.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(analyticsProvider.notifier).loadDetailedAnalytics(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildJobsTab(),
                    _buildApplicationsTab(),
                    _buildChartsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final analytics = ref.watch(analyticsProvider).analytics;
    if (analytics == null) return const Center(child: Text('Không có dữ liệu'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Info Card
          _buildInfoCard(
            title: 'Thông tin công ty',
            icon: Icons.business,
            color: Colors.blue,
            children: [
              _buildInfoRow('Tên công ty', analytics.company.companyName),
              _buildInfoRow('Địa điểm', analytics.company.companyLocation),
              _buildInfoRow('Trạng thái', analytics.company.isVerified ? 'Đã xác minh' : 'Chưa xác minh'),
              _buildInfoRow('Người theo dõi', '${analytics.company.totalFollowers}'),
              _buildInfoRow('Đánh giá trung bình', '${analytics.company.averageRating.toStringAsFixed(1)}/5'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Job Stats Card
          _buildInfoCard(
            title: 'Thống kê công việc',
            icon: Icons.work,
            color: Colors.green,
            children: [
              _buildInfoRow('Tổng số việc làm', '${analytics.recruiter.totalJobsPosted}'),
              _buildInfoRow('Đang hoạt động', '${analytics.recruiter.activeJobs}'),
              _buildInfoRow('Đã đóng', '${analytics.recruiter.inactiveJobs}'),
              _buildInfoRow('Tổng lượt xem', '${analytics.recruiter.totalJobViews}'),
              _buildInfoRow('TB xem/việc làm', '${analytics.recruiter.averageViewsPerJob.toStringAsFixed(1)}'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Application Stats Card
          _buildInfoCard(
            title: 'Thống kê ứng tuyển',
            icon: Icons.assignment,
            color: Colors.orange,
            children: [
              _buildInfoRow('Tổng ứng tuyển', '${analytics.recruiter.totalApplicationsReceived}'),
              _buildInfoRow('Chờ xử lý', '${analytics.recruiter.pendingApplications}'),
              _buildInfoRow('Đã chấp nhận', '${analytics.recruiter.acceptedApplications}'),
              _buildInfoRow('Đã từ chối', '${analytics.recruiter.rejectedApplications}'),
              _buildInfoRow('Tỷ lệ ứng tuyển/xem', '${(analytics.recruiter.applicationToViewRatio * 100).toStringAsFixed(1)}%'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Top Performing Jobs
          if (analytics.jobs.allJobs.isNotEmpty)
            _buildTopJobsCard(analytics.jobs.allJobs.take(5).toList()),
        ],
      ),
    );
  }

  Widget _buildJobsTab() {
    final analytics = ref.watch(analyticsProvider).analytics;
    if (analytics == null) return const Center(child: Text('Không có dữ liệu'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best Performing Jobs
          if (analytics.jobs.bestPerformingJob != null)
            _buildJobPerformanceCard(
              title: 'Việc làm hiệu quả nhất',
              job: analytics.jobs.bestPerformingJob!,
              color: Colors.green,
            ),
          
          const SizedBox(height: 16),
          
          if (analytics.jobs.mostViewedJob != null)
            _buildJobPerformanceCard(
              title: 'Việc làm được xem nhiều nhất',
              job: analytics.jobs.mostViewedJob!,
              color: Colors.blue,
            ),
          
          const SizedBox(height: 16),
          
          if (analytics.jobs.mostAppliedJob != null)
            _buildJobPerformanceCard(
              title: 'Việc làm có nhiều ứng tuyển nhất',
              job: analytics.jobs.mostAppliedJob!,
              color: Colors.purple,
            ),
          
          const SizedBox(height: 24),
          
          // All Jobs List
          Text(
            'Tất cả công việc',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...analytics.jobs.allJobs.map((job) => _buildJobCard(job)).toList(),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab() {
    final analytics = ref.watch(analyticsProvider).analytics;
    if (analytics == null) return const Center(child: Text('Không có dữ liệu'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Application Status Distribution Chart
          _buildInfoCard(
            title: 'Phân bố trạng thái ứng tuyển',
            icon: Icons.pie_chart,
            color: Colors.indigo,
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: analytics.recruiter.applicationStatusDistribution
                        .map((data) => PieChartSectionData(
                              value: data.value,
                              title: '${data.value.toInt()}',
                              color: _getStatusColor(data.label),
                              radius: 60,
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...analytics.recruiter.applicationStatusDistribution
                  .map((data) => _buildLegendItem(data.label, _getStatusColor(data.label)))
                  .toList(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Recent Followers
          if (analytics.recruiter.recentFollowers.isNotEmpty)
            _buildInfoCard(
              title: 'Người theo dõi gần đây',
              icon: Icons.people,
              color: Colors.teal,
              children: [
                ...analytics.recruiter.recentFollowers.take(10).map((follower) => 
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: follower.userAvatar?.isNotEmpty == true
                          ? NetworkImage(follower.userAvatar!)
                          : null,
                      child: follower.userAvatar?.isEmpty == true
                          ? Text(follower.userName.substring(0, 1).toUpperCase())
                          : null,
                    ),
                    title: Text(follower.userName),
                    subtitle: Text(follower.userEmail),
                    trailing: Text(
                      _formatDate(follower.followedDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    final analytics = ref.watch(analyticsProvider).analytics;
    if (analytics == null) return const Center(child: Text('Không có dữ liệu'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Applications by Month Chart
          _buildChartCard(
            title: 'Ứng tuyển theo tháng',
            chart: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < analytics.recruiter.applicationsByMonth.length) {
                            return Text(
                              analytics.recruiter.applicationsByMonth[value.toInt()].label,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: analytics.recruiter.applicationsByMonth
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Views by Month Chart
          _buildChartCard(
            title: 'Lượt xem theo tháng',
            chart: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < analytics.recruiter.viewsByMonth.length) {
                            return Text(
                              analytics.recruiter.viewsByMonth[value.toInt()].label,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: analytics.recruiter.viewsByMonth
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Job Categories Chart
          if (analytics.recruiter.topJobCategories.isNotEmpty)
            _buildChartCard(
              title: 'Phân bố danh mục công việc',
              chart: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < analytics.recruiter.topJobCategories.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  analytics.recruiter.topJobCategories[value.toInt()].label,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    barGroups: analytics.recruiter.topJobCategories
                        .asMap()
                        .entries
                        .map((e) => BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.value,
                                  color: Colors.orange,
                                  width: 20,
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTopJobsCard(List<dynamic> jobs) {
    return _buildInfoCard(
      title: 'Top 5 việc làm hiệu quả',
      icon: Icons.trending_up,
      color: Colors.purple,
      children: [
        ...jobs.map((job) => ListTile(
          title: Text(job.jobTitle),
          subtitle: Text('${job.totalViews} lượt xem • ${job.totalApplications} ứng tuyển'),
          trailing: Text(
            '${(job.viewToApplicationRatio * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildJobPerformanceCard({
    required String title,
    required dynamic job,
    required Color color,
  }) {
    return _buildInfoCard(
      title: title,
      icon: Icons.work,
      color: color,
      children: [
        _buildInfoRow('Tiêu đề', job.jobTitle),
        _buildInfoRow('Danh mục', job.jobCategory),
        _buildInfoRow('Địa điểm', job.jobLocation),
        _buildInfoRow('Lượt xem', '${job.totalViews}'),
        _buildInfoRow('Ứng tuyển', '${job.totalApplications}'),
        _buildInfoRow('Tỷ lệ chuyển đổi', '${(job.viewToApplicationRatio * 100).toStringAsFixed(1)}%'),
        _buildInfoRow('Yêu thích', '${job.favoriteCount}'),
      ],
    );
  }

  Widget _buildJobCard(dynamic job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(job.jobTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${job.jobCategory} • ${job.jobLocation}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${job.totalViews}'),
                const SizedBox(width: 16),
                Icon(Icons.assignment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${job.totalApplications}'),
                const SizedBox(width: 16),
                Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${job.favoriteCount}'),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(job.viewToApplicationRatio * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Text(
              'Chuyển đổi',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showJobDetails(job),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required Widget chart,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            chart,
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showJobDetails(dynamic job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job.jobTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Danh mục', job.jobCategory),
              _buildInfoRow('Địa điểm', job.jobLocation),
              _buildInfoRow('Kinh nghiệm', job.experienceLevel),
              _buildInfoRow('Mức lương', '${job.salary.toStringAsFixed(0)} VND'),
              _buildInfoRow('Ngày đăng', _formatDate(DateTime.parse(job.postedDate))),
              if (job.deadLine != null)
                _buildInfoRow('Hạn nộp', _formatDate(DateTime.parse(job.deadLine))),
              _buildInfoRow('Trạng thái', job.isActive ? 'Đang mở' : 'Đã đóng'),
              const Divider(),
              _buildInfoRow('Tổng lượt xem', '${job.totalViews}'),
              _buildInfoRow('Lượt xem duy nhất', '${job.uniqueViews}'),
              _buildInfoRow('Tổng ứng tuyển', '${job.totalApplications}'),
              _buildInfoRow('Chờ xử lý', '${job.pendingApplications}'),
              _buildInfoRow('Đã chấp nhận', '${job.acceptedApplications}'),
              _buildInfoRow('Đã từ chối', '${job.rejectedApplications}'),
              _buildInfoRow('Tỷ lệ chuyển đổi', '${(job.viewToApplicationRatio * 100).toStringAsFixed(1)}%'),
              _buildInfoRow('Tỷ lệ chấp nhận', '${(job.acceptanceRate * 100).toStringAsFixed(1)}%'),
              _buildInfoRow('Số lượt yêu thích', '${job.favoriteCount}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _exportToExcel() async {
    try {
      final result = await ref.read(analyticsProvider.notifier).exportToExcel();
      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xuất Excel thành công! File đã được tải về.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xuất Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
