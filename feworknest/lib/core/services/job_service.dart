import 'package:dio/dio.dart';

import '../config/dio_config.dart';
import '../constants/api_constants.dart';
import '../models/job_model.dart';
import '../utils/token_storage.dart';

class JobService {
  final Dio _dio;

  JobService({Dio? dio}) : _dio = dio ?? DioConfig.createDio(baseUrl: ApiConstants.baseUrl) {
    // Add auth interceptor
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

  Future<Map<String, dynamic>> getJobPosts({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? specialized,
    String? location,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.jobs, // Sử dụng constant thay vì hardcode
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null) 'search': search,
          if (specialized != null) 'specialized': specialized,
          if (location != null) 'location': location,
        },
      );

      final data = response.data;
      final jobs = (data['data'] as List)
          .map((json) => JobModel.fromJson(json))
          .toList();

      return {
        'jobs': jobs,
        'totalCount': data['totalCount'],
        'page': data['page'],
        'pageSize': data['pageSize'],
        'totalPages': data['totalPages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<JobModel> getJobPost(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.jobs}/$id');
      return JobModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<JobModel> createJobPost(CreateJobModel createJob) async {
    try {
      final response = await _dio.post(
        ApiConstants.jobs,
        data: createJob.toJson(),
      );
      return JobModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateJobPost(int id, UpdateJobModel updateJob) async {
    try {
      await _dio.put(
        '${ApiConstants.jobs}/$id',
        data: updateJob.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteJobPost(int id) async {
    try {
      await _dio.delete('${ApiConstants.jobs}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMyJobPosts({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.myJobs,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      final jobs = (data['data'] as List)
          .map((json) => JobModel.fromJson(json))
          .toList();

      return {
        'jobs': jobs,
        'totalCount': data['totalCount'],
        'page': data['page'],
        'pageSize': data['pageSize'],
        'totalPages': data['totalPages'],
      };
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
