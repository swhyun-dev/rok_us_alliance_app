// lib/features/auth/data/apple_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthService {
  const AppleAuthService._();

  /// iOS 전용. 그 외 플랫폼은 Exception.
  /// 사용자가 시트를 닫으면 null. 그 외 실패는 Exception.
  static Future<User?> signInWithApple() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw Exception('Apple 로그인은 iOS에서만 지원됩니다.');
    }

    AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }

    if (credential.identityToken == null) {
      throw Exception('Apple ID 토큰을 받지 못했습니다.');
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    return userCredential.user;
  }
}
