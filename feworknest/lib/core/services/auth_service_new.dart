import 'package:dio/dio.dart';

class AuthService {
  static const String baseUrl = 'https://localhost:5006/api'; // Replace with your C# API URL
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      // Backend C# trả về: { token, user }
      final user = response.data['user'];
      
      return {
        'success': true,
        'user': user,
        'access_token': response.data['token'],
        'role': user['role'], // Role có trong user object
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
      final response = await _dio.post('/auth/register/candidate', data: userData);

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
      final response = await _dio.post('/auth/register/recruiter', data: userData);

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
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));
      
      final response = await dio.get('/auth/profile');

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
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));
      
      final response = await dio.put('/auth/profile', data: profileData);

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

}
