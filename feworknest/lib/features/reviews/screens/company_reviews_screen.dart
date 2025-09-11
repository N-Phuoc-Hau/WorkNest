import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/company_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/review_provider.dart';
import '../../../core/utils/auth_guard.dart';
import '../widgets/create_review_dialog.dart';
import '../widgets/review_card.dart';
import '../widgets/review_stats.dart';

class CompanyReviewsScreen extends ConsumerStatefulWidget {
  final CompanyModel company;

  const CompanyReviewsScreen({
    super.key,
    required this.company,
  });

  @override
  ConsumerState<CompanyReviewsScreen> createState() => _CompanyReviewsScreenState();
}

class _CompanyReviewsScreenState extends ConsumerState<CompanyReviewsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadReviews({bool refresh = false}) {
    if (refresh) {
      _hasMorePages = true;
    }
    ref.read(reviewProvider.notifier).getCompanyReviews(widget.company.id);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final reviewState = ref.read(reviewProvider);
      if (_hasMorePages && !reviewState.isLoading && reviewState.reviews.isNotEmpty) {
        // Only load more if we have existing reviews and there might be more
        final currentCount = reviewState.reviews.length;
        if (currentCount >= 10) { // Only load more if we have at least 10 reviews
          _hasMorePages = false; // Prevent infinite loading for now
          // ref.read(reviewProvider.notifier).getCompanyReviews(widget.company.id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final canWriteReview = user?.role == 'candidate';

    return Scaffold(
      appBar: AppBar(
        title: Text('Đánh giá ${widget.company.name}'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          if (canWriteReview)
            IconButton(
              onPressed: () => _showCreateReviewDialog(),
              icon: const Icon(Icons.add_comment),
              tooltip: 'Viết đánh giá',
            ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadReviews(refresh: true);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Company Info Header
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Card(
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
                              backgroundImage: widget.company.images.isNotEmpty
                                  ? NetworkImage(widget.company.images.first)
                                  : null,
                              child: widget.company.images.isEmpty
                                  ? Text(
                                      widget.company.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
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
                                    widget.company.name,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (widget.company.location.isNotEmpty)
                                    Text(
                                      widget.company.location,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Review Statistics
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ReviewStats(reviews: reviewState.reviews),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Reviews List
            if (reviewState.isLoading && reviewState.reviews.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (reviewState.error != null)
              SliverFillRemaining(
                child: Center(
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
                        reviewState.error!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadReviews(refresh: true),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            else if (reviewState.reviews.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có đánh giá nào',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy là người đầu tiên đánh giá công ty này',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (canWriteReview) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateReviewDialog(),
                          icon: const Icon(Icons.add_comment),
                          label: const Text('Viết đánh giá'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < reviewState.reviews.length) {
                        final review = reviewState.reviews[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ReviewCard(review: review),
                        );
                      }
                      
                      // Loading indicator at the end
                      if (reviewState.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      return null;
                    },
                    childCount: reviewState.reviews.length + (reviewState.isLoading ? 1 : 0),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showCreateReviewDialog() {
    if (!AuthGuard.requireAuth(context, ref, 
        message: 'Bạn cần đăng nhập để viết đánh giá.')) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CreateReviewDialog(
        companyId: widget.company.id,
        companyName: widget.company.name,
        onReviewCreated: (review) {
          // Refresh reviews after creating
          _loadReviews(refresh: true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đánh giá của bạn đã được gửi thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }
}
