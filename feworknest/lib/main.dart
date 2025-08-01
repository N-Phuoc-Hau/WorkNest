import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app.dart';
import 'core/config/firebase_web_config.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔧 Khởi tạo Firebase
  await FirebaseWebConfig.initializeFirebase();

  // 🔔 Khởi tạo dịch vụ thông báo
  final notificationService = NotificationService();
  await notificationService.initialize();

  // ✅ Bắt lỗi toàn cục và chạy ứng dụng
  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: WorkNestApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('💥 Uncaught error: $error');
    debugPrint('$stack');
  });
}
