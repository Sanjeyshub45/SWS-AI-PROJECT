// lib/core/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  /// Saves a notification to Firestore.
  /// [type] should be 'upload_complete' or 'upload_failed'.
  static Future<void> save({
    required String message,
    required String type,
  }) async {
    try {
      final id = _uuid.v4();
      await _firestore.collection('notifications').doc(id).set({
        'id': id,
        'message': message,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      // Notification save failure should never crash the upload flow
    }
  }
}
