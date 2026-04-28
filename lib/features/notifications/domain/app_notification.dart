// lib/features/notifications/domain/app_notification.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.uid,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.imageUrl,
    this.routeName,
    this.routeParams,
    this.readAt,
  });

  final String id;
  final String uid;
  final String type; // point_awarded/level_up/petition_milestone/...
  final String title;
  final String body;
  final String? imageUrl;
  final String? routeName;
  final Map<String, dynamic>? routeParams;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final map = (doc.data() as Map<String, dynamic>?) ?? const {};
    final created = map['createdAt'];
    final read = map['readAt'];
    return AppNotification(
      id: doc.id,
      uid: (map['uid'] ?? '') as String,
      type: (map['type'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      imageUrl: map['imageUrl'] as String?,
      routeName: map['routeName'] as String?,
      routeParams: (map['routeParams'] as Map?)?.cast<String, dynamic>(),
      isRead: (map['isRead'] ?? false) as bool,
      createdAt:
          created is Timestamp ? created.toDate() : DateTime.now(),
      readAt: read is Timestamp ? read.toDate() : null,
    );
  }
}
