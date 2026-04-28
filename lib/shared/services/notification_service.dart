// lib/shared/services/notification_service.dart
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// FCM 권한 요청 + 토큰 발급/저장 + foreground/background 메시지 핸들러.
/// 앱 시작 시 main.dart 에서 한 번 initialize() 호출.
class NotificationService {
  NotificationService._();

  static StreamSubscription<RemoteMessage>? _foregroundSub;
  static StreamSubscription<String>? _tokenSub;
  static StreamSubscription<User?>? _authSub;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    // 1) 권한 요청 — iOS 는 명시적 요청 필수, Android 13+ POST_NOTIFICATIONS.
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[Notification] requestPermission 실패: $e');
    }

    // 2) iOS 포그라운드 표시 옵션.
    if (!kIsWeb && Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 3) FCM 토큰 발급 + users 문서에 저장.
    try {
      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('[Notification] getToken 실패: $e');
    }

    // 4) 토큰 갱신 listener.
    _tokenSub?.cancel();
    _tokenSub = messaging.onTokenRefresh.listen(_saveToken);

    // 5) 로그인 상태 변경 시 현재 토큰을 새 사용자에게 다시 저장.
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;
      try {
        final token = await messaging.getToken();
        if (token != null) await _saveToken(token);
      } catch (_) {}
    });

    // 6) 포그라운드 메시지 listener — 시스템 알림으로 표시되지 않으니
    //    Firestore notifications 컬렉션이 onCreate 트리거로 추가되는 것을
    //    구독해 인앱 알림 센터에서 보여주는 패턴 사용. 여기선 디버그 로그만.
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[Notification] foreground ${message.notification?.title} '
        '${message.data}',
      );
    });
  }

  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'deviceToken': token,
          'platform': _platformLabel(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[Notification] token 저장 실패: $e');
    }
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }

  static Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _tokenSub?.cancel();
    await _authSub?.cancel();
    _foregroundSub = null;
    _tokenSub = null;
    _authSub = null;
    _initialized = false;
  }
}
