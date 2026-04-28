// lib/features/action_board/data/action_event_store.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/action_event.dart';

class ActionEventStore {
  ActionEventStore._();

  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('events');

  /// 모든 행사를 시작일 오름차순으로 구독.
  static Stream<List<ActionEvent>> watchAll() {
    return _col.orderBy('eventDate', descending: false).snapshots().map(
          (snap) => snap.docs.map(ActionEvent.fromFirestore).toList(),
        );
  }

  /// 다가오는(미래) 행사만 구독.
  static Stream<List<ActionEvent>> watchUpcoming({int limit = 20}) {
    final now = Timestamp.fromDate(DateTime.now());
    return _col
        .where('status', isEqualTo: 'upcoming')
        .where('eventDate', isGreaterThanOrEqualTo: now)
        .orderBy('eventDate', descending: false)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ActionEvent.fromFirestore).toList());
  }

  /// isFeatured 인 다가오는 행사 (홈 UpcomingEventCard용).
  static Stream<List<ActionEvent>> watchFeaturedUpcoming({int limit = 3}) {
    final now = Timestamp.fromDate(DateTime.now());
    return _col
        .where('isFeatured', isEqualTo: true)
        .where('eventDate', isGreaterThanOrEqualTo: now)
        .orderBy('eventDate', descending: false)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ActionEvent.fromFirestore).toList());
  }

  /// 단일 행사 실시간 구독.
  static Stream<ActionEvent?> watchById(String id) {
    return _col.doc(id).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        return ActionEvent.fromFirestore(doc);
      },
    );
  }

  /// 단발 조회 (캐시 우회).
  static Future<ActionEvent?> fetchById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ActionEvent.fromFirestore(doc);
  }

  /// 관리자만 호출 (rules에서 isAdmin 검증). docId는 자동 생성.
  static Future<String> add(ActionEvent event) async {
    final ref = _col.doc();
    await ref.set(event.copyWith(id: ref.id).toMap());
    return ref.id;
  }

  /// 부분 업데이트. 호출자는 변경 필드만 전달.
  static Future<void> update(String id, Map<String, dynamic> changes) async {
    await _col.doc(id).update({
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 행사 삭제 (rules에서 isAdmin 검증).
  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
