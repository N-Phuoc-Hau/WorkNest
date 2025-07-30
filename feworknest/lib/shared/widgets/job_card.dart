import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/favorite_provider.dart';
import '../../../core/utils/auth_guard.dart';

class JobCard extends ConsumerWidget {
  final JobModel job;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorited = ref.watch(favoriteProvider).favoriteJobs
        .any((favorite) => favorite.jobId == job.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap ?? () => context.go('/jobs/${job.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (!AuthGuard.requireAuth(context, ref, 
                          message: 'Bạn cần đăng nhập để lưu việc làm yêu thích.')) {
                        return;
                      }
                      _toggleFavorite(ref, job.id);
                    },
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: job.recruiter.avatar != null
                        ? NetworkImage(job.recruiter.avatar!)
                        : null,
                    child: job.recruiter.avatar == null
                        ? Text(
                            (job.recruiter.company?.name ?? 'C')[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.recruiter.company?.name ?? 'Unknown Company',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          job.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChip(context, job.specialized),
                  if (job.jobType != null) _buildChip(context, job.jobType!),
                  _buildChip(
                    context,
                    '${job.salary.toStringAsFixed(0)} VNĐ',
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(job.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (job.applicationCount > 0)
                    Text(
                      '${job.applicationCount} ứng tuyển',
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
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color ?? Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} tuần trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
}
