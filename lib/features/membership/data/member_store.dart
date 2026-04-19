// lib/features/membership/data/member_store.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/member.dart';

class MemberStore {
  MemberStore._();

  static const _key = 'member_data_v1';

  static final ValueNotifier<Member?> notifier = ValueNotifier<Member?>(null);

  static Member? get current => notifier.value;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      notifier.value = Member.fromMap(map);
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  static Future<void> setMember(Member member) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(member.toMap()));
    notifier.value = member;
  }

  static Future<void> addPoints(int points, {String reason = ''}) async {
    final m = notifier.value;
    if (m == null) return;
    final newPoints = m.points + points;
    final newGrade = m.grade == MemberGrade.honorary
        ? m.grade
        : MemberGradeExt.fromPoints(newPoints);
    await setMember(m.copyWith(points: newPoints, grade: newGrade));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifier.value = null;
  }

  // 개발용: 목업 회원 로드
  static Future<void> loadMock() async {
    await setMember(Member.mock());
  }
}
