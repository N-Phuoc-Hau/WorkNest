import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/follow_provider.dart';
import '../../../core/utils/auth_guard.dart';
import '../widgets/company_follow_card.dart';

class FollowingCompaniesScreen extends ConsumerStatefulWidget {
  const FollowingCompaniesScreen({super.key});

  @override
  ConsumerState<FollowingCompaniesScreen> createState() => _FollowingCompaniesScreenState();
}

class _FollowingCompaniesScreenState extends ConsumerState<FollowingCompaniesScreen> {
  final _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthGuard.requireAuth(context, ref, 
          message: 'Bạn cần đăng nhập để xem danh sách công ty theo dõi.')) {
        _loadFollowing();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreFollowing();
    }
  }

  Future<void> _loadFollowing({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }
    
    await ref.read(followProvider.notifier).getMyFollowing(
      page: _currentPage,
      loadMore: !refresh && _currentPage > 1,
    );
  }

  Future<void> _loadMoreFollowing() async {
    final followState = ref.read(followProvider);
    if (_isLoadingMore || followState.isLoading || _currentPage >= followState.totalPages) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadFollowing();

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // Check if user is authenticated
    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Công ty theo dõi'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Bạn cần đăng nhập để xem danh sách công ty theo dõi',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      );
    }

    final followState = ref.watch(followProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Công ty theo dõi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadFollowing(refresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFollowing(refresh: true),
        child: _buildFollowingList(followState),
      ),
    );
  }

  Widget _buildFollowingList(FollowState followState) {
    if (followState.isLoading && followState.following.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (followState.error != null && followState.following.isEmpty) {
      return Center(
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
              followState.error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadFollowing(refresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (followState.following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa theo dõi công ty nào',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy khám phá và theo dõi các công ty bạn quan tâm',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/jobs'),
              child: const Text('Khám phá việc làm'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.business,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Đang theo dõi ${followState.totalCount} công ty',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Following list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: followState.following.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == followState.following.length) {
                // Loading indicator at the bottom
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final follow = followState.following[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CompanyFollowCard(
                  follow: follow,
                  onTap: () {
                    // Navigate to company details if available
                    if (follow.recruiter?.company?.id != null) {
                      context.push('/company-details/${follow.recruiter!.company!.id}');
                    }
                  },
                  onUnfollow: () async {
                    if (follow.recruiter?.company?.id != null) {
                      final success = await ref
                          .read(followProvider.notifier)
                          .unfollowCompany(follow.recruiter!.company!.id);
                      
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã bỏ theo dõi ${follow.recruiter!.company!.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
