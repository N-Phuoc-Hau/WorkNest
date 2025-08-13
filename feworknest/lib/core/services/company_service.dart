import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/company_model.dart';
import '../models/follow_model.dart';
import '../models/job_model.dart';
import '../utils/token_storage.dart';

class CompanyService {
  final Dio _dio;

  CompanyService({Dio? dio}) : _dio = dio ?? Dio() {
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

  // Get all companies
  Future<Map<String, dynamic>> getAllCompanies({
    int page = 1,
    int pageSize = 10,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.companies,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null) 'search': search,
        },
      );

      final apiResponse = ApiResponse.fromJson(response.data);
      
      if (apiResponse.success) {
        final companies = (apiResponse.data['data'] as List)
            .map((json) => CompanyModel.fromJson(json))
            .toList();
        
        return {
          'companies': companies,
          'totalCount': apiResponse.data['totalCount'],
          'totalPages': apiResponse.data['totalPages'],
          'page': apiResponse.data['page'],
          'pageSize': apiResponse.data['pageSize'],
        };
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to get companies: $e');
    }
  }

  // Get company by ID
  Future<CompanyModel> getCompany(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.companies}/$id');

      final apiResponse = ApiResponse.fromJson(response.data);
      
      if (apiResponse.success) {
        return CompanyModel.fromJson(apiResponse.data);
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to get company: $e');
    }
  }

  // Get my company (for recruiter)
  Future<CompanyModel> getMyCompany() async {
    try {
      final response = await _dio.get('${ApiConstants.companies}/my-company');

      final apiResponse = ApiResponse.fromJson(response.data);
      
      if (apiResponse.success) {
        return CompanyModel.fromJson(apiResponse.data);
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to get my company: $e');
    }
  }

  // Update company
  Future<CompanyModel> updateCompany(int id, UpdateCompanyModel updateCompany) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.companies}/$id',
        data: updateCompany.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(response.data);
      
      if (apiResponse.success) {
        return CompanyModel.fromJson(apiResponse.data);
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to update company: $e');
    }
  }

  // Upload company images
  Future<CompanyModel> uploadCompanyImages(int id, List<String> imagePaths) async {
    try {
      final formData = FormData();
      
      for (int i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              file.path,
              filename: 'company_image_$i.jpg',
            ),
          ),
        );
      }

      final response = await _dio.post(
        '${ApiConstants.companies}/$id/images',
        data: formData,
      );

      final apiResponse = ApiResponse.fromJson(response.data);
      
      if (apiResponse.success) {
        return CompanyModel.fromJson(apiResponse.data);
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to upload company images: $e');
    }
  }

  // Get company jobs
  Future<Map<String, dynamic>> getCompanyJobs(
    int id, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.companies}/$id/jobs',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final apiResponse = ApiResponse.fromJson(response.data);
      
      if (apiResponse.success) {
        final jobs = (apiResponse.data['data'] as List)
            .map((json) => JobModel.fromJson(json))
            .toList();
        
        return {
          'jobs': jobs,
          'totalCount': apiResponse.data['totalCount'],
          'totalPages': apiResponse.data['totalPages'],
          'page': apiResponse.data['page'],
          'pageSize': apiResponse.data['pageSize'],
        };
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to get company jobs: $e');
    }
  }

  // Get company followers
  Future<List<FollowModel>> getCompanyFollowers(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.companies}/$id/followers');

      final apiResponse = ApiResponse.fromJson(response.data);
      
      if (apiResponse.success) {
        return (apiResponse.data as List)
            .map((json) => FollowModel.fromJson(json))
            .toList();
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to get company followers: $e');
    }
  }

  // Follow company
  Future<bool> followCompany(int id) async {
    try {
      final response = await _dio.post('${ApiConstants.companies}/$id/follow');

      final apiResponse = ApiResponse.fromJson(response.data);
      
      if (apiResponse.success) {
        return true;
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to follow company: $e');
    }
  }

  // Unfollow company
  Future<bool> unfollowCompany(int id) async {
    try {
      final response = await _dio.delete('${ApiConstants.companies}/$id/follow');

      final apiResponse = ApiResponse.fromJson(response.data);
      
      if (apiResponse.success) {
        return true;
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to unfollow company: $e');
    }
  }
} 