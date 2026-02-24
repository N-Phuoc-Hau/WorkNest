import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../widgets/edit_application_dialog.dart';

class ApplicationDetailScreen extends ConsumerStatefulWidget {
  final String applicationId;

  const ApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  @override
  ConsumerState<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends ConsumerState<ApplicationDetailScreen> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = int.tryParse(widget.applicationId) ?? 0;
      ref.read(applicationProvider.notifier).getApplication(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final applicationState = ref.watch(applicationProvider);
    final authState = ref.watch(authProvider);
    final l10n = ref.watch(localizationsProvider);
    final themeMode = Theme.of(context).brightness;
    final isDark = themeMode == Brightness.dark;

    final user = authState.user;
    final application = applicationState.selectedApplication;
    final isCandidate = user?.role == 'candidate';
    final isRecruiter = user?.role == 'recruiter';

    if (applicationState.isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: AppSpacing.spacing16),
              Text(
                'Đang tải...',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (applicationState.error != null || application == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral50,
        appBar: AppBar(
          title: Text(
            l10n.applicationDetail,
            style: AppTypography.h5.copyWith(
              color: isDark ? AppColors.white : AppColors.neutral900,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isDark ? AppColors.neutral800 : AppColors.white,
          elevation: 0,
        ),
        body: Center(
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
                applicationState.error ?? 'Không tìm thấy đơn ứng tuyển',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.white : AppColors.neutral900,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.spacing24),
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
          // Gradient App Bar
          _buildAppBar(application, l10n, isDark, isCandidate, isRecruiter),
          
          // Content
          SliverPadding(
            padding: EdgeInsets.all(AppSpacing.spacing20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Status Card
                _buildStatusCard(application, l10n, isDark),
                SizedBox(height: AppSpacing.spacing16),
                
                // Job Info Card
                _buildJobInfoCard(application, l10n, isDark),
                SizedBox(height: AppSpacing.spacing16),
                
                // Application Info Card
                _buildApplicationInfoCard(application, l10n, isDark),
                
                // Recruiter view: Applicant Info
                if (isRecruiter) ...[
                  SizedBox(height: AppSpacing.spacing16),
                  _buildApplicantInfoCard(application, l10n, isDark),
                ],
                
                // Rejection reason if rejected
                if (application.status == ApplicationStatus.rejected &&
                    application.rejectionReason != null) ...[
                  SizedBox(height: AppSpacing.spacing16),
                  _buildRejectionCard(application, l10n, isDark),
                ],
                
                SizedBox(height: AppSpacing.spacing24),
                
                // Action buttons
                _buildActionButtons(application, l10n, isDark, isCandidate, isRecruiter),
                
                SizedBox(height: AppSpacing.spacing32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    ApplicationModel application,
    dynamic l10n,
    bool isDark,
    bool isCandidate,
    bool isRecruiter,
  ) {
    final statusText = _getStatusText(application.status);
    
    return SliverAppBar(
      expandedHeight: 160,
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
            left: AppSpacing.spacing48,
            bottom: AppSpacing.spacing16,
            right: AppSpacing.spacing16,
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.applicationDetail,
                style: AppTypography.h6.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.spacing4),
              Text(
                statusText,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
            ],
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
        // Language toggle
        const LanguageToggleButton(isDarkBg: true),
        // Edit button (candidate only, pending status)
        if (isCandidate && application.status == ApplicationStatus.pending) ...[
          IconButton(
            onPressed: () => _showEditDialog(application),
            icon: Container(
              padding: EdgeInsets.all(AppSpacing.spacing8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Icon(
                Icons.edit_rounded,
                color: AppColors.white,
              ),
            ),
            tooltip: l10n.editApplication,
          ),
        ],
        SizedBox(width: AppSpacing.spacing8),
      ],
    );
  }

  Widget _buildStatusCard(ApplicationModel application, dynamic l10n, bool isDark) {
    final statusColor = _getStatusColor(application.status);
    final statusText = _getStatusText(application.status);
    final statusIcon = _getStatusIcon(application.status);
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            child: Icon(
              statusIcon,
              size: 32,
              color: statusColor,
            ),
          ),
          SizedBox(width: AppSpacing.spacing20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.applicationStatus,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                  ),
                ),
                SizedBox(height: AppSpacing.spacing4),
                Text(
                  statusText,
                  style: AppTypography.h5.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfoCard(ApplicationModel application, dynamic l10n, bool isDark) {
    final job = application.job;
    if (job == null) return const SizedBox();

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
          Text(
            l10n.jobInfo,
            style: AppTypography.h6.copyWith(
              color: isDark ? AppColors.white : AppColors.neutral900,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing16),
          
          // Company logo and name
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral700 : AppColors.neutral100,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(
                    color: isDark ? AppColors.neutral600 : AppColors.neutral200,
                  ),
                ),
                child: (job.recruiter.company?.images.isNotEmpty ?? false)
                    ? ClipRRect(
                        borderRadius: AppSpacing.borderRadiusMd,
                        child: Image.network(
                          job.recruiter.company!.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.business_rounded,
                            size: 32,
                            color: AppColors.neutral400,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.business_rounded,
                        size: 32,
                        color: AppColors.neutral400,
                      ),
              ),
              SizedBox(width: AppSpacing.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: AppTypography.h6.copyWith(
                        color: isDark ? AppColors.white : AppColors.neutral900,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.spacing4),
                    Text(
                      job.recruiter.company?.name ?? 'Không có tên công ty',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.spacing16),
          Divider(color: isDark ? AppColors.neutral700 : AppColors.neutral200),
          SizedBox(height: AppSpacing.spacing16),
          
          // Job details
          _buildInfoRow(
            Icons.location_on_rounded,
            l10n.location,
            job.location,
            isDark,
          ),
          SizedBox(height: AppSpacing.spacing12),
          _buildInfoRow(
            Icons.attach_money_rounded,
            l10n.salary,
            _formatSalary(job.salary),
            isDark,
          ),
          SizedBox(height: AppSpacing.spacing12),
          _buildInfoRow(
            Icons.work_outline_rounded,
            l10n.jobType,
            job.jobType ?? 'Không có thông tin',
            isDark,
          ),
          
          SizedBox(height: AppSpacing.spacing16),
          
          // View job button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push('/jobs/${job.id}');
              },
              icon: Icon(Icons.visibility_rounded, size: 18),
              label: Text(l10n.viewJob),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
                side: BorderSide(
                  color: AppColors.primary,
                ),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationInfoCard(ApplicationModel application, dynamic l10n, bool isDark) {
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
          Text(
            l10n.applicationInfo,
            style: AppTypography.h6.copyWith(
              color: isDark ? AppColors.white : AppColors.neutral900,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing16),
          
          // Applied date
          _buildInfoRow(
            Icons.calendar_today_rounded,
            l10n.applicationDate,
            _formatDate(application.createdAt),
            isDark,
          ),
          
          // CV
          if (application.cvUrl != null) ...[
            SizedBox(height: AppSpacing.spacing12),
            Row(
              children: [
                Icon(
                  Icons.description_rounded,
                  size: 20,
                  color: AppColors.neutral500,
                ),
                SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.attachedCV,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacing4),
                      GestureDetector(
                        onTap: () => _openUrl(application.cvUrl!),
                        child: Text(
                          'CV_${application.applicant?.firstName ?? "Candidate"}.pdf',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          
          // Cover Letter
          if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.spacing16),
            Divider(color: isDark ? AppColors.neutral700 : AppColors.neutral200),
            SizedBox(height: AppSpacing.spacing16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.coverLetter,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        _isExpanded ? 'Thu gọn' : 'Xem thêm',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.spacing12),
            
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                application.coverLetter!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                  height: 1.6,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                application.coverLetter!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicantInfoCard(ApplicationModel application, dynamic l10n, bool isDark) {
    final candidate = application.applicant;
    if (candidate == null) return const SizedBox();

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
          Text(
            l10n.applicantInfo,
            style: AppTypography.h6.copyWith(
              color: isDark ? AppColors.white : AppColors.neutral900,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing16),
          
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral700 : AppColors.neutral100,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: candidate.avatar != null
                    ? ClipRRect(
                        borderRadius: AppSpacing.borderRadiusLg,
                        child: Image.network(
                          candidate.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: AppColors.neutral400,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: AppColors.neutral400,
                      ),
              ),
              SizedBox(width: AppSpacing.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${candidate.firstName} ${candidate.lastName}',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? AppColors.white : AppColors.neutral900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacing4),
                    Text(
                      candidate.email,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
        ],
      ),
    );
  }

  Widget _buildRejectionCard(ApplicationModel application, dynamic l10n, bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cancel_rounded,
                color: AppColors.error,
                size: 24,
              ),
              SizedBox(width: AppSpacing.spacing12),
              Text(
                l10n.rejectionReason,
                style: AppTypography.h6.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacing12),
          Text(
            application.rejectionReason!,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    ApplicationModel application,
    dynamic l10n,
    bool isDark,
    bool isCandidate,
    bool isRecruiter,
  ) {
    return Column(
      children: [
        // Candidate actions
        if (isCandidate) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToChat(application),
              icon: Icon(Icons.chat_rounded, size: 20),
              label: Text(l10n.contactRecruiter),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                elevation: 0,
              ),
            ),
          ),
          
          if (application.status == ApplicationStatus.pending) ...[
            SizedBox(height: AppSpacing.spacing12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmWithdraw(application),
                icon: Icon(Icons.cancel_outlined, size: 20),
                label: Text(l10n.withdrawApplication),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                  side: BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                ),
              ),
            ),
          ],
        ],
        
        // Recruiter actions
        if (isRecruiter) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToChat(application),
                  icon: Icon(Icons.chat_rounded, size: 20),
                  label: Text(l10n.contactCandidate),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          
          if (application.status == ApplicationStatus.pending) ...[
            SizedBox(height: AppSpacing.spacing12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmAccept(application),
                    icon: Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(l10n.acceptApplication),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(application),
                    icon: Icon(Icons.cancel_rounded, size: 20),
                    label: Text(l10n.rejectApplication),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                      side: BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.spacing12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showScheduleDialog(application),
                icon: Icon(Icons.event_rounded, size: 20),
                label: Text(l10n.scheduleInterview),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
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
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.neutral500,
        ),
        SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
              SizedBox(height: AppSpacing.spacing4),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.white : AppColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
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

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.access_time_rounded;
      case ApplicationStatus.accepted:
        return Icons.check_circle_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
      case ApplicationStatus.interviewing:
        return Icons.people_rounded;
      case ApplicationStatus.hired:
        return Icons.celebration_rounded;
      case ApplicationStatus.cancelled:
        return Icons.block_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatSalary(double salary) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return '${formatter.format(salary)} VNĐ';
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể mở link: $url'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
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

  void _showEditDialog(ApplicationModel application) {
    showDialog(
      context: context,
      builder: (context) => EditApplicationDialog(
        application: application,
        onUpdated: () {
          final id = int.tryParse(widget.applicationId) ?? 0;
          ref.read(applicationProvider.notifier).getApplication(id);
        },
      ),
    );
  }

  void _confirmAccept(ApplicationModel application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chấp nhận ứng tuyển'),
        content: const Text('Bạn có chắc chắn muốn chấp nhận đơn ứng tuyển này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(applicationProvider.notifier).updateApplicationStatus(
                    application.id,
                    UpdateApplicationStatusModel(
                      status: 'accepted',
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Chấp nhận'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(ApplicationModel application) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối ứng tuyển'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn có chắc chắn muốn từ chối đơn ứng tuyển này?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối (tùy chọn)',
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(applicationProvider.notifier).updateApplicationStatus(
                    application.id,
                    UpdateApplicationStatusModel(
                      status: 'rejected',
                      rejectionReason: reasonController.text.trim().isEmpty
                          ? null
                          : reasonController.text.trim(),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(ApplicationModel application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lên lịch phỏng vấn'),
        content: const Text('Tính năng này đang được phát triển.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _confirmWithdraw(ApplicationModel application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rút đơn ứng tuyển'),
        content: const Text('Bạn có chắc chắn muốn rút đơn ứng tuyển này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(applicationProvider.notifier).updateApplicationStatus(
                    application.id,
                    UpdateApplicationStatusModel(
                      status: 'cancelled',
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Rút đơn'),
          ),
        ],
      ),
    );
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
    final candidate = application.applicant;
    if (job == null || candidate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không tìm thấy thông tin ứng viên hoặc công việc'),
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
      final isRecruiter = currentUser.role == 'recruiter';

      final roomId = await ref.read(chatProvider.notifier).createOrGetChatRoom(
        recruiterId: job.recruiter.id,
        candidateId: candidate.id,
        jobId: job.id.toString(),
        recruiterInfo: {
          'id': job.recruiter.id,
          'name': '${job.recruiter.firstName} ${job.recruiter.lastName}',
          'avatar': job.recruiter.avatar ?? '',
          'role': 'recruiter',
        },
        candidateInfo: {
          'id': candidate.id,
          'name': '${candidate.firstName} ${candidate.lastName}',
          'avatar': candidate.avatar ?? '',
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
                otherUserName: isRecruiter
                    ? '${candidate.firstName} ${candidate.lastName}'
                    : '${job.recruiter.firstName} ${job.recruiter.lastName}',
                otherUserAvatar: isRecruiter
                    ? (candidate.avatar ?? '')
                    : (job.recruiter.avatar ?? ''),
                jobInfo: {
                  'id': job.id.toString(),
                  'title': job.title,
                  'company': job.recruiter.company?.name ?? 'Unknown Company',
                },
                recruiterInfo: {
                  'id': job.recruiter.id,
                  'name': '${job.recruiter.firstName} ${job.recruiter.lastName}',
                  'avatar': job.recruiter.avatar ?? '',
                  'role': 'recruiter',
                },
                candidateInfo: {
                  'id': candidate.id,
                  'name': '${candidate.firstName} ${candidate.lastName}',
                  'avatar': candidate.avatar ?? '',
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
