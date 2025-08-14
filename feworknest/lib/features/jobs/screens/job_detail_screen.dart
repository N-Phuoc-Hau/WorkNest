import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/company_model.dart' as standalone_company;
import '../../../core/models/follow_model.dart';
import '../../../core/models/job_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/favorite_provider.dart';
import '../../../core/providers/follow_provider.dart';
import '../../../core/providers/job_provider.dart';
import '../../../core/providers/review_provider.dart';
import '../../../core/utils/application_utils.dart';
import '../../../core/utils/auth_guard.dart';
import '../../reviews/screens/company_reviews_screen.dart';
import '../../reviews/widgets/review_card.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobIdInt = int.tryParse(widget.jobId) ?? 0;
      ref.read(jobProvider.notifier).getJobPost(jobIdInt);
      
      // Load recent jobs for related jobs section
      ref.read(jobProvider.notifier).getJobPosts(page: 1, pageSize: 20);
      
      // Load following list to check follow status
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated && authState.user?.role == 'candidate') {
        ref.read(followProvider.notifier).getMyFollowing();
      }
    });
  }

  void _loadCompanyReviews(int companyId) {
    ref.read(reviewProvider.notifier).getCompanyReviews(companyId);
  }

  // Convert UserModel CompanyModel to standalone CompanyModel
  standalone_company.CompanyModel _convertToCompanyModel(dynamic userCompany) {
    return standalone_company.CompanyModel(
      id: userCompany.id,
      name: userCompany.name,
      taxCode: userCompany.taxCode,
      description: userCompany.description ?? '',
      location: userCompany.location ?? '',
      isVerified: userCompany.isVerified,
      isActive: true, // Default value
      images: userCompany.images,
      createdAt: DateTime.now(), // Default value
      updatedAt: DateTime.now(), // Default value
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobProvider);
    final job = jobsState.selectedJob;
    final isLoading = jobsState.isLoading;
    final error = jobsState.error;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết công việc')),
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
                error ?? 'Không tìm thấy công việc',
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
        title: const Text('Chi tiết công việc'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: job.recruiter.avatar != null
                              ? NetworkImage(job.recruiter.avatar!)
                              : null,
                          child: job.recruiter.avatar == null
                              ? Text(
                                  (job.recruiter.company?.name ?? 'C')[0].toUpperCase(),
                                  style: const TextStyle(
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
                                job.recruiter.company?.name ?? 'Unknown Company',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (job.recruiter.company?.isVerified == true)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Đã xác minh',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Action buttons for candidates
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(authProvider);
                        final user = authState.user;
                        
                        // Only show buttons for candidates or unauthenticated users
                        if (authState.isAuthenticated && user?.role != 'candidate') {
                          return const SizedBox.shrink();
                        }
                        
                        if (job.recruiter.company?.id == null) {
                          return const SizedBox.shrink();
                        }
                        
                        final followState = ref.watch(followProvider);
                        final isFollowing = followState.followingCompanies.any(
                          (company) => company.id == job.recruiter.company!.id
                        );

                        final favoriteState = ref.watch(favoriteProvider);
                        final isFavorited = favoriteState.favoriteJobs
                            .any((favorite) => favorite.jobId == job.id);
                        
                        return Row(
                          children: [
                            // Follow button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  if (!AuthGuard.requireAuth(context, ref, 
                                      message: 'Bạn cần đăng nhập để theo dõi công ty.')) {
                                    return;
                                  }
                                  _toggleFollowCompany(ref, job.recruiter.company!.id);
                                },
                                icon: Icon(
                                  isFollowing ? Icons.person_remove : Icons.person_add,
                                ),
                                label: Text(
                                  isFollowing ? 'Bỏ theo dõi' : 'Theo dõi',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isFollowing 
                                    ? Colors.grey[600] 
                                    : Theme.of(context).primaryColor,
                                  side: BorderSide(
                                    color: isFollowing 
                                      ? Colors.grey[400]! 
                                      : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Favorite button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (!AuthGuard.requireAuth(context, ref, 
                                      message: 'Bạn cần đăng nhập để lưu việc làm yêu thích.')) {
                                    return;
                                  }
                                  _toggleFavorite(ref, job.id);
                                },
                                icon: Icon(
                                  isFavorited ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isFavorited ? 'Đã lưu' : 'Lưu việc',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFavorited ? Colors.red : Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Job Title Section
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
                      job.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Job Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(context, job.specialized, Icons.work),
                        if (job.jobType != null)
                          _buildChip(context, job.jobType!, Icons.schedule),
                        _buildChip(
                          context,
                          '${job.salary.toStringAsFixed(0)} VNĐ',
                          Icons.attach_money,
                          color: Colors.green,
                        ),
                        _buildChip(context, job.location, Icons.location_on, color: Colors.orange),
                        _buildChip(context, job.workingHours, Icons.access_time, color: Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Job Description
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
                        Icon(
                          Icons.description,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mô tả công việc',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      job.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Company Description
            if (job.recruiter.company?.description != null)
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
                          Icon(
                            Icons.business,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Về công ty',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        job.recruiter.company!.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Company Reviews Section
            Consumer(
              builder: (context, ref, child) {
                // Load reviews when company is available
                if (job.recruiter.company != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadCompanyReviews(job.recruiter.company!.id);
                  });
                }

                final reviewState = ref.watch(reviewProvider);
                final reviews = reviewState.reviews.take(3).toList();

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Đánh giá công ty',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (reviewState.reviews.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${reviewState.reviews.length} đánh giá',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        if (reviewState.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (reviews.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          
                          // Display up to 3 reviews
                          ...reviews.map((review) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReviewCard(review: review),
                          )),
                          
                          // Show more button if there are more than 3 reviews
                          if (reviewState.reviews.length > 3)
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  if (job.recruiter.company != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CompanyReviewsScreen(
                                          company: _convertToCompanyModel(job.recruiter.company!),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: Text('Xem thêm ${reviewState.reviews.length - 3} đánh giá'),
                              ),
                            ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Chưa có đánh giá nào',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  if (job.recruiter.company != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CompanyReviewsScreen(
                                          company: _convertToCompanyModel(job.recruiter.company!),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.star_outline),
                                label: const Text('Xem tất cả'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (!AuthGuard.requireAuth(context, ref, 
                                      message: 'Bạn cần đăng nhập để viết đánh giá công ty.')) {
                                    return;
                                  }
                                  if (job.recruiter.company != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CompanyReviewsScreen(
                                          company: _convertToCompanyModel(job.recruiter.company!),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.rate_review),
                                label: const Text('Viết đánh giá'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Job Stats
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.people,
                              color: Colors.blue.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${job.applicationCount}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          Text(
                            'Ứng tuyển',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey[200],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: Colors.green.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(job.createdAt),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                          Text(
                            'Ngày đăng',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
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

            // Related Jobs Section
            Consumer(
              builder: (context, ref, child) {
                final jobsState = ref.watch(jobProvider);
                final relatedJobs = jobsState.jobs.where((relatedJob) => 
                  relatedJob.id != job.id &&
                  (relatedJob.location.toLowerCase().contains(job.location.toLowerCase()) ||
                   relatedJob.jobType == job.jobType ||
                   relatedJob.recruiter.company?.name == job.recruiter.company?.name)
                ).take(3).toList();

                if (relatedJobs.isNotEmpty) {
                  return Card(
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
                            'Công việc liên quan',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          ...relatedJobs.map((relatedJob) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                context.push('/job-detail/${relatedJob.id}');
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    // Company Logo
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: relatedJob.recruiter.company != null && relatedJob.recruiter.company!.images.isNotEmpty
                                            ? Image.network(
                                                relatedJob.recruiter.company!.images.first,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => 
                                                    Center(
                                                      child: Text(
                                                        (relatedJob.recruiter.company?.name ?? 'C')[0].toUpperCase(),
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                              )
                                            : Center(
                                                child: Text(
                                                  (relatedJob.recruiter.company?.name ?? 'C')[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Job Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            relatedJob.title,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            relatedJob.recruiter.company?.name ?? 'Không rõ công ty',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  relatedJob.location,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Arrow Icon
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),
                          
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // Navigate to search with similar criteria
                                context.push('/search?location=${Uri.encodeComponent(job.location)}&jobType=${Uri.encodeComponent(job.jobType ?? '')}');
                              },
                              child: const Text('Xem thêm công việc tương tự'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            const SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authProvider);
          final user = authState.user;
          
          // Show apply button for both authenticated candidates and unauthenticated users
          if (authState.isAuthenticated && user?.role != 'candidate') {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () {
              if (!AuthGuard.requireAuth(context, ref, 
                  message: 'Bạn cần đăng nhập để ứng tuyển vào vị trí này.')) {
                return;
              }
              _showApplyDialog(context, job);
            },
            label: const Text('Ứng tuyển'),
            icon: const Icon(Icons.send),
          );
        },
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon, {Color? color}) {
    final chipColor = color ?? Theme.of(context).primaryColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: chipColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _toggleFavorite(WidgetRef ref, int jobId) async {
    final favoriteNotifier = ref.read(favoriteProvider.notifier);
    final isFavorited = ref.read(favoriteProvider).favoriteJobs
        .any((favorite) => favorite.jobId == jobId);

    if (isFavorited) {
      await favoriteNotifier.removeFromFavorite(jobId);
    } else {
      await favoriteNotifier.addToFavorite(jobId);
    }
  }

  Future<void> _toggleFollowCompany(WidgetRef ref, int companyId) async {
    final followNotifier = ref.read(followProvider.notifier);
    final followState = ref.read(followProvider);
    final isFollowing = followState.followingCompanies.any(
      (company) => company.id == companyId
    );

    if (isFollowing) {
      final success = await followNotifier.unfollowCompany(companyId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bỏ theo dõi công ty'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Create follow request
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

  void _showApplyDialog(BuildContext context, JobModel job) {
    ApplicationUtils.showApplicationDialog(
      context: context,
      jobId: job.id,
      jobTitle: job.title,
      companyName: job.recruiter.company?.name ?? 'Unknown Company',
    );
  }
}
