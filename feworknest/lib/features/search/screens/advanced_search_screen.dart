import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/search_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/search_suggestion_tile.dart';
import '../widgets/search_filter_chip.dart';
import '../widgets/job_recommendation_card.dart';

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _selectedLocation;
  String? _selectedJobType;
  String? _selectedExperienceLevel;
  double? _minSalary;
  double? _maxSalary;
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  
  bool _showFilters = false;
  bool _showSuggestions = false;
  bool _showRecommendations = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    
    // Load initial recommendations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      final userRole = user?.user?.role.toLowerCase() ?? 'candidate';
      ref.read(searchProvider(userRole).notifier).getJobRecommendations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    final user = ref.read(authProvider);
    final userRole = user?.user?.role.toLowerCase() ?? 'candidate';
    
    if (query.isNotEmpty) {
      setState(() {
        _showSuggestions = true;
        _showRecommendations = false;
      });
      
      // Get search suggestions
      ref.read(searchProvider(userRole).notifier).getSearchSuggestions(query);
      
      // Get search filters
      ref.read(searchProvider(userRole).notifier).getSearchFilters(query);
    } else {
      setState(() {
        _showSuggestions = false;
        _showRecommendations = true;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final user = ref.read(authProvider);
      final userRole = user?.user?.role.toLowerCase() ?? 'candidate';
      ref.read(searchProvider(userRole).notifier).loadMoreJobs();
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    final user = ref.read(authProvider);
    final userRole = user?.user?.role.toLowerCase() ?? 'candidate';
    
    if (query.isNotEmpty) {
      setState(() {
        _showSuggestions = false;
        _showRecommendations = false;
      });
      
      ref.read(searchProvider(userRole).notifier).searchJobs(
        keyword: query,
        location: _selectedLocation,
        jobType: _selectedJobType,
        minSalary: _minSalary,
        maxSalary: _maxSalary,
        experienceLevel: _selectedExperienceLevel,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
    }
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final userRole = user?.user?.role.toLowerCase() ?? 'candidate';
    final searchState = ref.watch(searchProvider(userRole));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm việc làm'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: _toggleFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm việc làm...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              final user = ref.read(authProvider);
                              final userRole = user?.user?.role.toLowerCase() ?? 'candidate';
                              ref.read(searchProvider(userRole).notifier).clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                
                // Filters Section
                if (_showFilters) ...[
                  const SizedBox(height: 16),
                  _buildFiltersSection(),
                ],
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: searchState.isLoading && searchState.jobs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bộ lọc',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Location Filter
        DropdownButtonFormField<String>(
          value: _selectedLocation,
          decoration: const InputDecoration(
            labelText: 'Địa điểm',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả')),
            const DropdownMenuItem(value: 'Ho Chi Minh City', child: Text('TP. Hồ Chí Minh')),
            const DropdownMenuItem(value: 'Hanoi', child: Text('Hà Nội')),
            const DropdownMenuItem(value: 'Da Nang', child: Text('Đà Nẵng')),
            const DropdownMenuItem(value: 'Remote', child: Text('Làm việc từ xa')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedLocation = value;
            });
          },
        ),
        
        const SizedBox(height: 12),
        
        // Job Type Filter
        DropdownButtonFormField<String>(
          value: _selectedJobType,
          decoration: const InputDecoration(
            labelText: 'Loại công việc',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả')),
            const DropdownMenuItem(value: 'Full-time', child: Text('Toàn thời gian')),
            const DropdownMenuItem(value: 'Part-time', child: Text('Bán thời gian')),
            const DropdownMenuItem(value: 'Contract', child: Text('Hợp đồng')),
            const DropdownMenuItem(value: 'Internship', child: Text('Thực tập')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedJobType = value;
            });
          },
        ),
        
        const SizedBox(height: 12),
        
        // Experience Level Filter
        DropdownButtonFormField<String>(
          value: _selectedExperienceLevel,
          decoration: const InputDecoration(
            labelText: 'Kinh nghiệm',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả')),
            const DropdownMenuItem(value: 'Junior', child: Text('Junior (0-2 năm)')),
            const DropdownMenuItem(value: 'Mid-level', child: Text('Mid-level (2-5 năm)')),
            const DropdownMenuItem(value: 'Senior', child: Text('Senior (5+ năm)')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedExperienceLevel = value;
            });
          },
        ),
        
        const SizedBox(height: 12),
        
        // Sort Options
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'Sắp xếp theo',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Ngày đăng')),
                  DropdownMenuItem(value: 'salary', child: Text('Lương')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortOrder,
                decoration: const InputDecoration(
                  labelText: 'Thứ tự',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'desc', child: Text('Giảm dần')),
                  DropdownMenuItem(value: 'asc', child: Text('Tăng dần')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortOrder = value!;
                  });
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Search Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _performSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tìm kiếm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(SearchState searchState) {
    if (searchState.error != null) {
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
              searchState.error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final user = ref.read(authProvider);
                final userRole = user?.user?.role.toLowerCase() ?? 'candidate';
                ref.read(searchProvider(userRole).notifier).clearError();
                _performSearch();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_showSuggestions) {
      return _buildSuggestions(searchState);
    }

    if (_showRecommendations) {
      return _buildRecommendations(searchState);
    }

    if (searchState.jobs.isNotEmpty) {
      return _buildSearchResults(searchState);
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Nhập từ khóa để tìm kiếm việc làm',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(SearchState searchState) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (searchState.suggestions.isNotEmpty) ...[
          const Text(
            'Gợi ý tìm kiếm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...searchState.suggestions.map((suggestion) => SearchSuggestionTile(
            suggestion: suggestion,
            onTap: () => _selectSuggestion(suggestion),
          )),
        ],
        
        if (searchState.filters.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Bộ lọc gợi ý',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searchState.filters.map((filter) => SearchFilterChip(
              label: filter,
              onTap: () {
                // Apply filter logic here
              },
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendations(SearchState searchState) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Gợi ý việc làm cho bạn',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (searchState.recommendations.isNotEmpty)
          ...searchState.recommendations.map((recommendation) => JobRecommendationCard(
            recommendation: recommendation,
            onTap: () {
              // Navigate to job detail
            },
          ))
        else
          const Center(
            child: Text(
              'Không có gợi ý nào',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    return Column(
      children: [
        // Results Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${searchState.totalCount} kết quả tìm kiếm',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (searchState.currentPage < searchState.totalPages)
                TextButton(
                  onPressed: () {
                    final user = ref.read(authProvider);
                    final userRole = user?.user?.role.toLowerCase() ?? 'candidate';
                    ref.read(searchProvider(userRole).notifier).loadMoreJobs();
                  },
                  child: const Text('Xem thêm'),
                ),
            ],
          ),
        ),
        
        // Results List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: searchState.jobs.length + (searchState.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == searchState.jobs.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final job = searchState.jobs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    job['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job['recruiter']?['company']?['name'] ?? ''),
                      Text('${job['location'] ?? ''} • ${job['salary'] ?? ''}'),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to job detail
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