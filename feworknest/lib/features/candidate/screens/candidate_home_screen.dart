import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/language_toggle_widget.dart';

class CandidateHomeScreen extends ConsumerWidget {
  const CandidateHomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning';
    if (hour < 18) return 'good_afternoon';
    return 'good_evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final l10n = ref.watch(localizationsProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final isWide = MediaQuery.of(context).size.width > 1024;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isWide ? AppSpacing.spacing32 : AppSpacing.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with theme and language toggles
              _buildHeader(context, ref, l10n, isDark),
              SizedBox(height: AppSpacing.spacing32),

              // Greeting
              _buildGreeting(context, ref, user, l10n),
              SizedBox(height: AppSpacing.spacing32),

              // Stats Cards
              _buildStatsSection(context, l10n, isWide),
              SizedBox(height: AppSpacing.spacing32),

              // Recent Applications
              _buildRecentApplications(context, l10n, isWide),
              SizedBox(height: AppSpacing.spacing32),

              // Quick Actions
              _buildQuickActions(context, l10n, isWide),
              
              SizedBox(height: AppSpacing.spacing64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic l10n, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.dashboard,
          style: AppTypography.h2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            // Theme toggle
            IconButton(
              onPressed: () {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: AppColors.neutral700,
              ),
              tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            ),
            SizedBox(width: AppSpacing.spacing8),
            
            // Language toggle
            const LanguageToggleButton(),
            
            SizedBox(width: AppSpacing.spacing8),
            
            // Notifications
            IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Badge(
                label: const Text('3'),
                child: Icon(
                  Icons.notifications_outlined,
                  color: AppColors.neutral700,
                ),
              ),
              tooltip: 'Notifications',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, WidgetRef ref, dynamic user, dynamic l10n) {
    final greeting = _getGreeting();
    final greetingText = greeting == 'good_morning'
        ? l10n.goodMorning
        : greeting == 'good_afternoon'
            ? l10n.goodAfternoon
            : l10n.goodEvening;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greetingText, ${user?.firstName ?? 'User'}',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.spacing8),
        Text(
          l10n.welcomeDashboard,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, dynamic l10n, bool isWide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isWide) {
          return Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildStatCard(
                  context,
                  l10n.totalJobsApplied,
                  '12',
                  Icons.work_outline,
                  AppColors.primary,
                ),
              ),
              SizedBox(width: AppSpacing.spacing16),
              Expanded(
                flex: 1,
                child: _buildStatCard(
                  context,
                  l10n.interviewed,
                  '5',
                  Icons.people_outline,
                  AppColors.success,
                ),
              ),
              SizedBox(width: AppSpacing.spacing16),
              Expanded(
                flex: 1,
                child: _buildStatusCard(context, l10n),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      l10n.totalJobsApplied,
                      '12',
                      Icons.work_outline,
                      AppColors.primary,
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacing16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      l10n.interviewed,
                      '5',
                      Icons.people_outline,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.spacing16),
              _buildStatusCard(context, l10n),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.neutral800
              : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.spacing12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacing16),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          SizedBox(height: AppSpacing.spacing8),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, dynamic l10n) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.neutral800
              : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.jobsAppliedStatus,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.spacing24),
          
          // Status items
          _buildStatusItem(l10n.reviewed, 5, Colors.blue),
          SizedBox(height: AppSpacing.spacing12),
          _buildStatusItem(l10n.shortlisted, 3, Colors.green),
          SizedBox(height: AppSpacing.spacing12),
          _buildStatusItem(l10n.inReview, 2, Colors.orange),
          SizedBox(height: AppSpacing.spacing12),
          _buildStatusItem(l10n.declined, 2, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing12,
            vertical: AppSpacing.spacing4,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentApplications(BuildContext context, dynamic l10n, bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentApplications,
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/applications'),
              child: Text(l10n.viewAllApplications),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.spacing16),
        
        // Mock applications
        _buildApplicationItem(
          context,
          'Senior UI/UX Designer',
          'Nomad',
          'Paris, France',
          '24 July 2024',
          l10n.inReview,
          Colors.orange,
          'https://via.placeholder.com/40',
        ),
        SizedBox(height: AppSpacing.spacing12),
        _buildApplicationItem(
          context,
          'Social Media Assistant',
          'Udacity',
          'New York, USA',
          '23 July 2024',
          l10n.shortlisted,
          Colors.green,
          'https://via.placeholder.com/40',
        ),
        SizedBox(height: AppSpacing.spacing12),
        _buildApplicationItem(
          context,
          'Marketing Manager',
          'Packer',
          'Madrid, Spain',
          '22 July 2024',
          l10n.declined,
          Colors.red,
          'https://via.placeholder.com/40',
        ),
      ],
    );
  }

  Widget _buildApplicationItem(
    BuildContext context,
    String jobTitle,
    String company,
    String location,
    String dateApplied,
    String status,
    Color statusColor,
    String logoUrl,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.neutral800
              : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          // Company logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.business,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacing16),
          
          // Job info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobTitle,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.spacing4),
                Text(
                  '$company • $location',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.spacing4),
                Text(
                  dateApplied,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: AppSpacing.spacing12),
          
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing12,
              vertical: AppSpacing.spacing6,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              status,
              style: AppTypography.bodySmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic l10n, bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.spacing16),
        
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = isWide ? 4 : 2;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSpacing.spacing16,
              mainAxisSpacing: AppSpacing.spacing16,
              childAspectRatio: 1.3,
              children: [
                _buildQuickActionCard(
                  context,
                  l10n.findJobs,
                  l10n.exploreJobs,
                  Icons.search,
                  AppColors.primary,
                  () => context.go('/jobs'),
                ),
                _buildQuickActionCard(
                  context,
                  l10n.myApplications,
                  l10n.trackApplications,
                  Icons.work_outline,
                  Colors.orange,
                  () => context.go('/applications'),
                ),
                _buildQuickActionCard(
                  context,
                  l10n.favorites,
                  l10n.savedJobs,
                  Icons.favorite_outline,
                  Colors.red,
                  () => context.go('/favorites'),
                ),
                _buildQuickActionCard(
                  context,
                  l10n.browseCompanies,
                  l10n.followedCompanies,
                  Icons.business_outlined,
                  Colors.green,
                  () => context.go('/following-companies'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.neutral800
                : AppColors.neutral200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.spacing12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            SizedBox(height: AppSpacing.spacing12),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.spacing4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, ${user?.firstName ?? 'User'}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tìm kiếm công việc mơ ước của bạn',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Quick actions section
            Text(
              'Hoạt động nhanh',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Quick actions - responsive grid
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final crossAxisCount = screenWidth > 600 ? 3 : 2;
                final childAspectRatio = screenWidth > 600 ? 1.2 : 0.85; // Increased height for mobile
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildQuickActionCard(
                      context,
                      icon: Icons.search,
                      title: 'Tìm việc làm',
                      subtitle: 'Khám phá cơ hội mới',
                      color: Colors.blue,
                      onTap: () => context.go('/jobs'),
                    ),
                    _buildQuickActionCard(
                      context,
                      icon: Icons.work,
                      title: 'Đơn ứng tuyển',
                      subtitle: 'Theo dõi trạng thái',
                      color: Colors.orange,
                      onTap: () => context.go('/applications'),
                    ),
                    _buildQuickActionCard(
                      context,
                      icon: Icons.favorite,
                      title: 'Việc yêu thích',
                      subtitle: 'Danh sách đã lưu',
                      color: Colors.red,
                      onTap: () => context.go('/favorites'),
                    ),
                    _buildQuickActionCard(
                      context,
                      icon: Icons.business,
                      title: 'Theo dõi công ty',
                      subtitle: 'Các công ty quan tâm',
                      color: Colors.green,
                      onTap: () => context.go('/following'),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Profile Section
            Text(
              'Thông tin cá nhân',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: user?.avatar != null
                          ? NetworkImage(user!.avatar!)
                          : null,
                      child: user?.avatar == null
                          ? Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.blue.shade700,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Unknown User',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/profile'),
                      icon: const Icon(Icons.arrow_forward_ios),
                      tooltip: 'Chỉnh sửa hồ sơ',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Activity Cards
            Text(
              'Hoạt động khác',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final crossAxisCount = screenWidth > 600 ? 3 : 2;
                final childAspectRatio = screenWidth > 600 ? 1.2 : 1.3;
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildActivityCard(
                      context,
                      'Chat',
                      'Tin nhắn với HR',
                      Icons.chat,
                      Colors.blue,
                      () => context.push('/chat'),
                    ),
                    _buildActivityCard(
                      context,
                      'Thông báo',
                      'Cập nhật mới nhất',
                      Icons.notifications,
                      Colors.orange,
                      () => context.push('/notifications'),
                    ),
                    _buildActivityCard(
                      context,
                      'Đánh giá',
                      'Xem đánh giá công ty',
                      Icons.rate_review,
                      Colors.purple,
                      () => context.push('/reviews?showMyReviews=true'),
                    ),
                    _buildActivityCard(
                      context,
                      'Cài đặt',
                      'Tùy chỉnh tài khoản',
                      Icons.settings,
                      Colors.grey,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tính năng đang phát triển')),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            
            // Add bottom padding for better UX
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced padding for mobile
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Important: use minimum space
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 28, // Slightly smaller icon
                  color: color,
                ),
              ),
              const SizedBox(height: 8), // Reduced spacing
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith( // Changed from titleMedium
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1, // Ensure single line
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // Reduced spacing
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11, // Smaller font size
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
