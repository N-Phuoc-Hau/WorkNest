import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/company_model.dart' as company_model;
import '../../core/models/follow_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/follow_provider.dart';
import '../../core/providers/job_provider.dart';
import '../../core/services/api_service.dart';
import '../../features/jobs/widgets/job_card.dart';

final companyServiceProvider = Provider<ApiService>((ref) => ApiService());

final companyProvider = FutureProvider.family<company_model.CompanyModel?, String>((ref, companyId) async {
  print('🔍 CompanyProvider called with ID: $companyId');
  final apiService = ref.read(companyServiceProvider);
  try {
    print('🔍 CompanyProvider making API call to /api/Company/$companyId');
    final response = await apiService.get('/api/Company/$companyId');
    print('🔍 CompanyProvider API response: $response');
    
    // Backend returns CompanyDto directly, not wrapped in {success, data}
    final company = company_model.CompanyModel.fromJson(response);
    print('🔍 CompanyProvider parsed company: ${company.name}');
    return company;
  } catch (e) {
    print('❌ CompanyProvider error: $e');
    throw Exception('Failed to load company: $e');
  }
});

class CompanyScreen extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyScreen({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen>
    with TickerProviderStateMixin 
{
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    print('🔍 CompanyScreen initState - Company ID: ${widget.companyId}');
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load company jobs
      final companyIdInt = int.tryParse(widget.companyId) ?? 0;
      print('🔍 CompanyScreen loading jobs for company ID: $companyIdInt');
      if (companyIdInt > 0) {
        ref.read(jobProvider.notifier).getJobPosts(
          page: 1,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 CompanyScreen build - Company ID: ${widget.companyId}');
    final companyAsync = ref.watch(companyProvider(widget.companyId));
    final authState = ref.watch(authProvider);
    final jobState = ref.watch(jobProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: companyAsync.when(
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
          ),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            title: const Text('Lỗi'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
          body: Center(
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
                  'Không thể tải thông tin công ty',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (company) {
          if (company == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Không tìm thấy'),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
              body: const Center(
                child: Text('Không tìm thấy thông tin công ty'),
              ),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 320,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildCompanyHeader(company, authState),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(50),
                    child: Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF6C63FF),
                        padding: EdgeInsets.symmetric(vertical: 8),
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: const Color(0xFF6C63FF),
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'Thông tin'),
                          Tab(text: 'Việc làm'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildCompanyInfo(company),
                _buildCompanyJobs(jobState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyHeader(company_model.CompanyModel company, AuthState authState) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF4FACFE),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: company.images.isNotEmpty
                        ? Image.network(
                            company.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.business,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.business,
                            size: 40,
                            color: Colors.grey,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              company.location,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (company.isVerified)
                        const SizedBox(height: 8),
                      if (company.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Đã xác thực',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (authState.isAuthenticated && authState.user?.role == 'candidate')
              _buildFollowButton(company.id),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(int companyId) {
    return Consumer(
      builder: (context, ref, child) {
        final followState = ref.watch(followProvider);
        final isFollowing = followState.followingCompanies.any(
          (company) => company.id == companyId,
        );

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _toggleFollow(companyId),
            icon: Icon(
              isFollowing ? Icons.favorite : Icons.favorite_border,
              size: 18,
            ),
            label: Text(
              isFollowing ? 'Đã theo dõi' : 'Theo dõi công ty',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.red : Colors.white,
              foregroundColor: isFollowing ? Colors.white : const Color(0xFF6C63FF),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyInfo(company_model.CompanyModel company) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Color(0xFF6C63FF),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Giới thiệu công ty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    company.description.isNotEmpty
                        ? company.description
                        : 'Chưa có thông tin mô tả về công ty.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Company Details Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4FACFE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business_center,
                          color: Color(0xFF4FACFE),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Thông tin chi tiết',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(Icons.business, 'Mã số thuế', company.taxCode ?? 'Chưa cập nhật'),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_on, 'Địa chỉ', company.location),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Ngày thành lập',
                    _formatDate(company.createdAt),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyJobs(JobsState jobState) {
    if (jobState.isLoading && jobState.jobs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
        ),
      );
    }

    if (jobState.jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_outline,
                size: 64,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có việc làm nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Công ty này chưa đăng tuyển việc làm nào.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: jobState.jobs.length,
      itemBuilder: (context, index) {
        final job = jobState.jobs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: JobCard(
            job: job,
            onTap: () => context.push('/job-detail/${job.id}'),
          ),
        );
      },
    );
  }

  Future<void> _toggleFollow(int companyId) async {
    final followNotifier = ref.read(followProvider.notifier);
    final followState = ref.read(followProvider);
    final isFollowing = followState.followingCompanies.any(
      (company) => company.id == companyId,
    );

    if (isFollowing) {
      final success = await followNotifier.unfollowCompany(companyId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bỏ theo dõi công ty'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      final createFollow = CreateFollowModel(companyId: companyId);
      final success = await followNotifier.followCompany(createFollow);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã theo dõi công ty'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}