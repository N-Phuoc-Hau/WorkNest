import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/company_model.dart';
import '../models/follow_model.dart';
import '../utils/token_storage.dart';
import 'auth_service.dart';

class FollowService {
  final Dio _dio;
  final AuthService _authService = AuthService();

  FollowService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors by trying to refresh token
        if (error.response?.statusCode == 401) {
          print('FollowService: Got 401, attempting token refresh...');
          
          final refreshToken = await TokenStorage.getRefreshToken();
          if (refreshToken != null && !await TokenStorage.isRefreshTokenExpired()) {
            try {
              // Try to refresh the token
              final refreshResult = await _authService.refreshToken(refreshToken);
              
              if (refreshResult['success'] == true) {
                print('FollowService: Token refresh successful');
                
                // Update stored tokens
                await TokenStorage.updateTokens(
                  accessToken: refreshResult['access_token'],
                  refreshToken: refreshResult['refresh_token'],
                  accessTokenExpiresAt: DateTime.parse(refreshResult['access_token_expires_at']),
                  refreshTokenExpiresAt: DateTime.parse(refreshResult['refresh_token_expires_at']),
                );
                
                // Retry the original request with new token
                final newToken = refreshResult['access_token'];
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                
                // Clone and retry the request
                final clonedRequest = await _dio.request(
                  error.requestOptions.path,
                  options: Options(
                    method: error.requestOptions.method,
                    headers: error.requestOptions.headers,
                  ),
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                
                return handler.resolve(clonedRequest);
              } else {
                print('FollowService: Token refresh failed, clearing tokens');
                // Refresh failed, clear tokens and forward the original error
                await TokenStorage.clearAll();
              }
            } catch (refreshError) {
              print('FollowService: Exception during token refresh: $refreshError');
              // Refresh threw exception, clear tokens and forward original error
              await TokenStorage.clearAll();
            }
          } else {
            print('FollowService: No valid refresh token, clearing tokens');
            // No valid refresh token, clear all
            await TokenStorage.clearAll();
          }
        }
        
        // Forward the original error
        handler.next(error);
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
      
      // The API returns company data directly, so parse as CompanyModel
      final companies = (data['data'] as List)
          .map((json) => CompanyModel.fromJson(json))
          .toList();

      return {
        'companies': companies,
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
