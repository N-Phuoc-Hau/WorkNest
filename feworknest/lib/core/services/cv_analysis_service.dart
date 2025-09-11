import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cv_analysis_models.dart';
import '../utils/cross_platform_file.dart';
import 'api_service.dart';

class CVAnalysisService {
  final ApiService _apiService;

  CVAnalysisService(this._apiService);

  /// Phân tích CV từ file
  Future<CVAnalysisResponse> analyzeCVFromFile(CrossPlatformFile cvFile) async {
    try {
      final bytes = await cvFile.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: cvFile.name,
      );

      final formData = FormData.fromMap({
        'cvFile': multipartFile,
      });

      // Use a separate dio instance for multipart upload
      final token = await _apiService.getAuthToken();
      final dio = Dio();
      dio.options.baseUrl = _apiService.baseUrl;
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await dio.post(
        '/cvanalysis/analyze-file',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data['success'] == true) {
        return CVAnalysisResponse.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Lỗi khi phân tích CV');
      }
    } catch (e) {
      throw Exception('Lỗi khi phân tích CV: $e');
    }
  }

  /// Get CV analysis for a specific application
  Future<CVAnalysisResponse?> getCVAnalysisForApplication(int applicationId) async {
    try {
      final response = await _apiService.get('/api/Application/$applicationId/cv-analysis');
      
      // Check if response contains analysis data
      if (response != null && response['applicationId'] != null) {
        // Convert backend response to our CVAnalysisResponse format
        final extractedSkills = List<String>.from(response['extractedSkills'] ?? []);
        
        return CVAnalysisResponse(
          analysisId: response['applicationId'].toString(),
          userId: '', // Not provided in response
          profile: CVProfile(
            skills: extractedSkills,
            technicalSkills: extractedSkills,
            softSkills: [],
            experienceYears: 0,
            educationLevel: '',
            degrees: [],
            certifications: [],
            workHistory: [],
            projects: [],
            languages: [],
            industries: [],
          ),
          scores: CVScoreBreakdown(
            overallScore: (response['matchScore'] ?? 0).round(),
            skillsScore: (response['matchScore'] ?? 0).round(),
            experienceScore: (response['matchScore'] ?? 0).round(),
            educationScore: (response['matchScore'] ?? 0).round(),
            projectsScore: 0,
            certificationsScore: 0,
            categoryScores: {},
          ),
          strengths: List<String>.from(response['strengths'] ?? []),
          weaknesses: List<String>.from(response['weaknesses'] ?? []),
          improvementSuggestions: List<String>.from(response['improvementSuggestions'] ?? []),
          recommendedJobs: [],
          detailedAnalysis: response['detailedAnalysis'] ?? '',
          analyzedAt: response['analyzedAt'] != null 
            ? DateTime.parse(response['analyzedAt'])
            : DateTime.now(),
        );
      } else {
        // No analysis available yet or in progress
        return null;
      }
    } catch (e) {
      print('Error getting CV analysis for application: $e');
      return null;
    }
  }

  /// Trigger CV analysis for a specific application
  Future<bool> triggerCVAnalysisForApplication(int applicationId) async {
    try {
      await _apiService.post('/api/Application/$applicationId/trigger-cv-analysis');
      return true; // If no exception, request was successful
    } catch (e) {
      print('Error triggering CV analysis for application: $e');
      return false;
    }
  }

  /// Phân tích CV từ text
  Future<CVAnalysisResponse> analyzeCVFromText(String cvText) async {
    try {
      final response = await _apiService.post('/cvanalysis/analyze-text', data: {
        'cvText': cvText,
      });

      if (response['success'] == true) {
        return CVAnalysisResponse.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi phân tích CV');
      }
    } catch (e) {
      throw Exception('Lỗi khi phân tích CV: $e');
    }
  }

  /// Lấy lịch sử phân tích CV
  Future<List<CVAnalysisHistory>> getAnalysisHistory({
    int pageSize = 10,
    int pageNumber = 1,
  }) async {
    try {
      final response = await _apiService.get(
        '/cvanalysis/history',
        queryParameters: {
          'pageSize': pageSize,
          'pageNumber': pageNumber,
        },
      );

      if (response['success'] == true) {
        return (response['data'] as List<dynamic>)
            .map((item) => CVAnalysisHistory.fromJson(item))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi lấy lịch sử phân tích');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy lịch sử phân tích: $e');
    }
  }

  /// Lấy chi tiết phân tích CV
  Future<CVAnalysisResponse?> getAnalysisDetail(String analysisId) async {
    try {
      final response = await _apiService.get('/cvanalysis/analysis/$analysisId');

      if (response['success'] == true) {
        return CVAnalysisResponse.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi lấy chi tiết phân tích');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy chi tiết phân tích: $e');
    }
  }

  /// Lấy gợi ý việc làm dựa trên CV
  Future<List<JobRecommendationAnalytics>> getJobRecommendations({
    String? cvText,
    int maxRecommendations = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'maxRecommendations': maxRecommendations,
      };

      if (cvText != null && cvText.isNotEmpty) {
        queryParams['cvText'] = cvText;
      }

      final response = await _apiService.get(
        '/cvanalysis/job-recommendations',
        queryParameters: queryParams,
      );

      if (response['success'] == true) {
        return (response['data'] as List<dynamic>)
            .map((item) => JobRecommendationAnalytics.fromJson(item))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi lấy gợi ý việc làm');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy gợi ý việc làm: $e');
    }
  }

  /// Lấy thống kê phân tích CV
  Future<CVAnalysisStats> getAnalysisStats() async {
    try {
      final response = await _apiService.get('/cvanalysis/stats');

      if (response['success'] == true) {
        return CVAnalysisStats.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Lỗi khi lấy thống kê phân tích');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy thống kê phân tích: $e');
    }
  }

  /// Pick CV file với hỗ trợ web và mobile
  Future<CrossPlatformFile?> pickCVFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: false,
        withData: kIsWeb, // Only load data for web platform
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (kIsWeb) {
          // For web platform, create from bytes
          if (file.bytes != null && file.name.isNotEmpty) {
            return CrossPlatformFile.fromBytes(file.bytes!, file.name);
          }
        } else {
          // For mobile platforms, create from File
          if (file.path != null) {
            return CrossPlatformFile.fromFile(File(file.path!));
          }
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Lỗi khi chọn file: $e');
    }
  }

  /// Validate file CV với hỗ trợ web và mobile
  bool isValidCVFile(CrossPlatformFile file) {
    return file.isValidCVFile;
  }

  /// Get file size in readable format với hỗ trợ web
  String getFileSizeString(CrossPlatformFile file) {
    return file.sizeString;
  }
}

// Provider
final cvAnalysisServiceProvider = Provider<CVAnalysisService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CVAnalysisService(apiService);
});
