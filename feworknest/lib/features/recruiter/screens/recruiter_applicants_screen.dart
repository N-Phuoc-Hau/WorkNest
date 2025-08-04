import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/recruiter_applicants_provider.dart';
import '../../../core/models/application_model.dart';

class RecruiterApplicantsScreen extends ConsumerStatefulWidget {
  const RecruiterApplicantsScreen({super.key});

  @override
  ConsumerState<RecruiterApplicantsScreen> createState() => _RecruiterApplicantsScreenState();
}

class _RecruiterApplicantsScreenState extends ConsumerState<RecruiterApplicantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  int _selectedJobId = 1; // TODO: Get from navigation or state

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
                  child: Text(
                    applicant.applicant?.avatar?.substring(0, 1).toUpperCase() ?? 'A',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
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
                        applicant.applicant?.position ?? 'Unknown Position',
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
                  'Kinh nghiệm: ${applicant.applicant?.experience ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.school, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  applicant.applicant?.education ?? 'N/A',
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
                    onPressed: () => _handleApplicantAction('contact', applicant),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Liên hệ'),
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
    switch (status) {
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
    switch (status) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Liên hệ: ${applicant.applicantName}')),
        );
        break;
      case 'more':
        _showMoreOptionsDialog(applicant);
        break;
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
              leading: const Icon(Icons.download),
              title: const Text('Tải CV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tải CV: ${applicant.applicantName}')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Lên lịch phỏng vấn'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lên lịch phỏng vấn: ${applicant.applicantName}')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Chấp nhận'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chấp nhận: ${applicant.applicantName}')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Từ chối', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Từ chối: ${applicant.applicantName}')),
                );
              },
            ),
          ],
        ),
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
    return '${date.day}/${date.month}/${date.year}';
  }
} 