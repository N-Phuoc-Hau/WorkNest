import 'package:dio/dio.dart';
import '../models/follow_model.dart';
import '../constants/api_constants.dart';
import '../utils/token_storage.dart';

class FollowService {
  final Dio _dio;

  FollowService({Dio? dio}) : _dio = dio ?? Dio() {
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

  Future<void> followCompany(CreateFollowModel createFollow) async {
    try {
      await _dio.post(
        '/api/Follow',
        data: createFollow.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unfollowCompany(int companyId) async {
    try {
      await _dio.delete('/api/Follow/$companyId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMyFollowing({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/Follow/my-following',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      final follows = (data['data'] as List)
          .map((json) => FollowModel.fromJson(json))
          .toList();

      return {
        'follows': follows,
        'totalCount': data['totalCount'],
        'page': data['page'],
        'pageSize': data['pageSize'],
        'totalPages': data['totalPages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMyFollowers({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/Follow/followers',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      final followers = (data['data'] as List)
          .map((json) => FollowModel.fromJson(json))
          .toList();

      return {
        'followers': followers,
        'totalCount': data['totalCount'],
        'page': data['page'],
        'pageSize': data['pageSize'],
        'totalPages': data['totalPages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> isFollowing(int companyId) async {
    try {
      final response = await _dio.get('/api/Follow/company/$companyId/is-following');
      return response.data['isFollowing'] as bool;
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
