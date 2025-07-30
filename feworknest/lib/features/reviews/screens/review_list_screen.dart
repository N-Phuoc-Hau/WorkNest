import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/review_provider.dart';
import '../../../core/models/review_model.dart';
import '../widgets/review_card.dart';

class ReviewListScreen extends ConsumerStatefulWidget {
  static const String routeName = '/reviews';
  
  final int? companyId;
  final String? companyName;
  final bool showMyReviews;

  const ReviewListScreen({
    super.key,
    this.companyId,
    this.companyName,
    this.showMyReviews = false,
  });

  @override
  ConsumerState<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends ConsumerState<ReviewListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.showMyReviews ? 2 : 1,
      vsync: this,
    );
    
    // Load initial data
    Future.microtask(() {
      if (widget.companyId != null) {
        ref.read(reviewProvider.notifier).getCompanyReviews(widget.companyId!);
      }
      if (widget.showMyReviews) {
        ref.read(reviewProvider.notifier).getMyReviews();
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
    final reviewState = ref.watch(reviewProvider);
    
    String title = 'Đánh giá';
    if (widget.companyName != null) {
      title = 'Đánh giá ${widget.companyName}';
    } else if (widget.showMyReviews) {
      title = 'Đánh giá của tôi';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: widget.showMyReviews 
          ? TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Tôi nhận được'),
                Tab(text: 'Tôi đã viết'),
              ],
            )
          : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReviews,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: widget.showMyReviews 
        ? TabBarView(
            controller: _tabController,
            children: [
              _buildCompanyReviewsList(reviewState.reviews),
              _buildMyReviewsList(reviewState.myReviews),
            ],
          )
        : _buildCompanyReviewsList(reviewState.reviews),
    );
  }

  Widget _buildCompanyReviewsList(List<ReviewModel> reviews) {
    final reviewState = ref.watch(reviewProvider);
    
    if (reviewState.isLoading && reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reviewState.error != null && reviews.isEmpty) {
      return _buildErrorState(reviewState.error!);
    }

    if (reviews.isEmpty) {
      return _buildEmptyState(
        'Chưa có đánh giá nào',
        widget.companyId != null 
          ? 'Hãy là người đầu tiên đánh giá công ty này!'
          : 'Chưa có đánh giá nào được tìm thấy',
        Icons.star_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshReviews(),
      child: Column(
        children: [
          // Summary header
          if (widget.companyId != null) _buildReviewSummary(reviews),
          
          // Reviews list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return ReviewCard(
                  review: review,
                  showReviewedUser: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReviewsList(List<ReviewModel> myReviews) {
    final reviewState = ref.watch(reviewProvider);
    
    if (reviewState.isLoading && myReviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (myReviews.isEmpty) {
      return _buildEmptyState(
        'Bạn chưa viết đánh giá nào',
        'Hãy chia sẻ trải nghiệm của bạn để giúp cộng đồng!',
        Icons.rate_review,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(reviewProvider.notifier).getMyReviews(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myReviews.length,
        itemBuilder: (context, index) {
          final review = myReviews[index];
          return ReviewCard(
            review: review,
            showReviewedUser: true,
            showActions: true,
            onDelete: () => _deleteReview(review),
          );
        },
      ),
    );
  }

  Widget _buildReviewSummary(List<ReviewModel> reviews) {
    if (reviews.isEmpty) return const SizedBox();

    final totalReviews = reviews.length;
    final averageRating = reviews.fold<double>(
      0.0, 
      (sum, review) => sum + review.rating,
    ) / totalReviews;

    // Rating distribution
    final ratingCounts = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      ratingCounts[i] = reviews.where((r) => r.rating == i).length;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Average rating
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews đánh giá',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 24),
              
              // Rating bars
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final starNumber = 5 - index;
                    final count = ratingCounts[starNumber] ?? 0;
                    final percentage = totalReviews > 0 ? count / totalReviews : 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$starNumber',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 12, color: Colors.amber[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber[600]!,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 20,
                            child: Text(
                              count.toString(),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Đã xảy ra lỗi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshReviews,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _refreshReviews() {
    if (widget.companyId != null) {
      ref.read(reviewProvider.notifier).getCompanyReviews(widget.companyId!);
    }
    if (widget.showMyReviews) {
      ref.read(reviewProvider.notifier).getMyReviews();
    }
  }

  void _deleteReview(ReviewModel review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đánh giá'),
        content: const Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(reviewProvider.notifier).deleteReview(review.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa đánh giá'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
