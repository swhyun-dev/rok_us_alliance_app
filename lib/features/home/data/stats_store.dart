// lib/features/home/data/stats_store.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppStats {
  const AppStats({
    required this.memberCount,
    required this.activePetitions,
    required this.monthlyEvents,
    required this.totalPosts,
    required this.totalComments,
    required this.totalSignatures,
    required this.updatedAt,
  });

  final int memberCount;
  final int activePetitions;
  final int monthlyEvents;
  final int totalPosts;
  final int totalComments;
  final int totalSignatures;
  final DateTime? updatedAt;

  factory AppStats.empty() => const AppStats(
        memberCount: 0,
        activePetitions: 0,
        monthlyEvents: 0,
        totalPosts: 0,
        totalComments: 0,
        totalSignatures: 0,
        updatedAt: null,
      );

  factory AppStats.fromMap(Map<String, dynamic> map) {
    final ts = map['updatedAt'];
    return AppStats(
      memberCount: (map['memberCount'] ?? 0) as int,
      activePetitions: (map['activePetitions'] ?? 0) as int,
      monthlyEvents: (map['monthlyEvents'] ?? 0) as int,
      totalPosts: (map['totalPosts'] ?? 0) as int,
      totalComments: (map['totalComments'] ?? 0) as int,
      totalSignatures: (map['totalSignatures'] ?? 0) as int,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class StatsStore {
  StatsStore._();

  static final DocumentReference<Map<String, dynamic>> _doc =
      FirebaseFirestore.instance.doc('app_meta/stats');

  /// 홈 HeroStatsSection 카운터 데이터 소스. 5분마다 updateAppStats CF 갱신.
  static Stream<AppStats> watchStats() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return AppStats.empty();
      return AppStats.fromMap(snap.data() ?? const {});
    });
  }
}
