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
        print('🌐 ApiService: *** Request Interceptor ***');
        print('🌐 ApiService: Base URL: ${_dio.options.baseUrl}');
        print('🌐 ApiService: Full URL: ${options.uri}');
        print('🌐 ApiService: Method: ${options.method}');
        print('🌐 ApiService: Path: ${options.path}');
        
        final token = await TokenStorage.getAccessToken();
        if (token != null) {
          print('🌐 ApiService: Token found, adding to headers');
          print('🌐 ApiService: Token preview: ${token.substring(0, 50)}...');
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          print('🌐 ApiService: ❌ No token found!');
        }
        
        print('🌐 ApiService: Request headers: ${options.headers}');
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors by trying to refresh token
        if (error.response?.statusCode == 401) {
          print('ApiService: Got 401, attempting token refresh...');

          // Skip refresh for auth endpoints themselves
          final isAuthEndpoint = error.requestOptions.path.contains('/Auth/login') ||
              error.requestOptions.path.contains('/Auth/register') ||
              error.requestOptions.path.contains('/Auth/refresh-token');
          if (isAuthEndpoint) {
            handler.next(error);
            return;
          }
          
          final refreshToken = await TokenStorage.getRefreshToken();
          if (refreshToken != null && !await TokenStorage.isRefreshTokenExpired()) {
            try {
              // Use a separate Dio instance to avoid interceptor loop
              final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
              final authResponse = await refreshDio.post(
                ApiConstants.refreshToken,
                data: {'refreshToken': refreshToken},
              );

              final data = authResponse.data;
              // Backend returns { accessToken, refreshToken, accessTokenExpiresAt, refreshTokenExpiresAt }
              final newAccessToken = data['accessToken'];
              final newRefreshToken = data['refreshToken'];

              if (newAccessToken != null && newRefreshToken != null) {
                print('ApiService: Token refresh successful');
                
                await TokenStorage.updateTokens(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken,
                  accessTokenExpiresAt: DateTime.parse(data['accessTokenExpiresAt']),
                  refreshTokenExpiresAt: DateTime.parse(data['refreshTokenExpiresAt']),
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
          await TokenStorage.clearAll();
        }
        
        handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      print('🌐 ApiService: GET request to: $path');
      print('🌐 ApiService: Query params: $queryParameters');
      
      final response = await _dio.get(path, queryParameters: queryParameters);
      
      print('🌐 ApiService: Response status: ${response.statusCode}');
      print('🌐 ApiService: Response data: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('🌐 ApiService: DioException caught in get()');
      print('🌐 ApiService: Error type: ${e.type}');
      print('🌐 ApiService: Status code: ${e.response?.statusCode}');
      print('🌐 ApiService: Error message: ${e.message}');
      print('🌐 ApiService: Response data: ${e.response?.data}');
      
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

  /// Generic request that returns dynamic (supports both List and Map responses)
  Future<dynamic> getDynamic(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      print('🌐 ApiService: GET (dynamic) request to: $path');
      final response = await _dio.get(path, queryParameters: queryParameters);
      print('🌐 ApiService: Response status: ${response.statusCode}');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> postDynamic(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
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
