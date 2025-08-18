import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/application_model.dart';
import '../pages/application_detail_page.dart';

class ApplicationListScreen extends ConsumerStatefulWidget {
  final int? jobPostId;

  const ApplicationListScreen({
    super.key,
    this.jobPostId,
  });

  @override
  ConsumerState<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends ConsumerState<ApplicationListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Sample data - Replace with actual provider
  final List<ApplicationModel> _allApplications = [
    ApplicationModel(
      id: 1,
      applicantId: 'user1',
      jobId: 1,
      applicantName: 'Nguyễn Văn An',
      applicantEmail: 'an.nguyen@example.com',
      applicantPhone: '0123456789',
      jobTitle: 'Senior Flutter Developer',
      status: ApplicationStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      appliedAt: DateTime.now().subtract(const Duration(days: 1)),
      coverLetter: 'Tôi có 3 năm kinh nghiệm phát triển ứng dụng mobile với Flutter...',
      cvFileName: 'CV_NguyenVanAn.pdf',
      avatarUrl: 'https://via.placeholder.com/150',
    ),
    ApplicationModel(
      id: 2,
      applicantId: 'user2',
      jobId: 1,
      applicantName: 'Trần Thị Bình',
      applicantEmail: 'binh.tran@example.com',
      applicantPhone: '0987654321',
      jobTitle: 'Senior Flutter Developer',
      status: ApplicationStatus.interviewing,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      appliedAt: DateTime.now().subtract(const Duration(days: 2)),
      coverLetter: 'Tôi rất quan tâm đến vị trí này...',
      cvFileName: 'CV_TranThiBinh.pdf',
    ),
    ApplicationModel(
      id: 3,
      applicantId: 'user3',
      jobId: 1,
      applicantName: 'Lê Minh Châu',
      applicantEmail: 'chau.le@example.com',
      applicantPhone: '0369258147',
      jobTitle: 'Senior Flutter Developer',
      status: ApplicationStatus.accepted,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      appliedAt: DateTime.now().subtract(const Duration(days: 3)),
      coverLetter: 'Với kinh nghiệm 5 năm trong lĩnh vực phát triển ứng dụng...',
      cvFileName: 'CV_LeMinhChau.pdf',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Danh sách ứng viên'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc',
          ),
          IconButton(
            onPressed: _refreshApplications,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tất cả'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_allApplications.length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chờ xử lý'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getApplicationsByStatus(ApplicationStatus.pending).length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Phỏng vấn'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getApplicationsByStatus(ApplicationStatus.interviewing).length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã duyệt'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getApplicationsByStatus(ApplicationStatus.accepted).length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplicationList(_allApplications),
          _buildApplicationList(_getApplicationsByStatus(ApplicationStatus.pending)),
          _buildApplicationList(_getApplicationsByStatus(ApplicationStatus.interviewing)),
          _buildApplicationList(_getApplicationsByStatus(ApplicationStatus.accepted)),
        ],
      ),
    );
  }

  List<ApplicationModel> _getApplicationsByStatus(ApplicationStatus status) {
    return _allApplications.where((app) => app.status == status).toList();
  }

  Widget _buildApplicationList(List<ApplicationModel> applications) {
    if (applications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshApplications,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final application = applications[index];
          return _buildApplicationCard(application);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có ứng viên nào',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các ứng viên sẽ hiển thị ở đây khi họ nộp đơn ứng tuyển',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(ApplicationModel application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToApplicationDetail(application),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue[100],
                      border: Border.all(color: Colors.blue[300]!, width: 1),
                    ),
                    child: application.avatarUrl?.isNotEmpty == true
                        ? ClipOval(
                            child: Image.network(
                              application.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  _buildDefaultAvatar(),
                            ),
                          )
                        : _buildDefaultAvatar(),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.applicantName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.applicantEmail,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(application.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getStatusColor(application.status)),
                    ),
                    child: Text(
                      _getStatusText(application.status),
                      style: TextStyle(
                        color: _getStatusColor(application.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Job Title
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        application.jobTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Cover Letter Preview
              if (application.coverLetter?.isNotEmpty == true) ...[
                Text(
                  'Thư xin việc:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  application.coverLetter!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Bottom Row
              Row(
                children: [
                  // Applied Date
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Nộp đơn: ${_formatDate(application.appliedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // CV File
                  if (application.cvFileName?.isNotEmpty == true) ...[
                    Icon(Icons.description_outlined, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      'CV đính kèm',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _analyzeCV(application),
                      icon: const Icon(Icons.analytics_outlined, size: 16),
                      label: const Text('Phân tích CV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToApplicationDetail(application),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Xem chi tiết'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
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

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 24,
      color: Colors.blue[300],
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
        return 'Chờ xử lý';
      case ApplicationStatus.accepted:
        return 'Đã duyệt';
      case ApplicationStatus.rejected:
        return 'Đã từ chối';
      case ApplicationStatus.interviewing:
        return 'Phỏng vấn';
      case ApplicationStatus.hired:
        return 'Đã tuyển';
      case ApplicationStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _navigateToApplicationDetail(ApplicationModel application) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationDetailPage(application: application),
      ),
    );
  }

  void _analyzeCV(ApplicationModel application) {
    // Show bottom sheet with CV analysis
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationDetailPage(application: application),
      ),
    );
  }

  Future<void> _refreshApplications() async {
    // TODO: Implement refresh logic
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        // Refresh data here
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Job filter
            DropdownButtonFormField<int?>(
              value: widget.jobPostId,
              decoration: const InputDecoration(
                labelText: 'Vị trí tuyển dụng',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả vị trí')),
                // TODO: Add job options
              ],
              onChanged: (value) {},
            ),
            
            const SizedBox(height: 16),
            
            // Date range filter
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Từ ngày',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      // TODO: Show date picker
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Đến ngày',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      // TODO: Show date picker
                    },
                  ),
                ),
              ],
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
              // TODO: Apply filters
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }
}
