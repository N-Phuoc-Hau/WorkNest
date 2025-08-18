import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/favorite_provider.dart';

class JobCard extends ConsumerWidget {
  final JobModel job;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Watch favorite state to auto-refresh UI
    final favoriteState = ref.watch(favoriteProvider);
    final isFavorited = favoriteState.favoriteJobs
        .any((favorite) => favorite.jobId == job.id);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with company logo and favorite button
              Row(
                children: [
                  // Company logo placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: job.recruiter.company?.images.isNotEmpty == true
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              job.recruiter.company!.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  color: theme.primaryColor,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.business,
                            color: theme.primaryColor,
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Company info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.recruiter.company?.name ?? 'Công ty chưa xác định',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (job.recruiter.company?.isVerified == true)
                          Row(
                            children: [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Đã xác thực',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  // Favorite button
                  if (onFavorite != null)
                    IconButton(
                      onPressed: onFavorite,
                      icon: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? Colors.red : Colors.grey[600],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Job title
              Text(
                job.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Job description
              Text(
                job.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Job details chips
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildInfoChip(
                    Icons.location_on,
                    job.location,
                    Colors.blue,
                  ),
                  _buildInfoChip(
                    Icons.work,
                    job.specialized,
                    Colors.green,
                  ),
                  _buildInfoChip(
                    Icons.attach_money,
                    '\$${job.salary.toStringAsFixed(0)}',
                    Colors.orange,
                  ),
                  if (job.jobType != null)
                    _buildInfoChip(
                      Icons.schedule,
                      job.jobType!,
                      Colors.purple,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Footer with posting date and application count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(job.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${job.applicationCount} ứng viên',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
