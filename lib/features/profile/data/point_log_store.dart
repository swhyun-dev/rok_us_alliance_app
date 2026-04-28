// lib/features/profile/data/point_log_store.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/point_log.dart';

class PointLogPage {
  const PointLogPage({
    required this.logs,
    required this.cursor,
    required this.hasMore,
  });
  final List<PointLog> logs;
  final DocumentSnapshot? cursor;
  final bool hasMore;
}

class PointLogStore {
  PointLogStore._();

  static const int _pageSize = 20;
  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('point_logs');

  static Stream<List<PointLog>> watchMyLogs(String uid, {int limit = _pageSize}) {
    return _col
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(PointLog.fromFirestore).toList());
  }

  static Future<PointLogPage> fetchPage(
    String uid, {
    DocumentSnapshot? cursor,
    int limit = _pageSize,
  }) async {
    Query<Map<String, dynamic>> q = _col
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (cursor != null) q = q.startAfterDocument(cursor);
    final snap = await q.get();
    final logs = snap.docs.map(PointLog.fromFirestore).toList();
    return PointLogPage(
      logs: logs,
      cursor: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }
}
