import 'package:dio/dio.dart';
import 'dart:io';
import '../constants/api_constants.dart';

class PublicUploadService {
  final Dio _dio;

  PublicUploadService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
  }

  Future<String> uploadAvatar(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/Upload/avatar',
        data: formData,
      );

      return response.data['imageUrl'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> uploadImage(File file, {String folder = 'images'}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/Upload/image',
        queryParameters: {'folder': folder},
        data: formData,
      );

      return response.data['imageUrl'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<String>> uploadImages(
    List<File> files, {
    String folder = 'images',
  }) async {
    try {
      final formData = FormData();
      
      for (final file in files) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        '/api/Upload/images',
        queryParameters: {'folder': folder},
        data: formData,
      );

      return List<String>.from(response.data['imageUrls']);
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