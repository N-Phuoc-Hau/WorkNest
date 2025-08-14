import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/public_upload_service.dart';
import '../services/upload_service.dart';

// Upload State
class UploadState {
  final bool isUploading;
  final String? error;
  final String? url;

  const UploadState({
    this.isUploading = false,
    this.error,
    this.url,
  });

  UploadState copyWith({
    bool? isUploading,
    String? error,
    String? url,
  }) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      error: error ?? this.error,
      url: url ?? this.url,
    );
  }
}

// Upload Result
class UploadResult {
  final bool success;
  final String? url;
  final String? message;

  const UploadResult({
    required this.success,
    this.url,
    this.message,
  });
}

// Upload Notifier
class UploadNotifier extends StateNotifier<UploadState> {
  final UploadService _uploadService;

  UploadNotifier(this._uploadService) : super(const UploadState());

  Future<UploadResult> uploadFile(File file, String folder) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final url = await _uploadService.uploadFile(file);
      
      state = state.copyWith(
        isUploading: false,
        url: url,
      );

      return UploadResult(success: true, url: url);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );

      return UploadResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService();
});

final publicUploadServiceProvider = Provider<PublicUploadService>((ref) {
  return PublicUploadService();
}); 

final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref.watch(uploadServiceProvider));
});