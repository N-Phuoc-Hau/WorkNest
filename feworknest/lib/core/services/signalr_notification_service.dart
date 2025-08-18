import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SignalRNotificationService {
  static final SignalRNotificationService _instance = SignalRNotificationService._internal();
  factory SignalRNotificationService() => _instance;
  SignalRNotificationService._internal();

  // Local Notifications
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Stream Controllers for real-time events
  final StreamController<Map<String, dynamic>> _chatNotificationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _jobPostNotificationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _interviewNotificationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _generalNotificationController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get chatNotifications => _chatNotificationController.stream;
  Stream<Map<String, dynamic>> get jobPostNotifications => _jobPostNotificationController.stream;
  Stream<Map<String, dynamic>> get interviewNotifications => _interviewNotificationController.stream;
  Stream<Map<String, dynamic>> get generalNotifications => _generalNotificationController.stream;

  bool _isConnected = false;

  // Initialize the service
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    developer.log('SignalR Notification Service initialized');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Request permissions for Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Mock methods for now (will implement SignalR later when packages are installed)
  Future<void> joinChatRoom(int chatRoomId) async {
    developer.log('Mock: Joined chat room: $chatRoomId');
  }

  Future<void> joinCompanyFollowers(int companyId) async {
    developer.log('Mock: Joined company followers: $companyId');
  }

  // Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'worknest_notifications',
      'WorkNest Notifications',
      channelDescription: 'Notifications for WorkNest app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Get connection status
  bool get isConnected => _isConnected;

  // Dispose resources
  void dispose() {
    _chatNotificationController.close();
    _jobPostNotificationController.close();
    _interviewNotificationController.close();
    _generalNotificationController.close();
  }
}