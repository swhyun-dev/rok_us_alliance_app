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

  /// 단일 알림 삭제. firestore.rules 에서 본인 문서만 delete 허용.
  static Future<void> delete(String notificationId) async {
    await _col.doc(notificationId).delete();
  }

  /// 본인 알림 전체 삭제. 한 번에 최대 [limit] 개만 처리(과다 삭제 방지).
  static Future<int> deleteAll(String uid, {int limit = 200}) async {
    final snap = await _col
        .where('uid', isEqualTo: uid)
        .limit(limit)
        .get();
    if (snap.docs.isEmpty) return 0;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snap.docs.length;
  }
}
