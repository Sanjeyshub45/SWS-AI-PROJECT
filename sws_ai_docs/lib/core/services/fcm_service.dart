// lib/core/services/fcm_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
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

  /// Public method — call this from anywhere to show a local push notification.
  /// [isSuccess] controls the icon tint (green vs red).
  static Future<void> showNotification({
    required String title,
    required String body,
    bool isSuccess = true,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'sws_uploads',
            'Upload Notifications',
            channelDescription: 'File upload completion alerts',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: isSuccess
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE53935),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[FCM] showNotification failed: $e');
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    showNotification(
      title: notification.title ?? 'SWS AI Docs',
      body: notification.body ?? '',
      isSuccess: true,
    );
  }
}
