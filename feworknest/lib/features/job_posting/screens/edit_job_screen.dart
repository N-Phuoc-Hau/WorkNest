import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/job_posting_provider.dart';
import '../../../core/providers/job_provider.dart';
import '../widgets/job_form.dart';

class EditJobScreen extends ConsumerStatefulWidget {
  static const String routeName = '/edit-job';
  
  final String jobId;

  const EditJobScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends ConsumerState<EditJobScreen> {
  @override
  void initState() {
    super.initState();
    // Load job details if needed
  }

  @override
  Widget build(BuildContext context) {
    final jobPostingState = ref.watch(jobPostingProvider);
    final jobPostingNotifier = ref.read(jobPostingProvider.notifier);
    // Find the current job
    final jobState = ref.watch(jobProvider);
    final currentJob = jobState.jobs.firstWhere(
      (job) => job.id == int.tryParse(widget.jobId),
      orElse: () => throw Exception('Job not found'),
    );

    ref.listen(jobPostingProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        if (next.error == null) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật tin tuyển dụng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          // Error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${next.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa tin tuyển dụng'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(
                      currentJob.isActive ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(currentJob.isActive ? 'Tạm dừng' : 'Kích hoạt'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa tin', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'toggle_status':
                  _toggleJobStatus(currentJob);
                  break;
                case 'delete':
                  _showDeleteDialog(currentJob);
                  break;
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: currentJob.isActive ? Colors.green.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      currentJob.isActive ? Icons.check_circle : Icons.pause_circle,
                      color: currentJob.isActive ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentJob.isActive ? 'Tin đang hoạt động' : 'Tin tạm dừng',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: currentJob.isActive ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentJob.isActive 
                                ? 'Ứng viên có thể xem và ứng tuyển vào tin này'
                                : 'Tin này đang bị ẩn khỏi ứng viên',
                            style: TextStyle(
                              fontSize: 12,
                              color: currentJob.isActive ? Colors.green.shade600 : Colors.orange.shade600,
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

            // Job Form
            JobForm(
              initialJob: currentJob,
              onCreateJob: (createJobModel) {
                // This won't be called for edit
              },
              onUpdateJob: (updateJobModel) {
                final jobId = int.tryParse(widget.jobId) ?? 0;
                jobPostingNotifier.updateJob(jobId, updateJobModel);
              },
              isLoading: jobPostingState.isLoading,
            ),

            const SizedBox(height: 24),

            // Statistics Card (if available)
            if (currentJob.isActive)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thống kê tin tuyển dụng',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Lượt xem',
                              '0', // TODO: Add view count from backend
                              Icons.visibility,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Ứng tuyển',
                              '0', // TODO: Add application count from backend
                              Icons.person,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Yêu thích',
                              '0', // TODO: Add favorite count from backend
                              Icons.favorite,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _toggleJobStatus(job) {
    // TODO: Implement toggle job status API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          job.isActive ? 'Đã tạm dừng tin tuyển dụng' : 'Đã kích hoạt tin tuyển dụng',
        ),
        backgroundColor: job.isActive ? Colors.orange : Colors.green,
      ),
    );
  }

  void _showDeleteDialog(job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin tuyển dụng'),
        content: Text(
          'Bạn có chắc chắn muốn xóa tin tuyển dụng "${job.title}"?\n\nHành động này không thể hoàn tác.',
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
                  backgroundColor: Colors.red,
                ),
              );
              
              context.pop(); // Go back to manage jobs screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
