import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/app/app.dart';
import 'core/config/firebase_web_config.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseWebConfig.initializeFirebase();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(
    const ProviderScope(
      child: WorkNestApp(),
    ),
  );
}
