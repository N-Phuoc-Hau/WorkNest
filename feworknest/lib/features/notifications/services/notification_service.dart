import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/utils/token_storage.dart';

class NotificationService {
  final String _baseUrl = ApiConstants.baseUrl;

  Future<List<NotificationModel>> getNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.notifications}?page=$page&pageSize=$pageSize'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> notifications = responseData['notifications'] ?? [];
        return notifications.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi khi tải thông báo');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải thông báo: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.unreadCount}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unreadCount'] as int;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl${ApiConstants.markAsRead}/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Lỗi khi đánh dấu đã đọc: $e');
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl${ApiConstants.markAllAsRead}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Lỗi khi đánh dấu tất cả: $e');
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl${ApiConstants.notifications}/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Lỗi khi xóa thông báo: $e');
    }
  }

  Future<NotificationModel?> getNotificationById(int notificationId) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.notifications}/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return NotificationModel.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi khi tải thông báo');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải thông báo: $e');
    }
  }
}
