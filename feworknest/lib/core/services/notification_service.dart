import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../utils/token_storage.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Dio _dio;

  NotificationService({Dio? dio}) : _dio = dio ?? Dio() {
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

  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
        
        // Initialize local notifications
        await _initializeLocalNotifications();
        
        // Get FCM token
        String? token = await _messaging.getToken();
        if (token != null) {
          print('FCM Token: $token');
          await _sendTokenToServer(token);
        }
        
        // Listen to token refresh
        _messaging.onTokenRefresh.listen((token) {
          _sendTokenToServer(token);
        });
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
        // Handle notification tap when app is terminated
        RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      } else {
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      _showLocalNotification(message);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High importance notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // Navigate to specific screen based on notification data
    _handleNotificationNavigation(message.data);
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final id = data['id'];
    
    switch (type) {
      case 'chat':
        // Navigate to chat screen
        print('Navigate to chat: $id');
        break;
      case 'job_application':
        // Navigate to job application screen
        print('Navigate to job application: $id');
        break;
      case 'system':
        // Navigate to system notification screen
        print('Navigate to system notification: $id');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  // Send token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      await _dio.post(
        ApiConstants.deviceToken,
        data: {
          'fcmToken': token,
          'deviceType': 'mobile',
        },
      );
      print('Token sent to server successfully');
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }

  // Create notification in Firebase Realtime Database
  Future<void> createNotification(String userId, Map<String, dynamic> notification) async {
    try {
      await _database
          .child('notifications')
          .child(userId)
          .push()
          .set(notification);
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // Get user notifications from backend API
  Future<Map<String, dynamic>> getUserNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get user notifications stream (for real-time updates)
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    try {
      final notificationsRef = _database.child('notifications/$userId');
      
      return notificationsRef.onValue.map((event) {
        final notifications = <Map<String, dynamic>>[];
        
        if (event.snapshot.exists) {
          for (final child in event.snapshot.children) {
            final notificationId = child.key!;
            final notificationData = child.value as Map<dynamic, dynamic>;
            
            notifications.add({
              'id': notificationId,
              ...notificationData,
            });
          }
        }
        
        // Sort by timestamp (most recent first)
        notifications.sort((a, b) {
          final timeA = a['timestamp'] ?? 0;
          final timeB = b['timestamp'] ?? 0;
          return (timeB as int).compareTo(timeA as int);
        });
        
        return notifications;
      });
    } catch (e) {
      print('Error getting user notifications stream: $e');
      rethrow;
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _dio.post('${ApiConstants.markAsRead}/$notificationId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _dio.get(ApiConstants.unreadCount);
      return response.data['unreadCount'] as int;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _dio.delete('${ApiConstants.notifications}/$notificationId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _dio.post(ApiConstants.markAllAsRead);
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

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // Handle background message here
}
