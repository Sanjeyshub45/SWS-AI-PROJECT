// lib/core/services/fcm_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Request permission (iOS/Android 13+)
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize local notifications plugin
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      // High importance channel for Android
      const channel = AndroidNotificationChannel(
        'sws_uploads',
        'Upload Notifications',
        description: 'Notifications for file upload completion',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Get and save device FCM token (may fail if FCM not configured)
      try {
        final token = await _fcm.getToken();
        if (token != null) await _saveToken(token);
        // Listen for token refresh
        _fcm.onTokenRefresh.listen(_saveToken);
      } catch (e) {
        // FCM not fully configured — push notifications unavailable
        debugPrint('[FCM] getToken failed (FCM may not be enabled): $e');
      }

      // Foreground messages → show local notification
      FirebaseMessaging.onMessage.listen((message) {
        _showLocalNotification(message);
      });
    } catch (e) {
      debugPrint('[FCM] initialize failed: $e');
    }
  }

  static Future<void> _saveToken(String token) async {
    await FirebaseFirestore.instance
        .collection('devices')
        .doc('current_device')
        .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sws_uploads',
          'Upload Notifications',
          channelDescription: 'File upload completion alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
