import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/upload_service.dart';
import '../services/public_upload_service.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService();
});

final publicUploadServiceProvider = Provider<PublicUploadService>((ref) {
  return PublicUploadService();
}); 