import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/favorite_provider.dart';
import '../../../core/providers/job_provider.dart';
import '../../../core/utils/application_utils.dart';
import '../../../core/utils/auth_guard.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobIdInt = int.tryParse(widget.jobId) ?? 0;
      ref.read(jobProvider.notifier).getJobPost(jobIdInt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobProvider);
    final job = jobsState.selectedJob;
    final isLoading = jobsState.isLoading;
    final error = jobsState.error;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết công việc')),
        body: Center(
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
                error ?? 'Không tìm thấy công việc',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isFavorited = ref.watch(favoriteProvider).favoriteJobs
                  .any((favorite) => favorite.jobId == job.id);
              
              return IconButton(
                onPressed: () {
                  if (!AuthGuard.requireAuth(context, ref, 
                      message: 'Bạn cần đăng nhập để lưu việc làm yêu thích.')) {
                    return;
                  }
                  _toggleFavorite(ref, job.id);
                },
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : null,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: job.recruiter.avatar != null
                          ? NetworkImage(job.recruiter.avatar!)
                          : null,
                      child: job.recruiter.avatar == null
                          ? Text(
                              (job.recruiter.company?.name ?? 'C')[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.recruiter.company?.name ?? 'Unknown Company',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (job.recruiter.company?.isVerified == true)
                            Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Đã xác minh',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Job Title
            Text(
              job.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Job Tags
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildChip(context, job.specialized, Icons.work),
                if (job.jobType != null)
                  _buildChip(context, job.jobType!, Icons.schedule),
                _buildChip(
                  context,
                  '${job.salary.toStringAsFixed(0)} VNĐ',
                  Icons.attach_money,
                  color: Colors.green,
                ),
                _buildChip(context, job.location, Icons.location_on),
                _buildChip(context, job.workingHours, Icons.access_time),
              ],
            ),
            const SizedBox(height: 16),

            // Job Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mô tả công việc',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Company Description
            if (job.recruiter.company?.description != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Về công ty',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.recruiter.company!.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Company Reviews Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đánh giá công ty',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (job.recruiter.company != null) {
                                context.push(
                                  '/reviews?companyId=${job.recruiter.company!.id}&companyName=${Uri.encodeComponent(job.recruiter.company!.name)}',
                                );
                              }
                            },
                            icon: const Icon(Icons.star_outline),
                            label: const Text('Xem đánh giá'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (!AuthGuard.requireAuth(context, ref, 
                                  message: 'Bạn cần đăng nhập để viết đánh giá công ty.')) {
                                return;
                              }
                              if (job.recruiter.company != null) {
                                context.push(
                                  '/company-review/${job.recruiter.company!.id}/${Uri.encodeComponent(job.recruiter.company!.name)}',
                                );
                              }
                            },
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Viết đánh giá'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Job Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${job.applicationCount}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Text(
                          'Ứng tuyển',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Column(
                      children: [
                        Text(
                          _formatDate(job.createdAt),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ngày đăng',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authProvider);
          final user = authState.user;
          
          // Show apply button for both authenticated candidates and unauthenticated users
          if (authState.isAuthenticated && user?.role != 'candidate') {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () {
              if (!AuthGuard.requireAuth(context, ref, 
                  message: 'Bạn cần đăng nhập để ứng tuyển vào vị trí này.')) {
                return;
              }
              _showApplyDialog(context, job);
            },
            label: const Text('Ứng tuyển'),
            icon: const Icon(Icons.send),
          );
        },
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _toggleFavorite(WidgetRef ref, int jobId) async {
    final favoriteNotifier = ref.read(favoriteProvider.notifier);
    final isFavorited = ref.read(favoriteProvider).favoriteJobs
        .any((favorite) => favorite.jobId == jobId);

    if (isFavorited) {
      await favoriteNotifier.removeFromFavorite(jobId);
    } else {
      await favoriteNotifier.addToFavorite(jobId);
    }
  }

  void _showApplyDialog(BuildContext context, JobModel job) {
    ApplicationUtils.showApplicationDialog(
      context: context,
      jobId: job.id,
      jobTitle: job.title,
      companyName: job.recruiter.company?.name ?? 'Unknown Company',
    );
  }
}
