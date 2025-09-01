import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/api_constants.dart';
import '../utils/token_storage.dart';

class ApiService {
  final Dio _dio;

  ApiService({Dio? dio}) : _dio = dio ?? Dio() {
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
          print('ApiService: Got 401, attempting token refresh...');
          
          final refreshToken = await TokenStorage.getRefreshToken();
          if (refreshToken != null && !await TokenStorage.isRefreshTokenExpired()) {
            try {
              final authResponse = await _dio.post(
                ApiConstants.refreshToken,
                data: {'refreshToken': refreshToken},
              );

              if (authResponse.data['success'] == true) {
                final newAccessToken = authResponse.data['data']['accessToken'];
                final newRefreshToken = authResponse.data['data']['refreshToken'];
                
                await TokenStorage.saveTokens(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken,
                  accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
                  refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
                );
                
                // Retry the original request with the new token
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                
                final cloneReq = await _dio.fetch(opts);
                handler.resolve(cloneReq);
                return;
              }
            } catch (refreshError) {
              print('ApiService: Failed to refresh token: $refreshError');
            }
          }
          
          // Clear tokens and let the error pass through
          await TokenStorage.clearTokens();
        }
        
        handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Uint8List?> downloadFile(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          },
        ),
      );

      if (response.data != null) {
        final bytes = response.data as Uint8List;
        
        // Save to downloads folder (platform specific)
        try {
          final directory = await _getDownloadsDirectory();
          final fileName = _extractFileNameFromPath(path);
          final file = File('${directory.path}/$fileName');
          
          await file.writeAsBytes(bytes);
          print('File saved to: ${file.path}');
        } catch (e) {
          print('Could not save file to downloads: $e');
        }
        
        return bytes;
      }
      return null;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // For Android, try to get the Downloads directory
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory;
      }
    }
    
    // Fallback to documents directory
    return await getApplicationDocumentsDirectory();
  }

  String _extractFileNameFromPath(String path) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (path.contains('excel')) {
      return 'Analytics_Report_$timestamp.xlsx';
    }
    return 'download_$timestamp.file';
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      switch (statusCode) {
        case 400:
          return data['message'] ?? 'Dữ liệu không hợp lệ';
        case 401:
          return 'Không có quyền truy cập. Vui lòng đăng nhập lại';
        case 403:
          return 'Không có quyền thực hiện hành động này';
        case 404:
          return 'Không tìm thấy dữ liệu';
        case 500:
          return 'Lỗi hệ thống. Vui lòng thử lại sau';
        default:
          return data['message'] ?? 'Có lỗi xảy ra';
      }
    } else {
      // Network error
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet';
    }
  }

  // Getter methods for accessing internal properties
  String get baseUrl => _dio.options.baseUrl;
  
  Future<String?> getAuthToken() async {
    return await TokenStorage.getAccessToken();
  }
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
