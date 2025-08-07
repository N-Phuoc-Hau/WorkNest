import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/api_constants.dart';
import '../models/application_model.dart';
import '../utils/token_storage.dart';

class ApplicationService {
  final Dio _dio;

  ApplicationService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getAccessToken();
        print('DEBUG ApplicationService: Token from storage: ${token != null ? "EXISTS" : "NULL"}');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('DEBUG ApplicationService: Authorization header set');
        } else {
          print('DEBUG ApplicationService: No token found, request will fail');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        print('DEBUG ApplicationService: HTTP Error: ${error.response?.statusCode}');
        print('DEBUG ApplicationService: Error data: ${error.response?.data}');
        handler.next(error);
      },
    ));
  }

  /// Submit job application with PDF CV file
  /// 
  /// [jobId] - ID của job post cần ứng tuyển
  /// [coverLetter] - Thư xin việc
  /// [cvFile] - File CV dạng PDF (cho mobile/desktop)
  /// [cvXFile] - File CV dạng XFile (cho web)
  Future<ApplicationModel> submitApplication({
    required int jobId,
    required String coverLetter,
    File? cvFile,
    XFile? cvXFile,
  }) async {
    // Validate inputs
    if (coverLetter.trim().isEmpty) {
      throw Exception('Cover letter không được để trống');
    }

    if (cvFile == null && cvXFile == null) {
      throw Exception('Vui lòng chọn file CV');
    }

    // Validate file type (PDF only)
    String? fileName;
    if (cvFile != null) {
      fileName = cvFile.path.split('/').last.toLowerCase();
    } else if (cvXFile != null) {
      fileName = cvXFile.name.toLowerCase();
    }

    if (fileName != null && !fileName.endsWith('.pdf')) {
      throw Exception('Chỉ chấp nhận file PDF cho CV');
    }

    return await createApplication(
      jobId: jobId,
      coverLetter: coverLetter,
      cvFile: cvFile,
      cvXFile: cvXFile,
    );
  }

  Future<ApplicationModel> createApplication({
    required int jobId,
    required String coverLetter,
    File? cvFile,
    XFile? cvXFile, // For web compatibility
  }) async {
    try {
      final formData = FormData();
      
      // Add required fields
      formData.fields.addAll([
        MapEntry('jobId', jobId.toString()),
        MapEntry('coverLetter', coverLetter),
      ]);

      // Add CV file - support both File and XFile
      if (cvFile != null) {
        // Mobile/Desktop version
        formData.files.add(
          MapEntry(
            'cvFile',
            await MultipartFile.fromFile(
              cvFile.path,
              filename: cvFile.path.split('/').last,
              contentType: MediaType('application', 'pdf'),
            ),
          ),
        );
      } else if (cvXFile != null) {
        // Web version
        final bytes = await cvXFile.readAsBytes();
        formData.files.add(
          MapEntry(
            'cvFile',
            MultipartFile.fromBytes(
              bytes,
              filename: cvXFile.name,
              contentType: MediaType('application', 'pdf'),
            ),
          ),
        );
      }

      print('DEBUG ApplicationService: Creating application with jobId: $jobId');
      print('DEBUG ApplicationService: Cover letter length: ${coverLetter.length}');
      print('DEBUG ApplicationService: CV file provided: ${cvFile != null || cvXFile != null}');

      final response = await _dio.post(
        '/api/Application',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('DEBUG ApplicationService: Application created successfully');
      return ApplicationModel.fromJson(response.data);
    } on DioException catch (e) {
      print('DEBUG ApplicationService: Error creating application: ${e.message}');
      if (e.response != null) {
        print('DEBUG ApplicationService: Response data: ${e.response?.data}');
        print('DEBUG ApplicationService: Status code: ${e.response?.statusCode}');
      }
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

  /// Get all applications for jobs created by the current recruiter
  Future<Map<String, dynamic>> getMyJobApplications({
    int page = 1,
    int pageSize = 10,
    String? status,
    int? jobId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      
      if (status != null) {
        queryParameters['status'] = status;
      }
      
      if (jobId != null) {
        queryParameters['jobId'] = jobId;
      }

      final response = await _dio.get(
        '/api/Application/my-job-applications',
        queryParameters: queryParameters,
      );

      final data = response.data;
      final applications = (data['data'] as List?)
          ?.map((json) => ApplicationModel.fromJson(json))
          .toList() ?? [];

      return {
        'applications': applications,
        'totalCount': data['totalCount'] ?? 0,
        'page': data['page'] ?? 1,
        'pageSize': data['pageSize'] ?? pageSize,
        'totalPages': data['totalPages'] ?? 1,
        'summary': data['summary'],
        'filters': data['filters'],
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
