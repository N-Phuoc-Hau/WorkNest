import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/favorite_provider.dart';
import '../../../core/providers/job_provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/job_card.dart';
import '../widgets/job_filter_bottom_sheet.dart';

class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  
  String? _searchQuery;
  String? _specialized;
  String? _location;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
      
      // Load favorite list to check favorite status
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated && authState.user?.role == 'candidate') {
        ref.read(favoriteProvider.notifier).getMyFavorites();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreJobs();
    }
  }

  Future<void> _loadJobs({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }
    
    await ref.read(jobProvider.notifier).getJobPosts(
      page: _currentPage,
      search: _searchQuery,
      specialized: _specialized,
      location: _location,
      loadMore: !refresh && _currentPage > 1,
    );
  }

  Future<void> _loadMoreJobs() async {
    final jobState = ref.read(jobProvider);
    if (_isLoadingMore || jobState.isLoading || _currentPage >= jobState.totalPages) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadJobs();

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _onSearch() async {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
      _currentPage = 1;
    });
    await _loadJobs(refresh: true);
  }

  Future<void> _showFilterBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => JobFilterBottomSheet(
        initialSpecialized: _specialized,
        initialLocation: _location,
      ),
    );

    if (result != null) {
      setState(() {
        _specialized = result['specialized'];
        _location = result['location'];
        _currentPage = 1;
      });
      await _loadJobs(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm việc làm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _searchController,
                    label: 'Tìm kiếm',
                    hintText: 'Tìm kiếm công việc...',
                    prefixIcon: const Icon(Icons.search),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _onSearch,
                  icon: const Icon(Icons.search),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Filter Tags
          if (_specialized != null || _location != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_specialized != null)
                    FilterChip(
                      label: Text('Chuyên ngành: $_specialized'),
                      selected: true,
                      onSelected: (value) {},
                      onDeleted: () {
                        setState(() {
                          _specialized = null;
                          _currentPage = 1;
                        });
                        _loadJobs(refresh: true);
                      },
                    ),
                  if (_location != null)
                    FilterChip(
                      label: Text('Địa điểm: $_location'),
                      selected: true,
                      onSelected: (value) {},
                      onDeleted: () {
                        setState(() {
                          _location = null;
                          _currentPage = 1;
                        });
                        _loadJobs(refresh: true);
                      },
                    ),
                ],
              ),
            ),

          // Job List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadJobs(refresh: true),
              child: _buildJobList(jobState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList(JobsState jobState) {
    if (jobState.isLoading && jobState.jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobState.error != null && jobState.jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(jobState.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadJobs(refresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (jobState.jobs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy công việc nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: jobState.jobs.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == jobState.jobs.length) {
          // Loading indicator at the bottom
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final job = jobState.jobs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: JobCard(
            job: job,
            onTap: () {
              // Navigate to job details
              context.push('/job-detail/${job.id}');
            },
          ),
        );
      },
    );
  }
}
