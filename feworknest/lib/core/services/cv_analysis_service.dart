import 'package:dio/dio.dart';

import '../config/dio_config.dart';
import '../constants/api_constants.dart';
import '../models/cv_analysis_model.dart';
import '../utils/token_storage.dart';

class CVAnalysisService {
  final Dio _dio;

  CVAnalysisService({Dio? dio}) : _dio = dio ?? DioConfig.createDio(baseUrl: ApiConstants.baseUrl) {
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        print('DEBUG CVAnalysisService: HTTP Error: ${error.response?.statusCode}');
        print('DEBUG CVAnalysisService: Error data: ${error.response?.data}');
        handler.next(error);
      },
    ));
  }

  /// Get CV Analysis Result for a specific application
  Future<CVAnalysisResult?> getCVAnalysis(int applicationId) async {
    try {
      print('DEBUG CVAnalysisService: Getting CV analysis for application $applicationId');
      
      final response = await _dio.get('/api/application/$applicationId/cv-analysis');
      
      print('DEBUG CVAnalysisService: CV analysis response received');
      
      // Check if analysis is available
      if (response.data.containsKey('message')) {
        print('DEBUG CVAnalysisService: Analysis not available: ${response.data['message']}');
        return null;
      }
      
      return CVAnalysisResult.fromJson(response.data);
    } on DioException catch (e) {
      print('DEBUG CVAnalysisService: Error getting CV analysis: ${e.message}');
      throw _handleError(e);
    }
  }

  /// Trigger CV Analysis for an application (if not already done)
  Future<void> requestCVAnalysis(int applicationId) async {
    try {
      print('DEBUG CVAnalysisService: Requesting CV analysis for application $applicationId');
      
      await _dio.post('/api/application/$applicationId/analyze-cv');
      
      print('DEBUG CVAnalysisService: CV analysis request sent successfully');
    } on DioException catch (e) {
      print('DEBUG CVAnalysisService: Error requesting CV analysis: ${e.message}');
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
