import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/application_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/recruiter_applicants_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../chat/screens/chat_detail_screen.dart';

class RecruiterApplicantsScreen extends ConsumerStatefulWidget {
  const RecruiterApplicantsScreen({super.key});

  @override
  ConsumerState<RecruiterApplicantsScreen> createState() => _RecruiterApplicantsScreenState();
}

class _RecruiterApplicantsScreenState extends ConsumerState<RecruiterApplicantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  int? _selectedJobId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('DEBUG RecruiterApplicantsScreen: initState - calling loadJobApplicants with _selectedJobId: $_selectedJobId');
      ref.read(recruiterApplicantsProvider.notifier).loadJobApplicants(_selectedJobId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicantsState = ref.watch(recruiterApplicantsProvider);

    // Debug logging
    print('DEBUG RecruiterApplicantsScreen: Building UI with state:');
    print('  - isLoading: ${applicantsState.isLoading}');
    print('  - error: ${applicantsState.error}');
    print('  - applicants count: ${applicantsState.applicants.length}');
    print('  - totalCount: ${applicantsState.totalCount}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ ứng viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('DEBUG RecruiterApplicantsScreen: refresh button - calling loadJobApplicants with _selectedJobId: $_selectedJobId');
              ref.read(recruiterApplicantsProvider.notifier).loadJobApplicants(_selectedJobId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Statistics
          if (applicantsState.applicants.isNotEmpty)
            _buildSummaryStatistics(applicantsState),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ứng viên...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                ref.read(recruiterApplicantsProvider.notifier).searchApplicants(
                  _selectedJobId,
                  search: value.isEmpty ? null : value,
                  status: _selectedFilter == 'all' ? null : _selectedFilter,
                );
              },
            ),
          ),
          
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: _selectedFilter == 'all',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'all';
                      });
                      ref.read(recruiterApplicantsProvider.notifier).searchApplicants(
                        _selectedJobId,
                        status: null,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Chờ xem xét'),
                    selected: _selectedFilter == 'pending',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'pending';
                      });
                      ref.read(recruiterApplicantsProvider.notifier).searchApplicants(
                        _selectedJobId,
                        status: 'pending',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Đã chấp nhận'),
                    selected: _selectedFilter == 'accepted',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'accepted';
                      });
                      ref.read(recruiterApplicantsProvider.notifier).searchApplicants(
                        _selectedJobId,
                        status: 'accepted',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Từ chối'),
                    selected: _selectedFilter == 'rejected',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'rejected';
                      });
                      ref.read(recruiterApplicantsProvider.notifier).searchApplicants(
                        _selectedJobId,
                        status: 'rejected',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Applicants List
          Expanded(
            child: applicantsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : applicantsState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Lỗi: ${applicantsState.error}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'DEBUG: Error occurred after parsing ${applicantsState.applicants.length} items',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                print('DEBUG RecruiterApplicantsScreen: Retry button pressed');
                                ref.read(recruiterApplicantsProvider.notifier).loadJobApplicants(_selectedJobId);
                              },
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : applicantsState.applicants.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Chưa có ứng viên nào',
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ứng viên sẽ xuất hiện ở đây khi họ ứng tuyển',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: applicantsState.applicants.length,
                            itemBuilder: (context, index) {
                              final applicant = applicantsState.applicants[index];
                              return _buildApplicantCard(applicant);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatistics(RecruiterApplicantsState state) {
    final totalApplications = state.totalCount;
    final pendingCount = state.applicants.where((app) => app.status == ApplicationStatus.pending).length;
    final acceptedCount = state.applicants.where((app) => app.status == ApplicationStatus.accepted).length;
    final rejectedCount = state.applicants.where((app) => app.status == ApplicationStatus.rejected).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê tổng quan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Tổng cộng', totalApplications.toString(), Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Chờ xem xét', pendingCount.toString(), Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Đã chấp nhận', acceptedCount.toString(), Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Từ chối', rejectedCount.toString(), Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(ApplicationModel applicant) {
    // Get applicant name - using firstName + lastName from the API response
    final applicantName = '${applicant.applicant?.firstName ?? ''} ${applicant.applicant?.lastName ?? ''}'.trim();
    final displayName = applicantName.isNotEmpty ? applicantName : applicant.applicantName;
    
    // Get applicant email from the nested applicant object
    final applicantEmail = applicant.applicant?.email ?? applicant.applicantEmail;
    
    // Get avatar from the nested applicant object  
    final avatarUrl = applicant.applicant?.avatar ?? applicant.avatarUrl;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewApplicantDetail(applicant),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Avatar, Name, and Status
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: avatarUrl?.isNotEmpty == true 
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl?.isEmpty ?? true
                        ? Text(
                            displayName.isNotEmpty 
                                ? displayName.substring(0, 1).toUpperCase()
                                : 'A',
                            style: TextStyle(
                              color: Colors.blue[800],
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
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          applicantEmail.isNotEmpty 
                              ? applicantEmail 
                              : 'Email chưa cập nhật',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ứng tuyển: ${applicant.job?.title ?? applicant.jobTitle}',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(applicant.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(applicant.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(applicant.status),
                      style: TextStyle(
                        color: _getStatusColor(applicant.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Application Details
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Ứng tuyển: ${_formatDate(applicant.appliedAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const Spacer(),
                  if (applicant.cvUrl?.isNotEmpty == true) ...[
                    Icon(Icons.attach_file, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Có CV',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.error_outline, size: 16, color: Colors.orange[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Chưa có CV',
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Company info if available
              if (applicant.job?.recruiter.company?.name != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Công ty: ${applicant.job!.recruiter.company!.name}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _viewApplicantDetail(applicant),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Xem chi tiết'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _startChatWithApplicant(applicant),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Nhắn tin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleApplicantAction(value, applicant),
                    itemBuilder: (context) => [
                      if (applicant.status == ApplicationStatus.pending) ...[
                        const PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Phê duyệt'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Từ chối'),
                            ],
                          ),
                        ),
                      ],
                      if (applicant.cvUrl?.isNotEmpty == true)
                        const PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(Icons.download),
                              SizedBox(width: 8),
                              Text('Tải CV'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'schedule',
                        child: Row(
                          children: [
                            Icon(Icons.schedule),
                            SizedBox(width: 8),
                            Text('Lên lịch phỏng vấn'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.more_vert),
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

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.accepted:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
      case ApplicationStatus.interviewing:
        return Colors.blue;
      case ApplicationStatus.hired:
        return Colors.purple;
      case ApplicationStatus.cancelled:
        return Colors.grey;
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
        return 'Phỏng vấn';
      case ApplicationStatus.hired:
        return 'Đã tuyển';
      case ApplicationStatus.cancelled:
        return 'Đã hủy';
    }
  }

  void _viewApplicantDetail(ApplicationModel applicant) {
    context.go('/recruiter/applicant/${applicant.id}');
  }

  void _handleApplicantAction(String action, ApplicationModel applicant) {
    switch (action) {
      case 'approve':
        _updateApplicationStatus(applicant, 'accepted');
        break;
      case 'reject':
        _showRejectionDialog(applicant);
        break;
      case 'download':
        _downloadCV(applicant);
        break;
      case 'schedule':
        _scheduleInterview(applicant);
        break;
    }
  }

  Future<void> _startChatWithApplicant(ApplicationModel applicant) async {
    LoadingDialog.show(context, message: 'Đang tạo cuộc trò chuyện...');
    
    try {
      print('DEBUG: Starting chat with applicant: ${applicant.applicantName}');
      
      // Get current user info
      final authState = ref.read(authProvider);
      print('DEBUG: Auth state - user: ${authState.user?.id}');
      
      if (authState.user == null) {
        LoadingDialog.hide(context);
        NotificationHelper.showError(
          context, 
          'Vui lòng đăng nhập để sử dụng tính năng này'
        );
        return;
      }

      final currentUser = authState.user!;
      final applicantName = '${applicant.applicant?.firstName ?? ''} ${applicant.applicant?.lastName ?? ''}'.trim();
      final displayName = applicantName.isNotEmpty ? applicantName : applicant.applicantName;
      
      // Prepare info for chat
      final jobInfo = {
        'id': applicant.jobId.toString(),
        'title': applicant.job?.title ?? applicant.jobTitle,
        'company': applicant.job?.recruiter.company?.name ?? 'Không rõ',
      };

      // Create simple room ID
      final roomId = '${currentUser.id}_${applicant.applicantId}_${applicant.jobId}';

      // Close loading dialog
      LoadingDialog.hide(context);

      // Navigate directly to ChatDetailScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            roomId: roomId,
            otherUserName: displayName,
            otherUserAvatar: applicant.applicant?.avatar ?? applicant.avatarUrl ?? '',
            jobInfo: jobInfo,
          ),
        ),
      );

      NotificationHelper.showSuccess(
        context,
        'Bắt đầu cuộc trò chuyện với $displayName',
      );

    } catch (e) {
      print('DEBUG: Error occurred - ${e.toString()}');
      
      LoadingDialog.hide(context);
      
      NotificationHelper.showError(
        context,
        'Lỗi khi tạo cuộc trò chuyện: ${e.toString()}',
      );
    }
  }

  void _updateApplicationStatus(ApplicationModel applicant, String status) async {
    try {
      final updateStatus = UpdateApplicationStatusModel(status: status);
      final success = await ref.read(recruiterApplicantsProvider.notifier)
          .updateApplicantStatus(applicant.id, updateStatus);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ${status == 'accepted' ? 'chấp nhận' : 'từ chối'} ứng viên: ${applicant.applicantName}'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
        // Refresh the list after updating status
        ref.read(recruiterApplicantsProvider.notifier).loadJobApplicants(_selectedJobId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi cập nhật trạng thái'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectionDialog(ApplicationModel applicant) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối ứng viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn từ chối ${applicant.applicantName}?'),
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
              _updateApplicationStatus(applicant, 'rejected');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _downloadCV(ApplicationModel applicant) {
    if (applicant.cvUrl != null) {
      // TODO: Implement CV download
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải CV: ${applicant.applicantName}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có CV để tải')),
      );
    }
  }

  void _scheduleInterview(ApplicationModel applicant) {
    // Navigate to schedule interview screen
    context.push(
      '/recruiter/schedule-interview/${applicant.id}',
      extra: applicant,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc nâng cao'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tính năng bộ lọc nâng cao đang phát triển...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
