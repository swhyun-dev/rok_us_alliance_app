// lib/features/profile/data/daily_check_in_store.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class DailyCheckInResult {
  const DailyCheckInResult({
    required this.status,
    required this.pointsAwarded,
    required this.bonusAwarded,
    required this.consecutiveDays,
  });

  final String status; // 'checked_in' | 'already_checked'
  final int pointsAwarded;
  final int bonusAwarded;
  final int consecutiveDays;

  bool get isFresh => status == 'checked_in';
  int get total => pointsAwarded + bonusAwarded;
}

class DailyCheckInStore {
  DailyCheckInStore._();

  /// uid 의 오늘 체크인 doc 존재 여부.
  static Future<bool> hasCheckedInToday(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('daily_check_ins')
        .doc('${uid}_${_todayKst()}')
        .get();
    return doc.exists;
  }

  static Future<DailyCheckInResult> run() async {
    final callable = FirebaseFunctions.instance.httpsCallable('dailyCheckIn');
    try {
      final result = await callable.call<Map<String, dynamic>>();
      final data = result.data;
      debugPrint('[dailyCheckIn] response: $data');
      if (data['debug'] != null) {
        debugPrint('[dailyCheckIn] DEBUG: ${data['debug']}');
      }
      return DailyCheckInResult(
        status: (data['status'] ?? 'already_checked') as String,
        pointsAwarded: (data['pointsAwarded'] ?? 0) as int,
        bonusAwarded: (data['bonusAwarded'] ?? 0) as int,
        consecutiveDays: (data['consecutiveDays'] ?? 0) as int,
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[dailyCheckIn] FirebaseFunctionsException '
          'code=${e.code} message=${e.message} details=${e.details}');
      rethrow;
    } catch (e, st) {
      debugPrint('[dailyCheckIn] unknown error: $e\n$st');
      rethrow;
    }
  }

  static String _todayKst() {
    final ms = DateTime.now().toUtc().millisecondsSinceEpoch +
        9 * 60 * 60 * 1000;
    final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
