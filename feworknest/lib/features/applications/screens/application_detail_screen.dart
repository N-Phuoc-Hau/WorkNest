import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/application_model.dart';
import '../../../core/providers/application_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
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
    final user = authState.user;
    final application = applicationState.selectedApplication;
    final isCandidate = user?.role == 'candidate';
    final isRecruiter = user?.role == 'recruiter';

    if (applicationState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (applicationState.error != null || application == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết ứng tuyển')),
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
                applicationState.error ?? 'Không tìm thấy đơn ứng tuyển',
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
        title: const Text('Chi tiết ứng tuyển'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          if (isCandidate && application.status == ApplicationStatus.pending)
            IconButton(
              onPressed: () => _showEditDialog(application),
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa',
            ),
          if (isRecruiter) ...[
            PopupMenuButton<String>(
              onSelected: (value) => _handleRecruiterAction(value, application),
              itemBuilder: (context) => [
                if (application.status == ApplicationStatus.pending) ...[
                  const PopupMenuItem(
                    value: 'accept',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Chấp nhận'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reject',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Từ chối'),
                      ],
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'chat',
                  child: Row(
                    children: [
                      Icon(Icons.chat, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Nhắn tin'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getStatusColor(application.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        _getStatusIcon(application.status),
                        color: _getStatusColor(application.status),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trạng thái ứng tuyển',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusText(application.status),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(application.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Job Info Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin công việc',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        application.job?.title ?? 'Không có tiêu đề',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        application.job?.recruiter.company?.name ?? 'Không có tên công ty',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          if (application.job?.id != null) {
                            context.push('/job-detail/${application.job!.id}');
                          }
                        },
                        icon: const Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                    if (application.job?.location != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            application.job!.location,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                    if (application.job?.salary != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            '${application.job!.salary.toStringAsFixed(0)} VND',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Application Details Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết ứng tuyển',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Applied Date
                    _buildInfoRow(
                      'Ngày ứng tuyển',
                      application.appliedAt != null 
                          ? _formatDate(application.appliedAt!)
                          : _formatDate(application.createdAt),
                      Icons.calendar_today,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // CV File
                    if (application.cvUrl != null)
                      _buildInfoRow(
                        'CV đính kèm',
                        'Xem CV',
                        Icons.description,
                        onTap: () => _openCV(application.cvUrl!),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Cover Letter
                    if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
                      Text(
                        'Thư giới thiệu',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          application.coverLetter!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rejection Reason (if rejected)
            if (application.status == ApplicationStatus.rejected && application.rejectionReason != null) ...[
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Lý do từ chối',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          application.rejectionReason!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToChat(application),
                    icon: const Icon(Icons.chat),
                    label: Text(isCandidate ? 'Liên hệ HR' : 'Liên hệ ứng viên'),
                  ),
                ),
                if (isCandidate && application.status == ApplicationStatus.pending) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditDialog(application),
                      icon: const Icon(Icons.edit),
                      label: const Text('Chỉnh sửa'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: onTap != null ? Colors.blue : Colors.grey[700],
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.accepted:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
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
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.hourglass_empty;
      case ApplicationStatus.accepted:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openCV(String cvUrl) async {
    try {
      final uri = Uri.parse(cvUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở CV')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
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
          // Refresh application data
          final id = int.tryParse(widget.applicationId) ?? 0;
          ref.read(applicationProvider.notifier).getApplication(id);
        },
      ),
    );
  }

  void _handleRecruiterAction(String action, ApplicationModel application) {
    switch (action) {
      case 'accept':
        _updateStatus(application, ApplicationStatus.accepted);
        break;
      case 'reject':
        _showRejectDialog(application);
        break;
      case 'chat':
        _navigateToChat(application);
        break;
    }
  }

  Future<void> _updateStatus(ApplicationModel application, ApplicationStatus status) async {
    try {
      final success = await ref.read(applicationProvider.notifier).updateApplicationStatus(
        application.id,
        UpdateApplicationStatusModel(status: status.name),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == ApplicationStatus.accepted
                  ? 'Đã chấp nhận ứng viên'
                  : 'Đã từ chối ứng viên',
            ),
            backgroundColor: status == ApplicationStatus.accepted ? Colors.green : Colors.orange,
          ),
        );
        // Refresh data
        final id = int.tryParse(widget.applicationId) ?? 0;
        ref.read(applicationProvider.notifier).getApplication(id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(ApplicationModel application) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối ứng viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn từ chối ứng viên này?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối (tùy chọn)',
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
              _updateStatus(application, ApplicationStatus.rejected);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Navigate to chat with the other party
  Future<void> _navigateToChat(ApplicationModel application) async {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (!authState.isAuthenticated || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần đăng nhập để sử dụng tính năng chat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final job = application.job;
    if (job == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin công việc'),
          backgroundColor: Colors.red,
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
      final roomId = user.role == 'candidate'
          ? await ref.read(chatProvider.notifier).createOrGetChatRoom(
              recruiterId: job.recruiter.id,
              candidateId: user.id,
              jobId: job.id.toString(),
              recruiterInfo: {
                'id': job.recruiter.id,
                'name': '${job.recruiter.firstName} ${job.recruiter.lastName}',
                'avatar': job.recruiter.avatar ?? '',
                'role': 'recruiter',
              },
              candidateInfo: {
                'id': user.id,
                'name': '${user.firstName} ${user.lastName}',
                'avatar': user.avatar ?? '',
                'role': 'candidate',
              },
              jobInfo: {
                'id': job.id.toString(),
                'title': job.title,
                'company': job.recruiter.company?.name ?? 'Unknown Company',
              },
            )
          : await ref.read(chatProvider.notifier).createOrGetChatRoom(
              recruiterId: user.id,
              candidateId: application.applicantId,
              jobId: job.id.toString(),
              recruiterInfo: {
                'id': user.id,
                'name': '${user.firstName} ${user.lastName}',
                'avatar': user.avatar ?? '',
                'role': 'recruiter',
              },
              candidateInfo: {
                'id': application.applicantId,
                'name': application.applicant?.firstName != null
                    ? '${application.applicant!.firstName} ${application.applicant!.lastName}'
                    : application.applicantName,
                'avatar': application.applicant?.avatar ?? '',
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

      if (roomId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              roomId: roomId,
              otherUserName: user.role == 'candidate'
                  ? '${job.recruiter.firstName} ${job.recruiter.lastName}'
                  : application.applicant?.firstName != null
                      ? '${application.applicant!.firstName} ${application.applicant!.lastName}'
                      : application.applicantName,
              otherUserAvatar: user.role == 'candidate'
                  ? job.recruiter.avatar ?? ''
                  : application.applicant?.avatar ?? '',
              jobInfo: {
                'id': job.id.toString(),
                'title': job.title,
                'company': job.recruiter.company?.name ?? 'Unknown Company',
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
