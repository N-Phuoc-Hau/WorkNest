import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/token_storage.dart';
import '../models/interview_model.dart';

class InterviewService {
  final String _baseUrl = ApiConstants.baseUrl;

  Future<bool> scheduleInterview({
    required int applicationId,
    required DateTime scheduledAt,
    required String title,
    String? description,
    String? meetingLink,
    String? location,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.scheduleInterview}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'applicationId': applicationId,
          'scheduledAt': scheduledAt.toIso8601String(),
          'title': title,
          'description': description,
          'meetingLink': meetingLink,
          'location': location,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi khi lên lịch phỏng vấn');
      }
    } catch (e) {
      throw Exception('Lỗi khi lên lịch phỏng vấn: $e');
    }
  }

  Future<List<InterviewModel>> getMyInterviews() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.myInterviews}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => InterviewModel.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi khi tải danh sách phỏng vấn');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách phỏng vấn: $e');
    }
  }

  Future<bool> updateInterviewStatus({
    required int interviewId,
    required String status,
    String? notes,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl${ApiConstants.updateInterviewStatus}/$interviewId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi khi cập nhật trạng thái phỏng vấn');
      }
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái phỏng vấn: $e');
    }
  }

  Future<InterviewModel?> getInterviewById(int interviewId) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.getInterview}/$interviewId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return InterviewModel.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi khi tải thông tin phỏng vấn');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải thông tin phỏng vấn: $e');
    }
  }
}
