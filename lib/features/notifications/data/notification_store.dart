// lib/features/notifications/data/notification_store.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_notification.dart';

class NotificationStore {
  NotificationStore._();

  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('notifications');

  static Stream<List<AppNotification>> watchMine(
    String uid, {
    int limit = 50,
  }) {
    return _col
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map(AppNotification.fromFirestore).toList(),
        );
  }

  static Stream<int> watchUnreadCount(String uid) {
    return _col
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  static Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// 화면에 보이는 알림들을 일괄 읽음 처리.
  static Future<void> markAllAsRead(List<String> ids) async {
    if (ids.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final id in ids) {
      batch.update(_col.doc(id), {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
