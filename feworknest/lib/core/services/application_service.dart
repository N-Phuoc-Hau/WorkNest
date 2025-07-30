import 'package:dio/dio.dart';
import 'dart:io';
import '../models/application_model.dart';
import '../constants/api_constants.dart';
import '../utils/token_storage.dart';

class ApplicationService {
  final Dio _dio;

  ApplicationService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<ApplicationModel> createApplication({
    required CreateApplicationModel createApplication,
    File? cvFile,
  }) async {
    try {
      final formData = FormData();
      
      // Add JSON data
      formData.fields.addAll([
        MapEntry('jobId', createApplication.jobId.toString()),
        if (createApplication.coverLetter != null)
          MapEntry('coverLetter', createApplication.coverLetter!),
      ]);

      // Add CV file if provided
      if (cvFile != null) {
        formData.files.add(
          MapEntry(
            'cvFile',
            await MultipartFile.fromFile(
              cvFile.path,
              filename: cvFile.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        '/api/Application',
        data: formData,
      );

      return ApplicationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApplicationModel> getApplication(int id) async {
    try {
      final response = await _dio.get('/api/Application/$id');
      return ApplicationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMyApplications({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/Application/my-applications',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      final applications = (data['data'] as List)
          .map((json) => ApplicationModel.fromJson(json))
          .toList();

      return {
        'applications': applications,
        'totalCount': data['totalCount'],
        'page': data['page'],
        'pageSize': data['pageSize'],
        'totalPages': data['totalPages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateApplicationStatus(
    int id,
    UpdateApplicationStatusModel updateStatus,
  ) async {
    try {
      await _dio.put(
        '/api/Application/$id/status',
        data: updateStatus.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getJobApplications(
    int jobId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/Application/job/$jobId/applications',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      final applications = (data['data'] as List)
          .map((json) => ApplicationModel.fromJson(json))
          .toList();

      return {
        'applications': applications,
        'totalCount': data['totalCount'],
        'page': data['page'],
        'pageSize': data['pageSize'],
        'totalPages': data['totalPages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteApplication(int id) async {
    try {
      await _dio.delete('/api/Application/$id');
    } on DioException catch (e) {
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
