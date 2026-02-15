import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app.dart';
import 'core/config/firebase_web_config.dart';
import 'core/services/signalr_notification_service.dart';

void main() async {
  // ✅ Bắt lỗi toàn cục và chạy ứng dụng
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // 🔧 Khởi tạo Firebase
      await FirebaseWebConfig.initializeFirebase();

      //  Khởi tạo SignalR service
      final signalRService = SignalRNotificationService();
      await signalRService.initialize();

      runApp(
        const ProviderScope(
          child: WorkNestApp(),
        ),
      );
    } catch (e, stackTrace) {
      print('💥 App initialization failed: $e');
      print('Stack trace: $stackTrace');
      
      // Chạy ứng dụng với chế độ offline/fallback
      runApp(
        const ProviderScope(
          child: WorkNestApp(),
        ),
      );
    };
  }, (error, stack) {
    debugPrint('💥 Uncaught error: $error');
    debugPrint('$stack');
  });
}
