import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseWebConfig {
  // Service Account Configuration from jobappchat-firebase-adminsdk-fbsvc-c4612be2ee.json
  static const Map<String, dynamic> firebaseConfig = {
    "apiKey": "AIzaSyCIMcF2niWutcfWzw1OlGm7EWZA3U4e5F0", // Keep original API key for client
    "authDomain": "jobappchat.firebaseapp.com",
    "projectId": "jobappchat",
    "storageBucket": "jobappchat.firebasestorage.app", // Updated storage bucket
    "messagingSenderId": "501808058071",
    "appId": "1:501808058071:web:7091b099f4484ac2caea92",
    "measurementId": "G-JZ5Q97ER4D",
    "databaseURL": "https://jobappchat-default-rtdb.asia-southeast1.firebasedatabase.app"
  };

  static Future<void> initializeFirebase() async {
    try {
      print('DEBUG Firebase: Initializing Firebase with project: jobappchat');
      
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyCIMcF2niWutcfWzw1OlGm7EWZA3U4e5F0",
            authDomain: "jobappchat.firebaseapp.com",
            projectId: "jobappchat",
            storageBucket: "jobappchat.firebasestorage.app",
            messagingSenderId: "501808058071",
            appId: "1:501808058071:web:7091b099f4484ac2caea92",
            measurementId: "G-JZ5Q97ER4D",
            databaseURL: "https://jobappchat-default-rtdb.asia-southeast1.firebasedatabase.app",
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      
      print('DEBUG Firebase: ✅ Firebase initialized successfully');
      print('DEBUG Firebase: Project ID: jobappchat');
      print('DEBUG Firebase: Database URL: https://jobappchat-default-rtdb.asia-southeast1.firebasedatabase.app');
      
    } catch (e) {
      print('DEBUG Firebase: ❌ Firebase initialization failed: $e');
      rethrow;
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