import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/review_model.dart';
import '../utils/token_storage.dart';

class ReviewService {
  final Dio _dio;

  ReviewService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<ReviewModel> createCandidateReview(
    CreateCandidateReviewModel createReview,
  ) async {
    try {
      final response = await _dio.post(
        '/api/Review/candidate-review',
        data: createReview.toJson(),
      );
      return ReviewModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ReviewModel> createRecruiterReview(
    CreateRecruiterReviewModel createReview,
  ) async {
    try {
      final response = await _dio.post(
        '/api/Review/recruiter-review',
        data: createReview.toJson(),
      );
      return ReviewModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserReviews(
    String userId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/Review/user/$userId',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      final reviews = (data['data'] as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();

      return {
        'reviews': reviews,
        'totalCount': data['totalCount'],
        'page': data['page'],
        'pageSize': data['pageSize'],
        'totalPages': data['totalPages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCompanyReviews(
    int companyId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      print('🔍 ReviewService: Getting company reviews for companyId: $companyId');
      final response = await _dio.get(
        '/api/Review/company/$companyId',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      print('🔍 ReviewService: Raw response: ${response.data}');
      final data = response.data;
      print('🔍 ReviewService: Data structure: ${data.runtimeType}');
      print('🔍 ReviewService: Data keys: ${data is Map ? data.keys.toList() : 'Not a map'}');
      
      final reviews = (data['data'] as List)
          .map((json) {
            print('🔍 ReviewService: Processing review json: $json');
            return ReviewModel.fromJson(json);
          })
          .toList();

      print('🔍 ReviewService: Parsed ${reviews.length} reviews successfully');
      return {
        'reviews': reviews,
        'totalCount': data['totalCount'],
        'page': data['page'],
        'pageSize': data['pageSize'],
        'totalPages': data['totalPages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMyReviews({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/Review/my-reviews',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      final reviews = (data['data'] as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();

      return {
        'reviews': reviews,
        'totalCount': data['totalCount'],
        'page': data['page'],
        'pageSize': data['pageSize'],
        'totalPages': data['totalPages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteReview(int id) async {
    try {
      await _dio.delete('/api/Review/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'];
      }
      return 'Lỗi: ${e.response!.statusCode}';
    }
    return 'Lỗi kết nối mạng';
  }
}
