import 'package:dio/dio.dart';

import '../config/dio_config.dart';
import '../constants/api_constants.dart';

class GuideService {
  late final Dio _dio;

  GuideService() {
    _dio = DioConfig.createDio(baseUrl: ApiConstants.baseUrl);
  }

  Future<Map<String, dynamic>> getAppGuide() async {
    try {
      final response = await _dio.get(ApiConstants.appGuide);
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể tải hướng dẫn sử dụng',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getApiDocumentation() async {
    try {
      final response = await _dio.get(ApiConstants.apiDocumentation);
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Không thể tải tài liệu API',
        };
      }
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }
}
