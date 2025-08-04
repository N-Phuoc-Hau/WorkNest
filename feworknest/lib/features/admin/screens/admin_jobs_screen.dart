import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminJobsScreen extends ConsumerStatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  ConsumerState<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends ConsumerState<AdminJobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tin tuyển dụng'),
        actions: [
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
                hintText: 'Tìm kiếm tin tuyển dụng...',
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
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Chờ duyệt'),
                  selected: _selectedFilter == 'pending',
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = 'pending';
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Đã duyệt'),
                  selected: _selectedFilter == 'approved',
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = 'approved';
                    });
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
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Jobs List
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Mock data count
              itemBuilder: (context, index) {
                final mockJobs = [
                  {
                    'title': 'Lập trình viên Flutter',
                    'company': 'TechCorp',
                    'location': 'Hà Nội',
                    'status': 'pending',
                    'type': 'Full-time',
                  },
                  {
                    'title': 'UI/UX Designer',
                    'company': 'DesignStudio',
                    'location': 'TP.HCM',
                    'status': 'approved',
                    'type': 'Part-time',
                  },
                  {
                    'title': 'Backend Developer',
                    'company': 'StartupXYZ',
                    'location': 'Đà Nẵng',
                    'status': 'rejected',
                    'type': 'Full-time',
                  },
                  {
                    'title': 'Product Manager',
                    'company': 'BigTech',
                    'location': 'Hà Nội',
                    'status': 'approved',
                    'type': 'Full-time',
                  },
                  {
                    'title': 'Data Scientist',
                    'company': 'AICompany',
                    'location': 'TP.HCM',
                    'status': 'pending',
                    'type': 'Contract',
                  },
                ];
                
                return _buildJobCard(mockJobs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        job['title']?.toString() ?? 'Unknown Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['company']?.toString() ?? 'Unknown Company',
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
                    color: _getStatusColor(job['status']?.toString() ?? 'pending'),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(job['status']?.toString() ?? 'pending'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  job['location']?.toString() ?? 'Unknown Location',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.work, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  job['type']?.toString() ?? 'Unknown Type',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleJobAction('approve', job),
                    child: const Text('Duyệt'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleJobAction('reject', job),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleJobAction('edit', job),
                    child: const Text('Sửa'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleJobAction('delete', job),
                    child: const Text('Xóa'),
                  ),
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
      case 'approved':
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
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Unknown';
    }
  }

  void _handleJobAction(String action, Map<String, dynamic> job) {
    switch (action) {
      case 'approve':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã duyệt: ${job['title']?.toString() ?? 'Unknown'}')),
        );
        break;
      case 'reject':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã từ chối: ${job['title']?.toString() ?? 'Unknown'}')),
        );
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sửa tin tuyển dụng: ${job['title']?.toString() ?? 'Unknown'}')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa: ${job['title']?.toString() ?? 'Unknown'}')),
        );
        break;
    }
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
} 