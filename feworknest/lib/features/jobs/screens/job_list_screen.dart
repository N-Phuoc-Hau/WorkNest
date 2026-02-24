import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/favorite_provider.dart';
import '../../../core/providers/job_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/language_toggle_widget.dart';
import '../widgets/job_card.dart';
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
  bool _isGridView = true; // Grid view by default

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      backgroundColor: Colors.transparent,
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = null;
      _specialized = null;
      _location = null;
      _currentPage = 1;
    });
    _loadJobs(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobProvider);
    final l10n = ref.watch(localizationsProvider);
    final themeMode = Theme.of(context).brightness;
    final isDark = themeMode == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 1024;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar with gradient
          _buildAppBar(l10n, isDark),
          
          // Search and Filter Section
          SliverToBoxAdapter(
            child: _buildSearchSection(l10n, isDark, isWide),
          ),
          
          // Active Filters Chips
          if (_specialized != null || _location != null || _searchQuery != null)
            SliverToBoxAdapter(
              child: _buildActiveFilters(l10n, isDark),
            ),
          
          // Header with results count and controls
          SliverToBoxAdapter(
            child: _buildHeader(jobState, l10n, isDark),
          ),
          
          // Job List/Grid
          _buildJobList(jobState, l10n, isDark, isWide),
          
          // Loading More Indicator
          if (_isLoadingMore)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.spacing24),
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
          
          // Bottom Padding
          SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.spacing32),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(dynamic l10n, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: EdgeInsets.only(
            left: AppSpacing.spacing20,
            bottom: AppSpacing.spacing16,
          ),
          title: Text(
            l10n.findJobs,
            style: AppTypography.h4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      actions: [
        // Language toggle
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.spacing16),
          child: const LanguageToggleButton(isDarkBg: true),
        ),
      ],
    );
  }

  Widget _buildSearchSection(dynamic l10n, bool isDark, bool isWide) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.spacing20),
      padding: EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.white,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.searchJobs,
            style: AppTypography.h5.copyWith(
              color: isDark ? AppColors.white : AppColors.neutral900,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing16),
          
          // Search Bar
          isWide
              ? _buildWideSearchBar(l10n, isDark)
              : _buildMobileSearchBar(l10n, isDark),
        ],
      ),
    );
  }

  Widget _buildWideSearchBar(dynamic l10n, bool isDark) {
    return Row(
      children: [
        // Search Input
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _onSearch(),
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.white : AppColors.neutral900,
            ),
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholderJob,
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.neutral500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: isDark ? AppColors.neutral700 : AppColors.neutral50,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing16,
                vertical: AppSpacing.spacing16,
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.spacing12),
        
        // Location Dropdown
        Expanded(
          flex: 2,
          child: _buildLocationDropdown(l10n, isDark),
        ),
        SizedBox(width: AppSpacing.spacing12),
        
        // Filter Button
        OutlinedButton.icon(
          onPressed: _showFilterBottomSheet,
          icon: Icon(Icons.tune_rounded, size: 20),
          label: Text(l10n.filter),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing20,
              vertical: AppSpacing.spacing16,
            ),
            side: BorderSide(
              color: isDark ? AppColors.neutral600 : AppColors.neutral300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.spacing12),
        
        // Search Button
        ElevatedButton(
          onPressed: _onSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing32,
              vertical: AppSpacing.spacing16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            elevation: 0,
          ),
          child: Text(
            l10n.search,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSearchBar(dynamic l10n, bool isDark) {
    return Column(
      children: [
        // Search Input
        TextField(
          controller: _searchController,
          onSubmitted: (_) => _onSearch(),
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.white : AppColors.neutral900,
          ),
          decoration: InputDecoration(
            hintText: l10n.searchPlaceholderJob,
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.neutral500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.primary,
            ),
            filled: true,
            fillColor: isDark ? AppColors.neutral700 : AppColors.neutral50,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.spacing12),
        
        // Location and Filter Row
        Row(
          children: [
            Expanded(
              child: _buildLocationDropdown(l10n, isDark),
            ),
            SizedBox(width: AppSpacing.spacing12),
            OutlinedButton.icon(
              onPressed: _showFilterBottomSheet,
              icon: Icon(Icons.tune_rounded, size: 20),
              label: Text(l10n.filter),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing16,
                  vertical: AppSpacing.spacing12,
                ),
                side: BorderSide(
                  color: isDark ? AppColors.neutral600 : AppColors.neutral300,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.spacing12),
        
        // Search Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
            child: Text(l10n.search),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDropdown(dynamic l10n, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing4,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral700 : AppColors.neutral50,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _location,
          hint: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSpacing.spacing8),
              Text(
                l10n.allLocations,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? AppColors.neutral400 : AppColors.neutral600,
          ),
          dropdownColor: isDark ? AppColors.neutral700 : AppColors.white,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.white : AppColors.neutral900,
          ),
          items: [
            'Hà Nội',
            'Hồ Chí Minh',
            'Đà Nẵng',
            'Cần Thơ',
            'Hải Phòng',
          ].map((location) {
            return DropdownMenuItem(
              value: location,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: AppSpacing.spacing8),
                  Text(location),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _location = value;
              _currentPage = 1;
            });
            _loadJobs(refresh: true);
          },
        ),
      ),
    );
  }

  Widget _buildActiveFilters(dynamic l10n, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
      padding: EdgeInsets.only(bottom: AppSpacing.spacing16),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.spacing8,
              runSpacing: AppSpacing.spacing8,
              children: [
                if (_searchQuery != null)
                  _buildFilterChip(
                    '${l10n.search}: $_searchQuery',
                    () {
                      setState(() {
                        _searchQuery = null;
                        _searchController.clear();
                        _currentPage = 1;
                      });
                      _loadJobs(refresh: true);
                    },
                    isDark,
                  ),
                if (_specialized != null)
                  _buildFilterChip(
                    '${l10n.specialized}: $_specialized',
                    () {
                      setState(() {
                        _specialized = null;
                        _currentPage = 1;
                      });
                      _loadJobs(refresh: true);
                    },
                    isDark,
                  ),
                if (_location != null)
                  _buildFilterChip(
                    '${l10n.location}: $_location',
                    () {
                      setState(() {
                        _location = null;
                        _currentPage = 1;
                      });
                      _loadJobs(refresh: true);
                    },
                    isDark,
                  ),
              ],
            ),
          ),
          if (_searchQuery != null || _specialized != null || _location != null)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: Icon(Icons.clear_all_rounded, size: 18),
              label: Text(l10n.clearFilters),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete, bool isDark) {
    return Chip(
      label: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.white : AppColors.neutral900,
        ),
      ),
      deleteIcon: Icon(
        Icons.close_rounded,
        size: 18,
        color: isDark ? AppColors.neutral300 : AppColors.neutral600,
      ),
      onDeleted: onDelete,
      backgroundColor: isDark ? AppColors.neutral700 : AppColors.neutral100,
      side: BorderSide(
        color: isDark ? AppColors.neutral600 : AppColors.neutral300,
      ),
    );
  }

  Widget _buildHeader(JobsState jobState, dynamic l10n, bool isDark) {
    final totalJobs = jobState.totalCount;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing20,
        vertical: AppSpacing.spacing16,
      ),
      child: Row(
        children: [
          // Results count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.allJobs,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? AppColors.white : AppColors.neutral900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.spacing4),
                if (!jobState.isLoading || jobState.jobs.isNotEmpty)
                  Text(
                    'Hiển thị $totalJobs kết quả',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
              ],
            ),
          ),
          
          // View Toggle
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.neutral800 : AppColors.neutral100,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: isDark ? AppColors.neutral700 : AppColors.neutral200,
              ),
            ),
            child: Row(
              children: [
                _buildViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  isSelected: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                  isDark: isDark,
                ),
                _buildViewToggleButton(
                  icon: Icons.view_list_rounded,
                  isSelected: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacing8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? AppColors.white
              : (isDark ? AppColors.neutral400 : AppColors.neutral600),
        ),
      ),
    );
  }

  Widget _buildJobList(JobsState jobState, dynamic l10n, bool isDark, bool isWide) {
    if (jobState.isLoading && jobState.jobs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: AppSpacing.spacing16),
              Text(
                l10n.loadingJobs,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (jobState.error != null && jobState.jobs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              SizedBox(height: AppSpacing.spacing16),
              Text(
                jobState.error!,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.white : AppColors.neutral900,
                ),
              ),
              SizedBox(height: AppSpacing.spacing16),
              ElevatedButton(
                onPressed: () => _loadJobs(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (jobState.jobs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_off_rounded,
                size: 80,
                color: AppColors.neutral400,
              ),
              SizedBox(height: AppSpacing.spacing16),
              Text(
                l10n.noJobsFound,
                style: AppTypography.h5.copyWith(
                  color: isDark ? AppColors.white : AppColors.neutral900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.spacing8),
              Text(
                l10n.tryAdjustingFilters,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
              if (_searchQuery != null || _specialized != null || _location != null) ...[
                SizedBox(height: AppSpacing.spacing20),
                ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: Icon(Icons.clear_all_rounded),
                  label: Text(l10n.clearFilters),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Grid or List view
    if (_isGridView && isWide) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.spacing16,
            mainAxisSpacing: AppSpacing.spacing16,
            childAspectRatio: 1.3,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final job = jobState.jobs[index];
              return JobCard(
                job: job,
                onTap: () => context.push('/job-detail/${job.id}'),
                onFavorite: () => _handleFavoriteToggle(job.id),
              );
            },
            childCount: jobState.jobs.length,
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final job = jobState.jobs[index];
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.spacing16),
                child: JobCard(
                  job: job,
                  onTap: () => context.push('/job-detail/${job.id}'),
                  onFavorite: () => _handleFavoriteToggle(job.id),
                ),
              );
            },
            childCount: jobState.jobs.length,
          ),
        ),
      );
    }
  }

  Future<void> _handleFavoriteToggle(int jobId) async {
    final l10n = ref.read(localizationsProvider);
    final favoriteNotifier = ref.read(favoriteProvider.notifier);
    final favoriteState = ref.read(favoriteProvider);
    final isFavorited = favoriteState.favoriteJobs
        .any((favorite) => favorite.jobId == jobId);
    
    if (isFavorited) {
      final success = await favoriteNotifier.removeFromFavorite(jobId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.removedFromFavorites),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        );
      }
    } else {
      final success = await favoriteNotifier.addToFavorite(jobId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addedToFavorites),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        );
      }
    }
  }
}
