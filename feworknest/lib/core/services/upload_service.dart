import 'package:dio/dio.dart';
import 'dart:io';
import '../constants/api_constants.dart';
import '../utils/token_storage.dart';

class UploadService {
  final Dio _dio;

  UploadService({Dio? dio}) : _dio = dio ?? Dio() {
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

  Future<String> uploadPdf(File file, {String folder = 'pdfs'}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/Upload/pdf',
        queryParameters: {'folder': folder},
        data: formData,
      );

      return response.data['fileUrl'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> uploadCv(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/Upload/cv',
        data: formData,
      );

      return response.data['cvUrl'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> uploadFile(File file, {String folder = 'files'}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/Upload/file',
        queryParameters: {'folder': folder},
        data: formData,
      );

      return response.data['fileUrl'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteImage(String publicId) async {
    try {
      await _dio.delete(
        '/api/Upload/image',
        queryParameters: {'publicId': publicId},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteFile(String publicId) async {
    try {
      await _dio.delete(
        '/api/Upload/file',
        queryParameters: {'publicId': publicId},
      );
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
