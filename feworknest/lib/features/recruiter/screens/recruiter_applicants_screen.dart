import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/application_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/recruiter_applicants_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../chat/screens/real_chat_screen.dart';
import '../../chat/screens/simple_chat_screen.dart';

class RecruiterApplicantsScreen extends ConsumerStatefulWidget {
  const RecruiterApplicantsScreen({super.key});

  @override
  ConsumerState<RecruiterApplicantsScreen> createState() => _RecruiterApplicantsScreenState();
}

class _RecruiterApplicantsScreenState extends ConsumerState<RecruiterApplicantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  int? _selectedJobId; // Changed to nullable to support "all jobs"

  @override
  void initState() {
    super.initState();
    // Load applicants when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ ứng viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
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
                            Text(
                              'Lỗi: ${applicantsState.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: applicant.applicant?.avatar != null 
                      ? NetworkImage(applicant.applicant!.avatar!)
                      : null,
                  child: applicant.applicant?.avatar == null
                      ? Text(
                          applicant.applicantName.isNotEmpty 
                              ? applicant.applicantName.substring(0, 1).toUpperCase()
                              : 'A',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.applicantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        applicant.applicant?.position ?? 'Chưa cập nhật',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        applicant.jobTitle,
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(applicant.status.name),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(applicant.status.name),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.work, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Kinh nghiệm: ${applicant.applicant?.experience ?? 'Chưa cập nhật'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.school, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  applicant.applicant?.education ?? 'Chưa cập nhật',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Độ phù hợp: 85%', // TODO: Calculate match rate
                  style: TextStyle(
                    color: _getMatchRateColor(85),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Ứng tuyển: ${_formatDate(applicant.appliedDate)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleApplicantAction('view', applicant),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Xem hồ sơ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startChatWithApplicant(applicant),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Nhắn tin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _handleApplicantAction('more', applicant),
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xem xét';
      case 'accepted':
        return 'Đã chấp nhận';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Unknown';
    }
  }

  Color _getMatchRateColor(int matchRate) {
    if (matchRate >= 90) {
      return Colors.green;
    } else if (matchRate >= 80) {
      return Colors.blue;
    } else if (matchRate >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  void _handleApplicantAction(String action, ApplicationModel applicant) {
    switch (action) {
      case 'view':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xem hồ sơ: ${applicant.applicantName}')),
        );
        break;
      case 'contact':
        _startChatWithApplicant(applicant);
        break;
      case 'more':
        _showMoreOptionsDialog(applicant);
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
      print('DEBUG: Current user - ID: ${currentUser.id}, Role: ${currentUser.role}');
      
      // Prepare detailed info for Firebase
      final recruiterInfo = {
        'id': currentUser.id,
        'name': '${currentUser.firstName} ${currentUser.lastName}'.trim(),
        'email': currentUser.email,
        'avatar': currentUser.avatar,
        'role': currentUser.role,
      };

      final candidateInfo = {
        'id': applicant.applicantId,
        'name': applicant.applicantName,
        'email': applicant.applicant?.email ?? '',
        'avatar': applicant.applicant?.avatar,
        'role': 'candidate',
      };

      final jobInfo = {
        'id': applicant.jobId.toString(),
        'title': applicant.job?.title ?? 'Không rõ',
        'company': applicant.job?.recruiter.company?.name ?? 'Không rõ',
      };

      print('DEBUG: Prepared detailed info for Firebase');

      try {
        // Try Firebase first with connection test
        print('DEBUG: Attempting Firebase chat creation...');
        
        // Test Firebase connection first
        final chatService = ref.read(chatServiceProvider);
        final isConnected = await chatService.testConnection().timeout(
          const Duration(seconds: 3), // Giảm timeout xuống 3 giây
          onTimeout: () {
            print('DEBUG: Firebase connection test timeout after 3 seconds');
            return false;
          },
        );

        if (!isConnected) {
          print('DEBUG: Firebase not connected, falling back to simple chat immediately');
          throw Exception('Firebase not connected - quick fallback');
        }

        print('DEBUG: Firebase connection OK, creating chat room...');
        
        final chatNotifier = ref.read(chatProvider({
          'userId': currentUser.id,
          'userType': currentUser.role.toLowerCase(),
        }).notifier);

        final roomId = await chatNotifier.createOrGetChatRoom(
          recruiterId: currentUser.id,
          candidateId: applicant.applicantId,
          jobId: applicant.jobId.toString(),
          recruiterInfo: recruiterInfo,
          candidateInfo: candidateInfo,
          jobInfo: jobInfo,
        ).timeout(
          const Duration(seconds: 8), // Giảm timeout room creation
          onTimeout: () {
            print('DEBUG: Firebase room creation timeout after 8 seconds, falling back to simple chat');
            throw Exception('Firebase room creation timeout');
          },
        );

        print('DEBUG: Firebase chat room created successfully - Room ID: $roomId');

        // Close loading dialog
        LoadingDialog.hide(context);

        // Navigate to Firebase chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RealChatScreen(
              roomId: roomId,
              otherUserInfo: candidateInfo,
              jobInfo: jobInfo,
            ),
          ),
        );

        NotificationHelper.showSuccess(
          context,
          'Đã tạo cuộc trò chuyện Firebase với ${applicant.applicantName}',
        );

      } catch (firebaseError) {
        print('DEBUG: Firebase error: $firebaseError, falling back to simple chat');
        
        // Fallback to simple chat
        final simpleRoomId = '${currentUser.id}_${applicant.applicantId}_${applicant.jobId}';
        print('DEBUG: Using simple room ID: $simpleRoomId');

        // Close loading dialog
        LoadingDialog.hide(context);

        // Navigate to simple chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleChatScreen(
              roomId: simpleRoomId,
              otherUserInfo: candidateInfo,
              jobInfo: jobInfo,
            ),
          ),
        );

        NotificationHelper.showWarning(
          context,
          'Đã tạo cuộc trò chuyện test với ${applicant.applicantName}',
        );
      }

    } catch (e) {
      print('DEBUG: General error occurred - ${e.toString()}');
      
      LoadingDialog.hide(context);
      
      NotificationHelper.showError(
        context,
        'Lỗi khi tạo cuộc trò chuyện: ${e.toString()}',
      );
    }
  }

  void _showMoreOptionsDialog(ApplicationModel applicant) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Nhắn tin'),
              onTap: () {
                Navigator.pop(context);
                _startChatWithApplicant(applicant);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Tải CV'),
              onTap: () {
                Navigator.pop(context);
                _downloadCV(applicant);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Lên lịch phỏng vấn'),
              onTap: () {
                Navigator.pop(context);
                _scheduleInterview(applicant);
              },
            ),
            if (applicant.status == ApplicationStatus.pending) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Chấp nhận', style: TextStyle(color: Colors.green)),
                onTap: () {
                  Navigator.pop(context);
                  _updateApplicationStatus(applicant, 'accepted');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showRejectionDialog(applicant);
                },
              ),
            ],
          ],
        ),
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
    // TODO: Implement interview scheduling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lên lịch phỏng vấn: ${applicant.applicantName}')),
    );
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