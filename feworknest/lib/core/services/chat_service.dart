import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/api_constants.dart';
import '../utils/token_storage.dart';
import 'auth_service.dart';

class ChatService {
  final Dio _dio;
  final AuthService _authService = AuthService();

  ChatService({Dio? dio}) : _dio = dio ?? Dio() {
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
          print('ChatService: Got 401, attempting token refresh...');
          
          final refreshToken = await TokenStorage.getRefreshToken();
          if (refreshToken != null && !await TokenStorage.isRefreshTokenExpired()) {
            try {
              // Try to refresh the token
              final refreshResult = await _authService.refreshToken(refreshToken);
              
              if (refreshResult['success'] == true) {
                print('ChatService: Token refresh successful');
                
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
                print('ChatService: Token refresh failed, clearing tokens');
                // Refresh failed, clear tokens and forward the original error
                await TokenStorage.clearAll();
              }
            } catch (refreshError) {
              print('ChatService: Exception during token refresh: $refreshError');
              // Refresh threw exception, clear tokens and forward original error
              await TokenStorage.clearAll();
            }
          } else {
            print('ChatService: No valid refresh token, clearing tokens');
            // No valid refresh token, clear all
            await TokenStorage.clearAll();
          }
        }
        
        // Forward the original error
        handler.next(error);
      },
    ));
  }

  /// Lấy danh sách phòng chat của user hiện tại
  Future<List<Map<String, dynamic>>> getUserChatRooms() async {
    try {
      final response = await _dio.get(ApiConstants.chatRooms);
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get chat rooms');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy số lượng tin nhắn chưa đọc
  Future<int> getUnreadMessagesCount() async {
    try {
      final response = await _dio.get('/api/Chat/unread-count');
      
      if (response.data['success'] == true) {
        return response.data['count'] as int? ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      print('Error getting unread messages count: $e');
      return 0;
    }
  }

  /// Tạo hoặc lấy phòng chat giữa recruiter và candidate
  Future<String> createOrGetChatRoom({
    required String recruiterId,
    required String candidateId,
    String? jobId,
    Map<String, dynamic>? recruiterInfo,
    Map<String, dynamic>? candidateInfo,
    Map<String, dynamic>? jobInfo,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.createChatRoom,
        data: {
          'recruiterId': recruiterId,
          'candidateId': candidateId,
          if (jobId != null) 'jobId': jobId,
          if (recruiterInfo != null) 'recruiterInfo': recruiterInfo,
          if (candidateInfo != null) 'candidateInfo': candidateInfo,
          if (jobInfo != null) 'jobInfo': jobInfo,
        },
      );
      
      if (response.data['success'] == true) {
        return response.data['roomId'];
      }
      throw Exception(response.data['message'] ?? 'Failed to create chat room');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy tin nhắn từ phòng chat
  Future<List<Map<String, dynamic>>> getChatMessages(
    String roomId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getChatMessages}/$roomId/messages',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get messages');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Gửi tin nhắn text
  Future<String> sendTextMessage({
    required String roomId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.sendTextMessage,
        data: {
          'roomId': roomId,
          'content': content,
        },
      );
      
      if (response.data['success'] == true) {
        return response.data['messageId'];
      }
      throw Exception(response.data['message'] ?? 'Failed to send message');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Gửi tin nhắn hình ảnh
  Future<Map<String, dynamic>> sendImageMessage({
    required String roomId,
    required XFile imageFile,
    String? caption,
  }) async {
    try {
      // Read file as bytes for cross-platform compatibility
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name;
      
      // Determine content type based on file extension
      String contentType = 'image/jpeg'; // default
      final extension = fileName.toLowerCase().split('.').last;
      
      // Validate supported image formats
      final supportedFormats = ['jpg', 'jpeg', 'png', 'gif'];
      if (!supportedFormats.contains(extension)) {
        throw Exception('Chỉ hỗ trợ định dạng ảnh JPEG, PNG và GIF');
      }
      
      switch (extension) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        default:
          contentType = 'image/jpeg';
      }
      
      print('ChatService: Uploading image - fileName: $fileName, contentType: $contentType, size: ${bytes.length} bytes');
      
      final formData = FormData.fromMap({
        'RoomId': roomId, // Match the API parameter name from Postman
        'ImageFile': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
        if (caption != null) 'caption': caption,
      });

      final response = await _dio.post(
        ApiConstants.sendImageMessage,
        data: formData,
      );
      
      print('ChatService: Image upload response: ${response.data}');
      
      if (response.data['success'] == true) {
        return {
          'messageId': response.data['messageId'],
          'imageUrl': response.data['imageUrl'],
        };
      }
      throw Exception(response.data['message'] ?? 'Failed to send image');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Đánh dấu tin nhắn đã đọc
  Future<void> markMessagesAsRead(String roomId) async {
    try {
      final response = await _dio.post('${ApiConstants.markChatAsRead}/$roomId/mark-read');
      
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to mark as read');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Xóa phòng chat (chỉ recruiter)
  Future<void> deleteChatRoom(String roomId) async {
    try {
      final response = await _dio.delete('${ApiConstants.deleteChatRoom}/$roomId');
      
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete chat room');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy thông tin phòng chat
  Future<Map<String, dynamic>> getChatRoomInfo(String roomId) async {
    try {
      final response = await _dio.get('${ApiConstants.getChatRoomInfo}/$roomId');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to get chat room info');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    print('ChatService Error: ${e.message}');
    print('Response: ${e.response?.data}');
    
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? 'Lỗi: ${e.response!.statusCode}';
      }
      return 'Lỗi: ${e.response!.statusCode}';
    }
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Timeout kết nối';
      case DioExceptionType.sendTimeout:
        return 'Timeout gửi dữ liệu';
      case DioExceptionType.receiveTimeout:
        return 'Timeout nhận dữ liệu';
      case DioExceptionType.connectionError:
        return 'Lỗi kết nối mạng';
      default:
        return 'Lỗi không xác định';
    }
  }
}
