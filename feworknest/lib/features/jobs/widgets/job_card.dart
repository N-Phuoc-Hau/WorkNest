import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/favorite_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

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
    final themeMode = Theme.of(context).brightness;
    final isDark = themeMode == Brightness.dark;
    // final l10n = AppLocalizations.of(context)!;
    
    // Watch favorite state to auto-refresh UI
    final favoriteState = ref.watch(favoriteProvider);
    final isFavorited = favoriteState.favoriteJobs
        .any((favorite) => favorite.jobId == job.id);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with company logo and favorite button
                Row(
                  children: [
                    // Company logo
                    _buildCompanyLogo(context, isDark),
                    SizedBox(width: AppSpacing.spacing12),
                    
                    // Company info
                    Expanded(
                      child: _buildCompanyInfo(context, isDark),
                    ),
                    
                    // Favorite button
                    if (onFavorite != null)
                      IconButton(
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorited 
                              ? Icons.favorite_rounded 
                              : Icons.favorite_border_rounded,
                          color: isFavorited ? AppColors.error : AppColors.neutral400,
                        ),
                        tooltip: isFavorited ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                      ),
                  ],
                ),
                
                SizedBox(height: AppSpacing.spacing16),
                
                // Job title
                Text(
                  job.title,
                  style: AppTypography.h6.copyWith(
                    color: isDark ? AppColors.white : AppColors.neutral900,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: AppSpacing.spacing12),
                
                // Job description
                Text(
                  job.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: AppSpacing.spacing16),
                
                // Job tags/chips
                Wrap(
                  spacing: AppSpacing.spacing8,
                  runSpacing: AppSpacing.spacing8,
                  children: [
                    _buildChip(
                      icon: Icons.location_on_rounded,
                      label: job.location,
                      color: AppColors.info,
                      isDark: isDark,
                    ),
                    _buildChip(
                      icon: Icons.work_rounded,
                      label: job.specialized,
                      color: AppColors.success,
                      isDark: isDark,
                    ),
                    if (job.jobType != null)
                      _buildChip(
                        icon: Icons.schedule_rounded,
                        label: job.jobType!,
                        color: AppColors.warning,
                        isDark: isDark,
                      ),
                  ],
                ),
                
                SizedBox(height: AppSpacing.spacing16),
                
                // Divider
                Divider(
                  color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                  height: 1,
                ),
                
                SizedBox(height: AppSpacing.spacing16),
                
                // Footer with salary, applicants, and date
                Row(
                  children: [
                    // Salary
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(AppSpacing.spacing6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: AppSpacing.borderRadiusSm,
                            ),
                            child: Icon(
                              Icons.attach_money_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: AppSpacing.spacing8),
                          Expanded(
                            child: Text(
                              job.salaryFormatted,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: AppSpacing.spacing12),
                    
                    // Applicants count
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 16,
                          color: AppColors.neutral500,
                        ),
                        SizedBox(width: AppSpacing.spacing4),
                        Text(
                          '${job.applicationCount}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(width: AppSpacing.spacing12),
                    
                    // Posted date
                    Text(
                      _formatDate(job.createdAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyLogo(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (job.recruiter.company?.id != null) {
          context.push('/company/${job.recruiter.company!.id}');
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutral700 : AppColors.neutral50,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isDark ? AppColors.neutral600 : AppColors.neutral200,
          ),
        ),
        child: job.recruiter.company?.images.isNotEmpty == true
            ? ClipRRect(
                borderRadius: AppSpacing.borderRadiusMd,
                child: Image.network(
                  job.recruiter.company!.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.business_rounded,
                      color: AppColors.primary,
                      size: 28,
                    );
                  },
                ),
              )
            : Icon(
                Icons.business_rounded,
                color: AppColors.primary,
                size: 28,
              ),
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (job.recruiter.company?.id != null) {
          context.push('/company/${job.recruiter.company!.id}');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.recruiter.company?.name ?? 'Công ty chưa xác định',
            style: AppTypography.labelLarge.copyWith(
              color: isDark ? AppColors.white : AppColors.neutral900,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSpacing.spacing4),
          if (job.recruiter.company?.isVerified == true)
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: AppColors.info,
                ),
                SizedBox(width: AppSpacing.spacing4),
                Text(
                  'Đã xác thực',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Text(
                  '${job.applicationCount} ',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'công việc',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: color.withOpacity(isDark ? 0.3 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          SizedBox(width: AppSpacing.spacing4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
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
      return DateFormat('dd/MM/yyyy').format(date);
    } else if (difference.inDays > 0) {
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
