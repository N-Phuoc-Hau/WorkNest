import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminCompaniesScreen extends ConsumerStatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  ConsumerState<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends ConsumerState<AdminCompaniesScreen> {
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
        title: const Text('Duyệt công ty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              _showAnalyticsDialog();
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
                hintText: 'Tìm kiếm công ty...',
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
          
          // Companies List
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Mock data count
              itemBuilder: (context, index) {
                final mockCompanies = [
                  {
                    'name': 'TechCorp Solutions',
                    'industry': 'Công nghệ thông tin',
                    'location': 'Hà Nội',
                    'status': 'pending',
                    'description': 'Công ty chuyên về phát triển phần mềm và ứng dụng di động',
                  },
                  {
                    'name': 'DesignStudio Creative',
                    'industry': 'Thiết kế đồ họa',
                    'location': 'TP.HCM',
                    'status': 'approved',
                    'description': 'Studio thiết kế sáng tạo chuyên nghiệp',
                  },
                  {
                    'name': 'StartupXYZ',
                    'industry': 'E-commerce',
                    'location': 'Đà Nẵng',
                    'status': 'rejected',
                    'description': 'Startup thương mại điện tử mới thành lập',
                  },
                  {
                    'name': 'BigTech Corporation',
                    'industry': 'Công nghệ thông tin',
                    'location': 'Hà Nội',
                    'status': 'approved',
                    'description': 'Tập đoàn công nghệ lớn với nhiều sản phẩm đa dạng',
                  },
                  {
                    'name': 'AICompany Vietnam',
                    'industry': 'Trí tuệ nhân tạo',
                    'location': 'TP.HCM',
                    'status': 'pending',
                    'description': 'Công ty chuyên về AI và machine learning',
                  },
                ];
                
                return _buildCompanyCard(mockCompanies[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
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
                    (company['name']?.toString() ?? 'C').substring(0, 1).toUpperCase(),
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
                        company['name']?.toString() ?? 'Unknown Company',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company['industry']?.toString() ?? 'Unknown Industry',
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
                    color: _getStatusColor(company['status']?.toString() ?? 'pending'),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(company['status']?.toString() ?? 'pending'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              company['description']?.toString() ?? 'No description available',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  company['location']?.toString() ?? 'Unknown Location',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleCompanyAction('approve', company),
                    child: const Text('Duyệt'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleCompanyAction('reject', company),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleCompanyAction('view', company),
                    child: const Text('Xem'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleCompanyAction('edit', company),
                    child: const Text('Sửa'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleCompanyAction('delete', company),
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

  void _handleCompanyAction(String action, Map<String, dynamic> company) {
    switch (action) {
      case 'approve':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã duyệt: ${company['name']?.toString() ?? 'Unknown'}')),
        );
        break;
      case 'reject':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã từ chối: ${company['name']?.toString() ?? 'Unknown'}')),
        );
        break;
      case 'view':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xem chi tiết: ${company['name']?.toString() ?? 'Unknown'}')),
        );
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sửa thông tin: ${company['name']?.toString() ?? 'Unknown'}')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa: ${company['name']?.toString() ?? 'Unknown'}')),
        );
        break;
    }
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thống kê công ty'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng số công ty: 150'),
            Text('Chờ duyệt: 25'),
            Text('Đã duyệt: 120'),
            Text('Từ chối: 5'),
            SizedBox(height: 16),
            Text('Tính năng thống kê chi tiết đang phát triển...'),
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