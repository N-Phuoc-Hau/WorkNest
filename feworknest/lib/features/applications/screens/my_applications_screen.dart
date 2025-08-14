import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/application_model.dart';
import '../../../core/providers/application_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../chat/screens/chat_detail_screen.dart';

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Load applications when screen initializes
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ứng tuyển của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(applicationProvider.notifier).getMyApplications();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm ứng tuyển...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      // TODO: Implement search functionality
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'pending', child: Text('Chờ xem xét')),
                    DropdownMenuItem(value: 'accepted', child: Text('Đã chấp nhận')),
                    DropdownMenuItem(value: 'rejected', child: Text('Từ chối')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Applications List
          Expanded(
            child: applicationState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : applicationState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lỗi: ${applicationState.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(applicationProvider.notifier).getMyApplications();
                              },
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : applicationState.myApplications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Bạn chưa có ứng tuyển nào',
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Hãy tìm kiếm và ứng tuyển công việc phù hợp',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _getFilteredApplications(applicationState.myApplications).length,
                            itemBuilder: (context, index) {
                              final application = _getFilteredApplications(applicationState.myApplications)[index];
                              return _buildApplicationCard(application);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  List<ApplicationModel> _getFilteredApplications(List<ApplicationModel> applications) {
    if (_selectedFilter == 'all') {
      return applications;
    }
    
    final status = _getStatusFromFilter(_selectedFilter);
    return applications.where((app) => app.status == status).toList();
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

  Widget _buildApplicationCard(ApplicationModel application) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          context.push('/application/${application.id}');
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.job?.title ?? 'Không có tiêu đề',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.job?.recruiter.company?.name ?? 'Không có tên công ty',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(application.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(application.status),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Ứng tuyển: ${application.appliedAt != null ? _formatDate(application.appliedAt!) : _formatDate(application.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (application.cvUrl != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.attachment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'CV đính kèm',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
            
            if (application.status == ApplicationStatus.rejected && application.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lý do từ chối:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      application.rejectionReason!,
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (application.job?.id != null) {
                        context.push('/job-detail/${application.job!.id}');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không tìm thấy thông tin công việc')),
                        );
                      }
                    },
                    child: const Text('Xem chi tiết'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToChat(application),
                    child: const Text('Liên hệ'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Navigate to chat with recruiter
  Future<void> _navigateToChat(ApplicationModel application) async {
    // Check authentication
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần đăng nhập để sử dụng tính năng chat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if job and recruiter info exists
    final job = application.job;
    if (job == null || job.recruiter.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin nhà tuyển dụng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
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
      
      // Create or get chat room
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

      // Clear loading
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (roomId != null) {
        // Success notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tạo phòng chat thành công'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Navigate to chat detail
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                roomId: roomId,
                otherUserName: '${job.recruiter.firstName} ${job.recruiter.lastName}',
                otherUserAvatar: job.recruiter.avatar ?? '',
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
        // Failed to create room
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tạo phòng chat. Vui lòng thử lại sau.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Clear loading
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
      
      // Show error
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
}
