import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

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
      print('DEBUG AuthService: Sending login request...');
      final response = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      print('DEBUG AuthService: Login SUCCESS, response received');
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
    } on DioException catch (e) {
      print('DEBUG AuthService: DioException caught - StatusCode: ${e.response?.statusCode}');
      if (e.response?.statusCode == 401) {
        print('DEBUG AuthService: 401 error, returning false with message');
        return {
          'success': false,
          'message': 'Sai tài khoản hoặc mật khẩu',
        };
      }
      print('DEBUG AuthService: Other DioException, returning false');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Đã có lỗi xảy ra, vui lòng thử lại.',
      };
    } catch (e) {
      print('DEBUG AuthService: General exception caught: $e');
      return {
        'success': false,
        'message': 'Đã có lỗi xảy ra, vui lòng thử lại.',
      };
    }
  }

  Future<Map<String, dynamic>> registerCandidate(Map<String, dynamic> userData) async {
    try {
      // Convert to FormData since backend expects multipart/form-data
      FormData formData = FormData.fromMap({
        'email': userData['email'],
        'password': userData['password'],
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
      });

      // Add avatar if provided
      if (userData['avatar'] != null && userData['avatar'].toString().isNotEmpty) {
        // If avatar is a URL, we need to handle it differently
        // For now, let's send it as a string field
        formData.fields.add(MapEntry('avatarUrl', userData['avatar']));
      }

      final response = await _dio.post(
        ApiConstants.registerCandidate, 
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return {
        'success': true,
        'message': response.data['message'],
        'userId': response.data['userId'],
      };
    } catch (e) {
      print('DEBUG AuthService: registerCandidate error: $e');
      if (e is DioException) {
        print('DEBUG AuthService: DioException response: ${e.response?.data}');
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
      // Convert to FormData since backend expects multipart/form-data
      FormData formData = FormData.fromMap({
        'email': userData['email'],
        'password': userData['password'],
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
        'companyName': userData['companyName'],
        'taxCode': userData['taxCode'],
        'description': userData['description'],
        'location': userData['location'],
      });

      // Add avatar if provided
      if (userData['avatar'] != null && userData['avatar'].toString().isNotEmpty) {
        formData.fields.add(MapEntry('avatarUrl', userData['avatar']));
      }

      // Add company images if provided
      if (userData['images'] != null) {
        List<String> imageUrls = List<String>.from(userData['images']);
        for (int i = 0; i < imageUrls.length; i++) {
          formData.fields.add(MapEntry('imageUrls[$i]', imageUrls[i]));
        }
      }

      final response = await _dio.post(
        ApiConstants.registerRecruiter, 
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return {
        'success': true,
        'message': response.data['message'],
        'userId': response.data['userId'],
      };
    } catch (e) {
      print('DEBUG AuthService: registerRecruiter error: $e');
      if (e is DioException) {
        print('DEBUG AuthService: DioException response: ${e.response?.data}');
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

  Future<Map<String, dynamic>> registerCandidateWithFiles(
    Map<String, dynamic> userData,
    XFile? avatarFile,
  ) async {
    try {
      // Create FormData with user data and files
      FormData formData = FormData.fromMap({
        'email': userData['email'],
        'password': userData['password'],
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
      });

      // Add avatar file if provided
      if (avatarFile != null) {
        if (kIsWeb) {
          final bytes = await avatarFile.readAsBytes();
          formData.files.add(MapEntry(
            'avatar',
            MultipartFile.fromBytes(
              bytes, 
              filename: avatarFile.name,
              contentType: _getMediaType(avatarFile.name),
            ),
          ));
        } else {
          formData.files.add(MapEntry(
            'avatar',
            await MultipartFile.fromFile(
              avatarFile.path, 
              filename: avatarFile.name,
              contentType: _getMediaType(avatarFile.name),
            ),
          ));
        }
      }

      final response = await _dio.post(
        ApiConstants.registerCandidate, 
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      return {
        'success': true,
        'message': response.data['message'],
        'userId': response.data['userId'],
      };
    } catch (e) {
      print('DEBUG AuthService: registerCandidateWithFiles error: $e');
      if (e is DioException) {
        print('DEBUG AuthService: DioException response: ${e.response?.data}');
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

  Future<Map<String, dynamic>> registerRecruiterWithFiles(
    Map<String, dynamic> userData,
    XFile? avatarFile,
    List<XFile> companyImageFiles,
  ) async {
    try {
      // Create FormData with user data
      FormData formData = FormData.fromMap({
        'email': userData['email'],
        'password': userData['password'],
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
        'companyName': userData['companyName'],
        'taxCode': userData['taxCode'],
        'description': userData['description'],
        'location': userData['location'],
      });

      // Add avatar file if provided
      if (avatarFile != null) {
        if (kIsWeb) {
          final bytes = await avatarFile.readAsBytes();
          formData.files.add(MapEntry(
            'avatar',
            MultipartFile.fromBytes(
              bytes, 
              filename: avatarFile.name,
              contentType: _getMediaType(avatarFile.name),
            ),
          ));
        } else {
          formData.files.add(MapEntry(
            'avatar',
            await MultipartFile.fromFile(
              avatarFile.path, 
              filename: avatarFile.name,
              contentType: _getMediaType(avatarFile.name),
            ),
          ));
        }
      }

      // Add company image files
      for (final imageFile in companyImageFiles) {
        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          formData.files.add(MapEntry(
            'images',
            MultipartFile.fromBytes(
              bytes, 
              filename: imageFile.name,
              contentType: _getMediaType(imageFile.name),
            ),
          ));
        } else {
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(
              imageFile.path, 
              filename: imageFile.name,
              contentType: _getMediaType(imageFile.name),
            ),
          ));
        }
      }

      final response = await _dio.post(
        ApiConstants.registerRecruiter, 
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      return {
        'success': true,
        'message': response.data['message'],
        'userId': response.data['userId'],
      };
    } catch (e) {
      print('DEBUG AuthService: registerRecruiterWithFiles error: $e');
      if (e is DioException) {
        print('DEBUG AuthService: DioException response: ${e.response?.data}');
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

  MediaType _getMediaType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg'); // Default fallback
    }
  }

}
