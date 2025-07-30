import 'package:dio/dio.dart';

import '../config/dio_config.dart';
import '../constants/api_constants.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = DioConfig.createDio(baseUrl: ApiConstants.baseUrl);
  }

  // Test connection method
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get(
        ApiConstants.jobs, // Test với JobPost endpoint thay vì /api
        queryParameters: {'page': 1, 'pageSize': 1}, // Minimal query
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode != null && response.statusCode! < 400;
    } catch (e) {
      // If we get any response, even 404, server is running
      if (e is DioException && e.response != null) {
        return e.response!.statusCode! < 500;
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      // Backend C# trả về: { accessToken, refreshToken, accessTokenExpiresAt, refreshTokenExpiresAt, user }
      final user = response.data['user'];
      
      return {
        'success': true,
        'user': user,
        'access_token': response.data['accessToken'],
        'refresh_token': response.data['refreshToken'],
        'access_token_expires_at': response.data['accessTokenExpiresAt'],
        'refresh_token_expires_at': response.data['refreshTokenExpiresAt'],
        'role': user['role'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Đăng nhập thất bại',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> registerCandidate(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(ApiConstants.registerCandidate, data: userData);

      return {
        'success': true,
        'message': response.data['message'],
        'userId': response.data['userId'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Đăng ký thất bại',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> registerRecruiter(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(ApiConstants.registerRecruiter, data: userData);

      return {
        'success': true,
        'message': response.data['message'],
        'userId': response.data['userId'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Đăng ký thất bại',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String token) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl, // Không thêm /api ở đây
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));
      
      final response = await dio.get(ApiConstants.profile);

      return {
        'success': true,
        'user': response.data,
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể lấy thông tin người dùng',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl, // Không thêm /api ở đây
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));
      
      final response = await dio.put(ApiConstants.profile, data: profileData);

      return {
        'success': true,
        'message': response.data['message'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể cập nhật thông tin',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Check token status
  Future<Map<String, dynamic>> checkTokenStatus(String token) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));
      
      final response = await dio.get(ApiConstants.tokenStatus);

      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Token không hợp lệ hoặc đã hết hạn',
      };
    }
  }

  // Refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(ApiConstants.refreshToken, data: {
        'refreshToken': refreshToken,
      });

      return {
        'success': true,
        'access_token': response.data['accessToken'],
        'refresh_token': response.data['refreshToken'],
        'access_token_expires_at': response.data['accessTokenExpiresAt'],
        'refresh_token_expires_at': response.data['refreshTokenExpiresAt'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể làm mới token',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Revoke token
  Future<Map<String, dynamic>> revokeToken(String refreshToken) async {
    try {
      final response = await _dio.post(ApiConstants.revokeToken, data: {
        'refreshToken': refreshToken,
      });

      return {
        'success': true,
        'message': response.data['message'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể thu hồi token',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Revoke all tokens
  Future<Map<String, dynamic>> revokeAllTokens() async {
    try {
      final response = await _dio.post(ApiConstants.revokeAllTokens);

      return {
        'success': true,
        'message': response.data['message'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể thu hồi tất cả token',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  // Get app guide
  Future<Map<String, dynamic>> getAppGuide() async {
    try {
      final response = await _dio.get(ApiConstants.appGuide);
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể tải hướng dẫn',
      };
    }
  }

  // Get API documentation
  Future<Map<String, dynamic>> getApiDocumentation() async {
    try {
      final response = await _dio.get(ApiConstants.apiDocumentation);
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể tải tài liệu API',
      };
    }
  }

}
