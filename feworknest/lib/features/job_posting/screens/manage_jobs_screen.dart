import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/job_posting_provider.dart';

class ManageJobsScreen extends ConsumerStatefulWidget {
  static const String routeName = '/manage-jobs';

  const ManageJobsScreen({super.key});

  @override
  ConsumerState<ManageJobsScreen> createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends ConsumerState<ManageJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load jobs when screen loads
    Future.microtask(() {
      ref.read(jobPostingProvider.notifier).loadMyJobs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobPostingState = ref.watch(jobPostingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tin tuyển dụng'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/create-job'),
            tooltip: 'Tạo tin mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đang tuyển'),
            Tab(text: 'Đã đóng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Jobs Tab
          _buildJobsList(jobPostingState.myJobs),
          
          // Active Jobs Tab
          _buildJobsList(
            jobPostingState.myJobs.where((job) => job.isActive).toList(),
          ),
          
          // Closed Jobs Tab
          _buildJobsList(
            jobPostingState.myJobs.where((job) => !job.isActive).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-job'),
        child: const Icon(Icons.add),
        tooltip: 'Tạo tin tuyển dụng mới',
      ),
    );
  }

  Widget _buildJobsList(List<JobModel> jobs) {
    final jobPostingState = ref.watch(jobPostingProvider);

    if (jobPostingState.isLoading && jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobPostingState.error != null) {
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
              'Lỗi: ${jobPostingState.error}',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(jobPostingProvider.notifier).loadMyJobs();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có tin tuyển dụng nào',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo tin tuyển dụng đầu tiên của bạn',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/create-job'),
              child: const Text('Tạo tin tuyển dụng'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(jobPostingProvider.notifier).loadMyJobs();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _buildJobCard(job);
        },
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.specialized,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: job.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.isActive ? 'Đang tuyển' : 'Đã đóng',
                    style: TextStyle(
                      color: job.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Job Info
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.location,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '\$${job.salary.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Đăng ${_formatDate(job.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/edit-job/${job.id}'),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Chỉnh sửa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteDialog(job),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Xóa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _showDeleteDialog(JobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin tuyển dụng'),
        content: Text(
          'Bạn có chắc chắn muốn xóa tin tuyển dụng "${job.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(jobPostingProvider.notifier).deleteJob(job.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa tin tuyển dụng'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
