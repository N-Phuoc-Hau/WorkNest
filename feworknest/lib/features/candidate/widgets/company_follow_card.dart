import 'package:flutter/material.dart';

import '../../../core/models/follow_model.dart';

class CompanyFollowCard extends StatelessWidget {
  final FollowModel follow;
  final VoidCallback? onTap;
  final VoidCallback? onUnfollow;

  const CompanyFollowCard({
    super.key,
    required this.follow,
    this.onTap,
    this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final company = follow.recruiter?.company;

    if (company == null) {
      return const SizedBox.shrink();
    }
    
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
              // Header with company info and unfollow button
              Row(
                children: [
                  // Company logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: company.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              company.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  color: theme.primaryColor,
                                  size: 32,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.business,
                            color: theme.primaryColor,
                            size: 32,
                          ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Company info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                company.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (company.isVerified)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: Colors.blue[600],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (company.location?.isNotEmpty == true)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  company.location!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Theo dõi từ ${_formatDate(follow.createdAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Unfollow button
                  if (onUnfollow != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'unfollow') {
                          _showUnfollowDialog(context);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'unfollow',
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_remove,
                                color: Colors.red[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bỏ theo dõi',
                                style: TextStyle(
                                  color: Colors.red[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Company description (if available)
              if (company.description?.isNotEmpty == true) ...[
                Text(
                  company.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Company stats or additional info
              Row(
                children: [
                  _buildInfoChip(
                    Icons.business_center,
                    'Đang tuyển dụng',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  if (company.taxCode?.isNotEmpty == true)
                    _buildInfoChip(
                      Icons.verified_outlined,
                      'Đã xác thực',
                      Colors.blue,
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
    
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _showUnfollowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bỏ theo dõi công ty'),
          content: Text(
            'Bạn có chắc chắn muốn bỏ theo dõi "${follow.recruiter?.company?.name}"?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onUnfollow?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Bỏ theo dõi'),
            ),
          ],
        );
      },
    );
  }
}
