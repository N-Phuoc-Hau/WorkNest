import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/application_model.dart';
import '../../../core/providers/application_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/language_toggle_widget.dart';
import '../../chat/screens/chat_detail_screen.dart';

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(applicationProvider.notifier).getMyApplications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicationState = ref.watch(applicationProvider);
    final l10n = ref.watch(localizationsProvider);
    final themeMode = Theme.of(context).brightness;
    final isDark = themeMode == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral50,
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          _buildAppBar(l10n, isDark),
          
          // Search and Filter Section
          SliverToBoxAdapter(
            child: _buildSearchAndFilter(l10n, isDark),
          ),
          
          // Applications List
          _buildApplicationsList(applicationState, l10n, isDark),
        ],
      ),
    );
  }

  Widget _buildAppBar(dynamic l10n, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
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
            left: AppSpacing.spacing20,
            bottom: AppSpacing.spacing16,
          ),
          title: Text(
            l10n.myApplications,
            style: AppTypography.h4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      actions: [
        // Refresh button
        IconButton(
          onPressed: () {
            ref.read(applicationProvider.notifier).getMyApplications();
          },
          icon: Container(
            padding: EdgeInsets.all(AppSpacing.spacing8),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              Icons.refresh_rounded,
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

  Widget _buildSearchAndFilter(dynamic l10n, bool isDark) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.spacing20),
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
          Text(
            l10n.searchApplications,
            style: AppTypography.h6.copyWith(
              color: isDark ? AppColors.white : AppColors.neutral900,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing16),
          
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {});
            },
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.white : AppColors.neutral900,
            ),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên công việc hoặc công ty...',
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.neutral500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: isDark ? AppColors.neutral700 : AppColors.neutral50,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacing16),
          
          // Filter chips
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: [
              _buildFilterChip(
                label: l10n.allApplications,
                value: 'all',
                isDark: isDark,
              ),
              _buildFilterChip(
                label: l10n.pending,
                value: 'pending',
                isDark: isDark,
              ),
              _buildFilterChip(
                label: l10n.accepted,
                value: 'accepted',
                isDark: isDark,
              ),
              _buildFilterChip(
                label: l10n.rejected,
                value: 'rejected',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: isDark ? AppColors.neutral700 : AppColors.neutral100,
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.white,
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: isSelected
            ? AppColors.white
            : (isDark ? AppColors.neutral300 : AppColors.neutral700),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.neutral600 : AppColors.neutral300),
      ),
    );
  }

  Widget _buildApplicationsList(dynamic applicationState, dynamic l10n, bool isDark) {
    if (applicationState.isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: AppSpacing.spacing16),
              Text(
                'Đang tải ứng tuyển...',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (applicationState.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              SizedBox(height: AppSpacing.spacing16),
              Text(
                'Lỗi: ${applicationState.error}',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.white : AppColors.neutral900,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.spacing16),
              ElevatedButton(
                onPressed: () {
                  ref.read(applicationProvider.notifier).getMyApplications();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredApplications = _getFilteredApplications(
      applicationState.myApplications,
    );

    if (filteredApplications.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_off_rounded,
                size: 64,
                color: AppColors.neutral400,
              ),
              SizedBox(height: AppSpacing.spacing16),
              Text(
                l10n.noApplicationsFound,
                style: AppTypography.h6.copyWith(
                  color: isDark ? AppColors.white : AppColors.neutral900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.spacing8),
              Text(
                l10n.startApplyingNow,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
              SizedBox(height: AppSpacing.spacing24),
              ElevatedButton(
                onPressed: () => context.push('/jobs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing32,
                    vertical: AppSpacing.spacing16,
                  ),
                ),
                child: Text(l10n.findJobs),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final application = filteredApplications[index];
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.spacing16),
              child: _buildApplicationCard(application, l10n, isDark),
            );
          },
          childCount: filteredApplications.length,
        ),
      ),
    );
  }

  Widget _buildApplicationCard(ApplicationModel application, dynamic l10n, bool isDark) {
    final statusColor = _getStatusColor(application.status);
    final statusText = _getStatusText(application.status);
    
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
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.job?.title ?? 'Không có tiêu đề',
                        style: AppTypography.h6.copyWith(
                          color: isDark ? AppColors.white : AppColors.neutral900,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacing.spacing4),
                      Text(
                        application.job?.recruiter.company?.name ?? 'Không có tên công ty',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.spacing12),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing12,
                    vertical: AppSpacing.spacing6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: AppSpacing.borderRadiusLg,
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: AppTypography.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppSpacing.spacing16),
            
            // Info row
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.neutral500,
                ),
                SizedBox(width: AppSpacing.spacing8),
                Expanded(
                  child: Text(
                    '${l10n.applicationDate}: ${_formatDate(application.createdAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
                if (application.cvUrl != null) ...[
                  Icon(
                    Icons.attachment_rounded,
                    size: 16,
                    color: AppColors.neutral500,
                  ),
                  SizedBox(width: AppSpacing.spacing4),
                  Text(
                    l10n.attachedCV,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ],
            ),
            
            // Rejection reason if rejected
            if (application.status == ApplicationStatus.rejected &&
                application.rejectionReason != null) ...[
              SizedBox(height: AppSpacing.spacing12),
              Container(
                padding: EdgeInsets.all(AppSpacing.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    SizedBox(width: AppSpacing.spacing8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.rejectionReason,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSpacing.spacing4),
                          Text(
                            application.rejectionReason!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: AppSpacing.spacing16),
            
            // Action buttons
            Column(
              children: [
                // First row: View Detail button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/application/${application.id}');
                    },
                    icon: Icon(Icons.description_rounded, size: 18),
                    label: Text(l10n.viewDetail),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.spacing12,
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.spacing8),
                // Second row: View Job and Contact buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (application.job?.id != null) {
                            context.push('/jobs/${application.job!.id}');
                          }
                        },
                        icon: Icon(Icons.work_outline_rounded, size: 18),
                        label: Text(l10n.viewJob),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.spacing12,
                          ),
                          side: BorderSide(
                            color: isDark ? AppColors.neutral600 : AppColors.neutral300,
                          ),
                          foregroundColor: isDark ? AppColors.white : AppColors.neutral900,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacing12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToChat(application),
                        icon: Icon(Icons.chat_rounded, size: 18),
                        label: Text(l10n.contactRecruiter),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.spacing12,
                          ),
                          side: BorderSide(
                            color: isDark ? AppColors.neutral600 : AppColors.neutral300,
                          ),
                          foregroundColor: isDark ? AppColors.white : AppColors.neutral900,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
    );
  }

  List<ApplicationModel> _getFilteredApplications(List<ApplicationModel> applications) {
    var filtered = applications;
    
    // Filter by status
    if (_selectedFilter != 'all') {
      final status = _getStatusFromFilter(_selectedFilter);
      filtered = filtered.where((app) => app.status == status).toList();
    }
    
    // Filter by search text
    final searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((app) {
        final jobTitle = app.job?.title.toLowerCase() ?? '';
        final companyName = app.job?.recruiter.company?.name.toLowerCase() ?? '';
        return jobTitle.contains(searchText) || companyName.contains(searchText);
      }).toList();
    }
    
    return filtered;
  }

  ApplicationStatus _getStatusFromFilter(String filter) {
    switch (filter) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.pending;
    }
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.accepted:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.interviewing:
        return AppColors.info;
      case ApplicationStatus.hired:
        return AppColors.primary;
      case ApplicationStatus.cancelled:
        return AppColors.neutral500;
    }
  }

  String _getStatusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Chờ xem xét';
      case ApplicationStatus.accepted:
        return 'Đã chấp nhận';
      case ApplicationStatus.rejected:
        return 'Từ chối';
      case ApplicationStatus.interviewing:
        return 'Đang phỏng vấn';
      case ApplicationStatus.hired:
        return 'Đã được nhận';
      case ApplicationStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _navigateToChat(ApplicationModel application) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bạn cần đăng nhập để sử dụng tính năng chat'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final job = application.job;
    if (job == null || job.recruiter.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không tìm thấy thông tin nhà tuyển dụng'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Đang tạo phòng chat...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final currentUser = authState.user!;

      final roomId = await ref.read(chatProvider.notifier).createOrGetChatRoom(
        recruiterId: job.recruiter.id,
        candidateId: currentUser.id,
        jobId: job.id.toString(),
        recruiterInfo: {
          'id': job.recruiter.id,
          'name': '${job.recruiter.firstName} ${job.recruiter.lastName}',
          'avatar': job.recruiter.avatar ?? '',
          'role': 'recruiter',
        },
        candidateInfo: {
          'id': currentUser.id,
          'name': '${currentUser.firstName} ${currentUser.lastName}',
          'avatar': currentUser.avatar ?? '',
          'role': 'candidate',
        },
        jobInfo: {
          'id': job.id.toString(),
          'title': job.title,
          'company': job.recruiter.company?.name ?? 'Unknown Company',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (roomId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã tạo phòng chat thành công'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                roomId: roomId,
                otherUserName:
                    '${job.recruiter.firstName} ${job.recruiter.lastName}',
                otherUserAvatar: job.recruiter.avatar ?? '',
                jobInfo: {
                  'id': job.id.toString(),
                  'title': job.title,
                  'company': job.recruiter.company?.name ?? 'Unknown Company',
                },
                recruiterInfo: {
                  'id': job.recruiter.id,
                  'name':
                      '${job.recruiter.firstName} ${job.recruiter.lastName}',
                  'avatar': job.recruiter.avatar ?? '',
                  'role': 'recruiter',
                },
                candidateInfo: {
                  'id': currentUser.id,
                  'name': '${currentUser.firstName} ${currentUser.lastName}',
                  'avatar': currentUser.avatar ?? '',
                  'role': 'candidate',
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không thể tạo phòng chat. Vui lòng thử lại sau.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
