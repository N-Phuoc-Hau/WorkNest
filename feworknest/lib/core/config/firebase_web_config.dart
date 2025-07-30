import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseWebConfig {
  static const Map<String, dynamic> firebaseConfig = {
    "apiKey": "YOUR_API_KEY",
    "authDomain": "jobappchat.firebaseapp.com",
    "projectId": "jobappchat",
    "storageBucket": "jobappchat.appspot.com",
    "messagingSenderId": "YOUR_SENDER_ID",
    "appId": "YOUR_APP_ID",
    "measurementId": "YOUR_MEASUREMENT_ID"
  };

  static Future<void> initializeFirebase() async {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "YOUR_API_KEY",
          authDomain: "jobappchat.firebaseapp.com",
          projectId: "jobappchat",
          storageBucket: "jobappchat.appspot.com",
          messagingSenderId: "YOUR_SENDER_ID",
          appId: "YOUR_APP_ID",
          measurementId: "YOUR_MEASUREMENT_ID",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  }

  static Future<String?> getFCMToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get token
        String? token = await messaging.getToken();
        print('FCM Token: $token');
        return token;
      } else {
        print('User declined or has not accepted permission');
        return null;
      }
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static void setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  static void setupBackgroundMessageHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
} 