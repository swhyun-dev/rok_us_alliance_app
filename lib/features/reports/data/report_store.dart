// lib/features/reports/data/report_store.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/report_reason.dart';

class ReportStore {
  ReportStore._();

  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('reports');

  /// 사용자가 신고를 등록한다. rules 가 reporterId == auth.uid 와
  /// status == 'pending' / resolvedBy == null 을 강제하므로 위 값 그대로 셋팅.
  static Future<String> create({
    required String reporterId,
    required String reporterNickname,
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? description,
    Map<String, dynamic>? targetSnapshot,
  }) async {
    final ref = _col.doc();
    await ref.set({
      'id': ref.id,
      'reporterId': reporterId,
      'reporterNickname': reporterNickname,
      'targetType': targetType.code,
      'targetId': targetId,
      'targetSnapshot': targetSnapshot ?? <String, dynamic>{},
      'reason': reason.code,
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'status': 'pending',
      'resolvedBy': null,
      'resolvedAt': null,
      'resolution': null,
      'action': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// 본인이 같은 대상을 이미 신고했는지 1회 확인 (중복 방지 UX).
  static Future<bool> hasReported({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
  }) async {
    final q = await _col
        .where('reporterId', isEqualTo: reporterId)
        .where('targetType', isEqualTo: targetType.code)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }
}
