import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/follow_model.dart';
import '../../../core/models/job_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/favorite_provider.dart';
import '../../../core/providers/follow_provider.dart';
import '../../../core/providers/job_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/application_utils.dart';
import '../../../core/utils/auth_guard.dart';
import '../../../shared/widgets/language_toggle_widget.dart';
import '../widgets/job_card.dart';

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
      
      // Load recent jobs for similar jobs section
      ref.read(jobProvider.notifier).getJobPosts(page: 1, pageSize: 20);
      
      // Load following list to check follow status
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated && authState.user?.role == 'candidate') {
        ref.read(followProvider.notifier).getMyFollowing();
        ref.read(favoriteProvider.notifier).getMyFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobProvider);
    final job = jobsState.selectedJob;
    final isLoading = jobsState.isLoading;
    final error = jobsState.error;
    final l10n = ref.watch(localizationsProvider);
    final themeMode = Theme.of(context).brightness;
    final isDark = themeMode == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral50,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (error != null || job == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral50,
        appBar: AppBar(
          title: Text(l10n.jobDetail),
          backgroundColor: isDark ? AppColors.neutral800 : AppColors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.neutral400,
              ),
              SizedBox(height: AppSpacing.spacing16),
              Text(
                error ?? 'Không tìm thấy công việc',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.white : AppColors.neutral900,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.spacing16),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: Text(l10n.back),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral50,
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          _buildAppBar(job, l10n, isDark),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company info card with action buttons
                  _buildCompanyInfoCard(job, l10n, isDark),
                  
                  SizedBox(height: AppSpacing.spacing20),
                  
                  // About this role section
                  _buildAboutThisRoleCard(job, l10n, isDark),
                  
                  SizedBox(height: AppSpacing.spacing20),
                  
                  // Categories
                  if (job.specialized.isNotEmpty)
                    _buildCategoriesCard(job, l10n, isDark),
                  
                  if (job.specialized.isNotEmpty)
                    SizedBox(height: AppSpacing.spacing20),
                  
                  // Description
                  _buildSectionCard(
                    title: l10n.description,
                    content: job.description,
                    icon: Icons.description_rounded,
                    isDark: isDark,
                  ),
                  
                  SizedBox(height: AppSpacing.spacing20),
                  
                  // About Company
                  if (job.recruiter.company?.description != null)
                    _buildSectionCard(
                      title: l10n.aboutCompany,
                      content: job.recruiter.company!.description!,
                      icon: Icons.business_rounded,
                      isDark: isDark,
                    ),
                  
                  if (job.recruiter.company?.description != null)
                    SizedBox(height: AppSpacing.spacing20),
                  
                  // Similar Jobs
                  _buildSimilarJobsSection(job, jobsState, l10n, isDark),
                  
                  SizedBox(height: AppSpacing.spacing96), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildApplyButton(job, l10n),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar(JobModel job, dynamic l10n, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: EdgeInsets.only(
            left: AppSpacing.spacing64,
            bottom: AppSpacing.spacing16,
          ),
          title: Text(
            job.title,
            style: AppTypography.h5.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: EdgeInsets.all(AppSpacing.spacing8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.white,
          ),
        ),
      ),
      actions: [
        // Share button
        IconButton(
          onPressed: () {
            // TODO: Implement share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tính năng chia sẻ đang được phát triển'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: Container(
            padding: EdgeInsets.all(AppSpacing.spacing8),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              Icons.share_rounded,
              color: AppColors.white,
            ),
          ),
        ),
        // Language toggle
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.spacing16),
          child: const LanguageToggleButton(isDarkBg: true),
        ),
      ],
    );
  }

  Widget _buildCompanyInfoCard(JobModel job, dynamic l10n, bool isDark) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final showActions = !authState.isAuthenticated || user?.role == 'candidate';
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.white,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company logo and info
          Row(
            children: [
              // Company logo
              GestureDetector(
                onTap: () {
                  if (job.recruiter.company?.id != null) {
                    context.push('/company/${job.recruiter.company!.id}');
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: isDark ? AppColors.neutral700 : AppColors.neutral200,
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
                                size: 36,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.business_rounded,
                          color: AppColors.primary,
                          size: 36,
                        ),
                ),
              ),
              SizedBox(width: AppSpacing.spacing16),
              
              // Company info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.recruiter.company?.name ?? 'Unknown Company',
                            style: AppTypography.h6.copyWith(
                              color: isDark ? AppColors.white : AppColors.neutral900,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (job.recruiter.company?.isVerified == true)
                          Container(
                            margin: EdgeInsets.only(left: AppSpacing.spacing8),
                            padding: EdgeInsets.all(AppSpacing.spacing4),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: AppSpacing.borderRadiusSm,
                            ),
                            child: Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.info,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacing4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppColors.neutral500,
                        ),
                        SizedBox(width: AppSpacing.spacing4),
                        Text(
                          job.location,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Action buttons (Follow & Save)
          if (showActions) ...[
            SizedBox(height: AppSpacing.spacing16),
            Consumer(
              builder: (context, ref, child) {
                if (job.recruiter.company?.id == null) {
                  return const SizedBox.shrink();
                }
                
                final followState = ref.watch(followProvider);
                final isFollowing = followState.followingCompanies.any(
                  (company) => company.id == job.recruiter.company!.id
                );

                final favoriteState = ref.watch(favoriteProvider);
                final isFavorited = favoriteState.favoriteJobs
                    .any((favorite) => favorite.jobId == job.id);
                
                return Row(
                  children: [
                    // Follow button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (!AuthGuard.requireAuth(context, ref, 
                              message: 'Bạn cần đăng nhập để theo dõi công ty.')) {
                            return;
                          }
                          _toggleFollowCompany(ref, job.recruiter.company!.id);
                        },
                        icon: Icon(
                          isFollowing ? Icons.person_remove_rounded : Icons.person_add_rounded,
                          size: 20,
                        ),
                        label: Text(isFollowing ? l10n.unfollowCompany : l10n.followCompany),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.spacing12,
                          ),
                          side: BorderSide(
                            color: isFollowing ? AppColors.warning : AppColors.primary,
                          ),
                          foregroundColor: isFollowing ? AppColors.warning : AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacing12),
                    
                    // Save button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (!AuthGuard.requireAuth(context, ref, 
                              message: 'Bạn cần đăng nhập để lưu việc làm.')) {
                            return;
                          }
                          _toggleFavorite(ref, job.id);
                        },
                        icon: Icon(
                          isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 20,
                        ),
                        label: Text(isFavorited ? l10n.unsaveJob : l10n.saveJob),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.spacing12,
                          ),
                          backgroundColor: isFavorited ? AppColors.error : AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutThisRoleCard(JobModel job, dynamic l10n, bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.white,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aboutThisRole,
            style: AppTypography.h6.copyWith(
              color: isDark ? AppColors.white : AppColors.neutral900,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing16),
          
          // Info rows
          _buildInfoRow(
            icon: Icons.people_rounded,
            label: l10n.applicants,
            value: '${job.applicationCount}',
            isDark: isDark,
          ),
          SizedBox(height: AppSpacing.spacing12),
          
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: l10n.postedDate,
            value: _formatDate(job.createdAt),
            isDark: isDark,
          ),
          SizedBox(height: AppSpacing.spacing12),
          
          _buildInfoRow(
            icon: Icons.work_rounded,
            label: l10n.jobType,
            value: job.jobType ?? l10n.fullTime,
            isDark: isDark,
          ),
          SizedBox(height: AppSpacing.spacing12),
          
          _buildInfoRow(
            icon: Icons.attach_money_rounded,
            label: l10n.salary,
            value: '${NumberFormat('#,###').format(job.salary)} VNĐ',
            isDark: isDark,
            valueColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.spacing8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.neutral300 : AppColors.neutral600,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: valueColor ?? (isDark ? AppColors.white : AppColors.neutral900),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesCard(JobModel job, dynamic l10n, bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.white,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  Icons.category_rounded,
                  size: 20,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: AppSpacing.spacing12),
              Text(
                l10n.categories,
                style: AppTypography.h6.copyWith(
                  color: isDark ? AppColors.white : AppColors.neutral900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacing16),
          
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: [
              _buildCategoryChip(job.specialized, AppColors.warning, isDark),
              if (job.jobType != null)
                _buildCategoryChip(job.jobType!, AppColors.info, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.white,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: AppSpacing.spacing12),
              Text(
                title,
                style: AppTypography.h6.copyWith(
                  color: isDark ? AppColors.white : AppColors.neutral900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacing16),
          
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarJobsSection(JobModel job, dynamic jobsState, dynamic l10n, bool isDark) {
    final similarJobs = jobsState.jobs.where((relatedJob) => 
      relatedJob.id != job.id &&
      (relatedJob.location.toLowerCase().contains(job.location.toLowerCase()) ||
       relatedJob.jobType == job.jobType ||
       relatedJob.specialized == job.specialized)
    ).take(3).toList();

    if (similarJobs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.spacing8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(
                Icons.work_outline_rounded,
                size: 20,
                color: AppColors.success,
              ),
            ),
            SizedBox(width: AppSpacing.spacing12),
            Text(
              l10n.similarJobs,
              style: AppTypography.h6.copyWith(
                color: isDark ? AppColors.white : AppColors.neutral900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/jobs'),
              child: Row(
                children: [
                  Text(
                    l10n.showAll,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacing4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.spacing16),
        
        ...similarJobs.map((relatedJob) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.spacing16),
          child: GestureDetector(
            onTap: () => context.push('/jobs/${relatedJob.id}'),
            child: JobCard(job: relatedJob),
          ),
        )),
      ],
    );
  }

  Widget _buildApplyButton(JobModel job, dynamic l10n) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    // Only show for candidates or unauthenticated users
    if (authState.isAuthenticated && user?.role != 'candidate') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
      child: ElevatedButton(
        onPressed: () {
          if (!AuthGuard.requireAuth(context, ref, 
              message: 'Bạn cần đăng nhập để ứng tuyển vào vị trí này.')) {
            return;
          }
          _showApplyDialog(context, job);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusXl,
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, size: 20),
            SizedBox(width: AppSpacing.spacing8),
            Text(
              l10n.applyNow,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _toggleFavorite(WidgetRef ref, int jobId) async {
    final l10n = ref.read(localizationsProvider);
    final favoriteNotifier = ref.read(favoriteProvider.notifier);
    final favoriteState = ref.read(favoriteProvider);
    final isFavorited = favoriteState.favoriteJobs
        .any((favorite) => favorite.jobId == jobId);
    
    if (isFavorited) {
      final success = await favoriteNotifier.removeFromFavorite(jobId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.removedFromFavorites),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        );
      }
    } else {
      final success = await favoriteNotifier.addToFavorite(jobId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addedToFavorites),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleFollowCompany(WidgetRef ref, int companyId) async {
    final followNotifier = ref.read(followProvider.notifier);
    final followState = ref.read(followProvider);
    final isFollowing = followState.followingCompanies.any(
      (company) => company.id == companyId
    );

    if (isFollowing) {
      final success = await followNotifier.unfollowCompany(companyId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã bỏ theo dõi công ty'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        );
      }
    } else {
      final createFollow = CreateFollowModel(companyId: companyId);
      final success = await followNotifier.followCompany(createFollow);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã theo dõi công ty'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        );
      }
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
