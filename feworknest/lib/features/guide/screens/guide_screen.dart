import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/guide_service.dart';

final guideServiceProvider = Provider<GuideService>((ref) => GuideService());

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _guideData;
  Map<String, dynamic>? _apiData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGuideData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGuideData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final guideService = ref.read(guideServiceProvider);
      
      final guideResult = await guideService.getAppGuide();
      final apiResult = await guideService.getApiDocumentation();

      if (guideResult['success'] && apiResult['success']) {
        setState(() {
          _guideData = guideResult['data'];
          _apiData = apiResult['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không thể tải hướng dẫn';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Có lỗi xảy ra: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hướng dẫn sử dụng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hướng dẫn App', icon: Icon(Icons.help_outline)),
            Tab(text: 'Tài liệu API', icon: Icon(Icons.code)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppGuideTab(),
                    _buildApiDocumentationTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGuideData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppGuideTab() {
    if (_guideData == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Thông tin ứng dụng', [
            _buildInfoRow('Tên ứng dụng', _guideData!['appName']),
            _buildInfoRow('Phiên bản', _guideData!['version']),
            _buildInfoRow('Mô tả', _guideData!['description']),
          ]),
          
          _buildSection('Xác thực & Bảo mật', [
            _buildInfoRow('Thời gian token', _guideData!['authentication']['tokenExpiry']),
            _buildInfoRow('Tự động đăng xuất', _guideData!['authentication']['autoLogout']),
            _buildInfoRow('Lưu đăng nhập', _guideData!['authentication']['persistentLogin']),
            _buildInfoRow('Quản lý phiên', _guideData!['authentication']['sessionManagement']),
          ]),
          
          _buildRolesSection(),
          _buildFeaturesSection(),
          _buildSecuritySection(),
          _buildTroubleshootingSection(),
        ],
      ),
    );
  }

  Widget _buildApiDocumentationTab() {
    if (_apiData == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Thông tin API', [
            _buildInfoRow('Base URL', _apiData!['baseUrl']),
            _buildInfoRow('Content Type', _apiData!['contentType']),
          ]),
          
          _buildApiEndpointsSection('Auth Endpoints', _apiData!['authEndpoints']),
          _buildApiEndpointsSection('Job Endpoints', _apiData!['jobEndpoints']),
          _buildApiEndpointsSection('Application Endpoints', _apiData!['applicationEndpoints']),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSection() {
    final roles = _guideData!['userRoles'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vai trò người dùng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildRoleCard('Ứng viên', roles['candidate']),
            const SizedBox(height: 8),
            _buildRoleCard('Nhà tuyển dụng', roles['recruiter']),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(String roleName, Map<String, dynamic> roleData) {
    return ExpansionTile(
      title: Text(roleName, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        _buildPermissionsList('Quyền hạn', roleData['permissions']),
        _buildPermissionsList('Hạn chế', roleData['restrictions']),
      ],
    );
  }

  Widget _buildPermissionsList(String title, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = _guideData!['features'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tính năng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildFeatureCard('Quản lý việc làm', features['jobManagement']),
            _buildFeatureCard('Quản lý hồ sơ ứng tuyển', features['applicationManagement']),
            
            const SizedBox(height: 8),
            const Text('Tính năng khác:', style: TextStyle(fontWeight: FontWeight.w500)),
            ...features['otherFeatures'].map<Widget>((feature) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('• $feature', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, Map<String, dynamic> featureData) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        if (featureData.containsKey('forRecruiters'))
          _buildPermissionsList('Cho nhà tuyển dụng', featureData['forRecruiters']),
        if (featureData.containsKey('forCandidates'))
          _buildPermissionsList('Cho ứng viên', featureData['forCandidates']),
        if (featureData.containsKey('forEveryone'))
          _buildPermissionsList('Cho mọi người', featureData['forEveryone']),
      ],
    );
  }

  Widget _buildSecuritySection() {
    final security = _guideData!['securityNotes'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bảo mật',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildPermissionsList('Bảo mật Token', security['tokenSecurity']),
            _buildPermissionsList('Bảo vệ dữ liệu', security['dataProtection']),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    final troubleshooting = _guideData!['troubleshooting'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khắc phục sự cố',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildPermissionsList('Lỗi thường gặp', troubleshooting['commonIssues']),
            _buildPermissionsList('Mẹo sử dụng', troubleshooting['tips']),
          ],
        ),
      ),
    );
  }

  Widget _buildApiEndpointsSection(String title, Map<String, dynamic> endpoints) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            
            ...endpoints.entries.map((entry) => _buildApiEndpoint(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildApiEndpoint(String name, dynamic endpoint) {
    if (endpoint is Map<String, dynamic>) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (endpoint.containsKey('method'))
                Text('Method: ${endpoint['method']}', style: const TextStyle(fontSize: 12)),
              if (endpoint.containsKey('url'))
                Text('URL: ${endpoint['url']}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              if (endpoint.containsKey('requiresAuth'))
                Text('Requires Auth: ${endpoint['requiresAuth']}', style: const TextStyle(fontSize: 12)),
              if (endpoint.containsKey('role'))
                Text('Role: ${endpoint['role']}', style: const TextStyle(fontSize: 12)),
              if (endpoint.containsKey('note'))
                Text('Note: ${endpoint['note']}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
            ],
          ),
        ),
      );
    }
    return const SizedBox();
  }
}
