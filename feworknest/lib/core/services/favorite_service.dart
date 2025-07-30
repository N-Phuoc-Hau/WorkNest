import 'package:dio/dio.dart';
import '../models/favorite_model.dart';
import '../constants/api_constants.dart';
import '../utils/token_storage.dart';

class FavoriteService {
  final Dio _dio;

  FavoriteService({Dio? dio}) : _dio = dio ?? Dio() {
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

  Future<void> addToFavorite(int jobId) async {
    try {
      await _dio.post('/api/Favorite/$jobId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeFromFavorite(int jobId) async {
    try {
      await _dio.delete('/api/Favorite/$jobId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMyFavorites({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/Favorite/my-favorites',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      final favorites = (data['favorites'] as List)
          .map((json) => FavoriteJobDto.fromJson(json))
          .toList();

      return {
        'favorites': favorites,
        'totalCount': data['totalCount'],
        'currentPage': data['currentPage'],
        'pageSize': data['pageSize'],
        'totalPages': data['totalPages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> checkFavoriteStatus(int jobId) async {
    try {
      final response = await _dio.get('/api/Favorite/check/$jobId');
      return response.data['isFavorited'] as bool;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FavoriteStatsModel> getFavoriteStats() async {
    try {
      final response = await _dio.get('/api/Favorite/stats');
      return FavoriteStatsModel.fromJson(response.data);
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
