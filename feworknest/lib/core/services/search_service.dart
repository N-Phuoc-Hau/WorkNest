import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class SearchService {
  late final Dio _dio;

  SearchService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  // Get search suggestions
  Future<Map<String, dynamic>> getSearchSuggestions(String query, {String userRole = 'candidate'}) async {
    try {
      final response = await _dio.get(
        ApiConstants.searchSuggestions,
        queryParameters: {
          'query': query,
          'userRole': userRole,
        },
      );

      return {
        'success': true,
        'suggestions': response.data['suggestions'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể lấy gợi ý tìm kiếm',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Get search filters
  Future<Map<String, dynamic>> getSearchFilters(String query, {String userRole = 'candidate'}) async {
    try {
      final response = await _dio.get(
        ApiConstants.searchFilters,
        queryParameters: {
          'query': query,
          'userRole': userRole,
        },
      );

      return {
        'success': true,
        'filters': response.data['filters'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể lấy bộ lọc tìm kiếm',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Search jobs with advanced filters
  Future<Map<String, dynamic>> searchJobs({
    String? keyword,
    String? location,
    String? jobType,
    double? minSalary,
    double? maxSalary,
    String? experienceLevel,
    String? sortBy = 'date',
    String? sortOrder = 'desc',
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParameters['keyword'] = keyword;
      }
      if (location != null && location.isNotEmpty) {
        queryParameters['location'] = location;
      }
      if (jobType != null && jobType.isNotEmpty) {
        queryParameters['jobType'] = jobType;
      }
      if (minSalary != null) {
        queryParameters['minSalary'] = minSalary;
      }
      if (maxSalary != null) {
        queryParameters['maxSalary'] = maxSalary;
      }
      if (experienceLevel != null && experienceLevel.isNotEmpty) {
        queryParameters['experienceLevel'] = experienceLevel;
      }

      final response = await _dio.get(
        ApiConstants.searchJobs,
        queryParameters: queryParameters,
      );

      return {
        'success': true,
        'jobs': response.data['jobs'],
        'totalCount': response.data['totalCount'],
        'page': response.data['page'],
        'pageSize': response.data['pageSize'],
        'totalPages': response.data['totalPages'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể tìm kiếm việc làm',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Get job recommendations
  Future<Map<String, dynamic>> getJobRecommendations() async {
    try {
      final response = await _dio.get(ApiConstants.jobRecommendations);

      return {
        'success': true,
        'recommendations': response.data['recommendations'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể lấy gợi ý việc làm',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Get candidate recommendations
  Future<Map<String, dynamic>> getCandidateRecommendations(String jobId) async {
    try {
      final response = await _dio.get('${ApiConstants.candidateRecommendations}/$jobId');

      return {
        'success': true,
        'recommendations': response.data['recommendations'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể lấy gợi ý ứng viên',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Get search history
  Future<Map<String, dynamic>> getSearchHistory() async {
    try {
      final response = await _dio.get(ApiConstants.searchHistory);

      return {
        'success': true,
        'searchHistory': response.data['searchHistory'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể lấy lịch sử tìm kiếm',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Save search
  Future<Map<String, dynamic>> saveSearch(String name, Map<String, dynamic> searchCriteria) async {
    try {
      final response = await _dio.post(
        ApiConstants.saveSearch,
        data: {
          'name': name,
          'searchCriteria': searchCriteria,
        },
      );

      return {
        'success': true,
        'message': response.data['message'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể lưu tìm kiếm',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }
} 