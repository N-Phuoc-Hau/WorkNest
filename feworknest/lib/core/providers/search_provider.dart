import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/search_service.dart';

// Search State
class SearchState {
  final List<Map<String, dynamic>> jobs;
  final List<String> suggestions;
  final List<String> filters;
  final List<Map<String, dynamic>> recommendations;
  final List<Map<String, dynamic>> searchHistory;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final Map<String, dynamic> currentFilters;

  const SearchState({
    this.jobs = const [],
    this.suggestions = const [],
    this.filters = const [],
    this.recommendations = const [],
    this.searchHistory = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 0,
    this.totalCount = 0,
    this.currentFilters = const {},
  });

  SearchState copyWith({
    List<Map<String, dynamic>>? jobs,
    List<String>? suggestions,
    List<String>? filters,
    List<Map<String, dynamic>>? recommendations,
    List<Map<String, dynamic>>? searchHistory,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    Map<String, dynamic>? currentFilters,
  }) {
    return SearchState(
      jobs: jobs ?? this.jobs,
      suggestions: suggestions ?? this.suggestions,
      filters: filters ?? this.filters,
      recommendations: recommendations ?? this.recommendations,
      searchHistory: searchHistory ?? this.searchHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      currentFilters: currentFilters ?? this.currentFilters,
    );
  }
}

// Search Notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _searchService;
  final String _userRole;

  SearchNotifier(this._searchService, this._userRole) : super(const SearchState());

  // Get search suggestions
  Future<void> getSearchSuggestions(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(suggestions: [], error: null);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _searchService.getSearchSuggestions(query, userRole: _userRole);
      
      if (result['success'] == true) {
        state = state.copyWith(
          suggestions: List<String>.from(result['suggestions']),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result['message'],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Có lỗi xảy ra: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // Get search filters
  Future<void> getSearchFilters(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(filters: [], error: null);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _searchService.getSearchFilters(query, userRole: _userRole);
      
      if (result['success'] == true) {
        state = state.copyWith(
          filters: List<String>.from(result['filters']),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result['message'],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Có lỗi xảy ra: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // Search jobs
  Future<void> searchJobs({
    String? keyword,
    String? location,
    String? jobType,
    double? minSalary,
    double? maxSalary,
    String? experienceLevel,
    String? sortBy = 'date',
    String? sortOrder = 'desc',
    int page = 1,
    bool loadMore = false,
  }) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await _searchService.searchJobs(
        keyword: keyword,
        location: location,
        jobType: jobType,
        minSalary: minSalary,
        maxSalary: maxSalary,
        experienceLevel: experienceLevel,
        sortBy: sortBy,
        sortOrder: sortOrder,
        page: page,
      );
      
      if (result['success'] == true) {
        final newJobs = List<Map<String, dynamic>>.from(result['jobs']);
        final currentJobs = loadMore ? state.jobs : [];
        
        state = state.copyWith(
          jobs: [...currentJobs, ...newJobs],
          currentPage: result['page'],
          totalPages: result['totalPages'],
          totalCount: result['totalCount'],
          currentFilters: {
            'keyword': keyword,
            'location': location,
            'jobType': jobType,
            'minSalary': minSalary,
            'maxSalary': maxSalary,
            'experienceLevel': experienceLevel,
            'sortBy': sortBy,
            'sortOrder': sortOrder,
          },
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result['message'],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Có lỗi xảy ra: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // Get job recommendations
  Future<void> getJobRecommendations() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _searchService.getJobRecommendations();
      
      if (result['success'] == true) {
        state = state.copyWith(
          recommendations: List<Map<String, dynamic>>.from(result['recommendations']),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result['message'],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Có lỗi xảy ra: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // Get candidate recommendations
  Future<void> getCandidateRecommendations(String jobId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _searchService.getCandidateRecommendations(jobId);
      
      if (result['success'] == true) {
        state = state.copyWith(
          recommendations: List<Map<String, dynamic>>.from(result['recommendations']),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result['message'],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Có lỗi xảy ra: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // Get search history
  Future<void> getSearchHistory() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _searchService.getSearchHistory();
      
      if (result['success'] == true) {
        state = state.copyWith(
          searchHistory: List<Map<String, dynamic>>.from(result['searchHistory']),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result['message'],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Có lỗi xảy ra: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // Save search
  Future<void> saveSearch(String name, Map<String, dynamic> searchCriteria) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _searchService.saveSearch(name, searchCriteria);
      
      if (result['success'] == true) {
        state = state.copyWith(
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result['message'],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Có lỗi xảy ra: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // Load more jobs
  Future<void> loadMoreJobs() async {
    if (state.currentPage < state.totalPages && !state.isLoading) {
      await searchJobs(
        keyword: state.currentFilters['keyword'],
        location: state.currentFilters['location'],
        jobType: state.currentFilters['jobType'],
        minSalary: state.currentFilters['minSalary'],
        maxSalary: state.currentFilters['maxSalary'],
        experienceLevel: state.currentFilters['experienceLevel'],
        sortBy: state.currentFilters['sortBy'],
        sortOrder: state.currentFilters['sortOrder'],
        page: state.currentPage + 1,
        loadMore: true,
      );
    }
  }

  // Clear search results
  void clearSearch() {
    state = state.copyWith(
      jobs: [],
      suggestions: [],
      filters: [],
      currentPage: 1,
      totalPages: 0,
      totalCount: 0,
      currentFilters: {},
      error: null,
    );
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

final searchProvider = StateNotifierProvider.family<SearchNotifier, SearchState, String>((ref, userRole) {
  final searchService = ref.watch(searchServiceProvider);
  return SearchNotifier(searchService, userRole);
}); 