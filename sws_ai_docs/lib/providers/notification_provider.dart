// lib/providers/notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => NotificationModel.fromMap(d.data(), d.id))
          .toList());
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications =
      ref.watch(notificationsStreamProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});

class NotificationActions {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> markAsRead(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  static Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final unread = await _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  static Future<void> clearAll() async {
    final batch = _firestore.batch();
    final all = await _firestore.collection('notifications').get();
    for (final doc in all.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
