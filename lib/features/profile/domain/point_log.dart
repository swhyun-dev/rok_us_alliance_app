// lib/features/profile/domain/point_log.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PointLog {
  const PointLog({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.refId,
    this.refType,
    this.pointsAfter,
    this.levelAfter,
    this.levelChanged = false,
    this.adjustedBy,
    this.adjustReason,
  });

  final String id;
  final String uid;
  final String type;
  final int amount;
  final String description;
  final DateTime createdAt;
  final String? refId;
  final String? refType;
  final int? pointsAfter;
  final int? levelAfter;
  final bool levelChanged;
  final String? adjustedBy;
  final String? adjustReason;

  bool get isPositive => amount > 0;

  String get amountLabel {
    final prefix = isPositive ? '+' : '';
    return '$prefix${amount}P';
  }

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
  }

  factory PointLog.fromFirestore(DocumentSnapshot doc) {
    final map = (doc.data() as Map<String, dynamic>?) ?? const {};
    final ts = map['createdAt'];
    final created = ts is Timestamp ? ts.toDate() : DateTime.now();
    return PointLog(
      id: doc.id,
      uid: (map['uid'] ?? '') as String,
      type: (map['type'] ?? '') as String,
      amount: (map['amount'] ?? 0) as int,
      description: (map['description'] ?? '') as String,
      createdAt: created,
      refId: map['refId'] as String?,
      refType: map['refType'] as String?,
      pointsAfter: map['pointsAfter'] as int?,
      levelAfter: map['levelAfter'] as int?,
      levelChanged: (map['levelChanged'] ?? false) as bool,
      adjustedBy: map['adjustedBy'] as String?,
      adjustReason: map['adjustReason'] as String?,
    );
  }
}
