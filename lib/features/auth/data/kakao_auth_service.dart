// lib/features/auth/data/kakao_auth_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' hide User;

class KakaoAuthService {
  const KakaoAuthService._();

  /// 카카오 OAuth → Cloud Function Custom Token → FirebaseAuth.signInWithCustomToken.
  /// 사용자가 시트를 닫으면 null. 그 외 실패는 Exception.
  static Future<User?> signInWithKakao() async {
    final OAuthToken? token = await _obtainKakaoToken();
    if (token == null) return null;

    final callable =
        FirebaseFunctions.instance.httpsCallable('createCustomTokenFromKakao');
    final result = await callable.call<Map<String, dynamic>>({
      'kakaoAccessToken': token.accessToken,
    });

    final customToken = result.data['customToken'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw Exception('Kakao Custom Token을 받지 못했습니다.');
    }

    final userCredential =
        await FirebaseAuth.instance.signInWithCustomToken(customToken);
    return userCredential.user;
  }

  static Future<OAuthToken?> _obtainKakaoToken() async {
    // 카톡 설치 사용자: 앱 전환 흐름 우선, 실패 시 계정 로그인으로 폴백.
    if (await isKakaoTalkInstalled()) {
      try {
        return await UserApi.instance.loginWithKakaoTalk();
      } on PlatformException catch (e) {
        if (_isUserCanceled(e)) return null;
        // 카톡 자체 인증 실패 → 카카오계정 로그인 폴백
        return _loginWithKakaoAccount();
      }
    }
    return _loginWithKakaoAccount();
  }

  static Future<OAuthToken?> _loginWithKakaoAccount() async {
    try {
      return await UserApi.instance.loginWithKakaoAccount();
    } on PlatformException catch (e) {
      if (_isUserCanceled(e)) return null;
      rethrow;
    }
  }

  static bool _isUserCanceled(PlatformException e) {
    final code = e.code.toUpperCase();
    return code == 'CANCELED' || code == 'USER_CANCELED';
  }

  static Future<void> signOut() async {
    try {
      await UserApi.instance.logout();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }
}
